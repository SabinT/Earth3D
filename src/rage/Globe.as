package rage
{
	import away3dlite.arcane;
	import away3dlite.cameras.Camera3D;
	import away3dlite.containers.ObjectContainer3D;
	import away3dlite.containers.Scene3D;
	import away3dlite.containers.View3D;
	import away3dlite.core.utils.Cast;
	import away3dlite.materials.BitmapMaterial;
	import away3dlite.materials.ColorMaterial;
	import away3dlite.materials.WireColorMaterial;
	import away3dlite.primitives.Sphere;
	import away3dlite.templates.Template;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Orientation3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Utils3D;
	import flash.geom.Vector3D;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	/**
	 * Author: sonofrage
	 * Email: godofrage@gmail.com
	 */
	
	[SWF(backgroundColor="#000000", frameRate="60", quality="MEDIUM", width="500", height="500")]

	public class Globe extends Template
	{
		public function Globe() {
			
		}
		
		override protected function onInit():void
		{
			stop();
			
			// read properties from files, load images etc
			trace("loading started...");
			
			settingsLoader.load(new URLRequest(resourceBase + "settings.xml"));
			settingsLoader.addEventListener(Event.COMPLETE, loadGraphics);
		}
		
		private function loadGraphics(e:Event):void {
			settings = new XML(e.target.data);

			earthLoader = LoaderUtils.load(new URLRequest(resourceBase + "earthmap.jpg"));
			var backFile:String = settings.scene[0].background[0].@file;
			backLoader = LoaderUtils.load(new URLRequest(resourceBase + backFile));
			// other top level graphics
			
			LoaderUtils.setCallback(loadHotSpots);
		}
		
		public function setResourceBase(base:String):void
		{
			resourceBase = base;
		}
		
		public function loadHotSpots():void {
			LoaderUtils.clear();
			
			earthImage = Bitmap(earthLoader.content).bitmapData;
			
			newTab = String(settings.scene[0].navigation[0].@newtab);
			
			var hsList:XMLList = settings.hotspots.hotspot;
			var cur:XML;
			
			var i:int;
			for (i = 0; i < hsList.length(); i++) {
				cur = hsList[i];
				var x:int =  cur.x;
				var y:int = cur.y;
				var z:int = cur.z;
				var link:String = cur.link;
				var fileName:String = cur.file;
				
				var hs:HotSpot = new HotSpot();
				hs.load(resourceBase + fileName, x, y, z, link, earthImage);
				addHotSpot(hs);
			}
			
			LoaderUtils.setCallback(loadComplete);
		}
		
		public function addHotSpot(hs:HotSpot):void {
			// find appropriate location on the array and add
			if (hotSpots.length == 0) {
				hotSpots.push(hs);
				return;
			}
			
			var i:int;
			for (i = 0; i < hotSpots.length; i++) {
				if (HotSpot(hotSpots[i]).z < hs.z) break;
			}
			
			hotSpots.splice(i, 0, hs);
			//hotSpots.push(hs);	
		}
		
		public function loadComplete():void
		{
			// everything has been loaded
			LoaderUtils.clear();
			
			setupScene();
			setupListeners();
			setupDebug();
			
			trace("loading complete...");
			start();
			
			lastTime = getTimer();
			curTime = getTimer();
		}
		
		private function setupScene():void
		{
			// add the background
			var autoFit:String = settings.scene[0].background[0].@autofit;

			if (autoFit == "true") {
				backLoader.content.width = stage.stageWidth;
				backLoader.content.height = stage.stageHeight;
			}
			addChildAt(backLoader.content, 0);
			
			globeImage = new BitmapData(earthImage.width, earthImage.height, false);
			earthImageBW = earthImage.clone();
			BitmapUtils.desaturate(earthImageBW);
			
			// for now, do the compositing manually
			globeImage.copyPixels(earthImage, new Rectangle(0,0,earthImage.width, earthImage.height), new Point());
			//globeImage.draw(earthImage);
			globeMaterial = new BitmapMaterial(globeImage);
			globeMaterial.smooth = true;
			
			camera.zoom = 20;
			camera.focus = 100;
			camera.x = 0; camera.y = 0;
			zoom = Number(settings.scene[0].camera[0].@zoom);
			//camMinDist = Number(settings.scene[0].camera[0].@min);
			//zoomMax = camera.focus * radius * camera.zoom * 2 / (stage.stageWidth  < stage.stageHeight ? stage.stageWidth : stage.stageHeight);
			zoomMax = CAMERA_DISTANCE / (radius * camera.focus * 2.25) * (stage.stageWidth  < stage.stageHeight ? stage.stageWidth : stage.stageHeight);
			zoomMin = Number(settings.scene[0].camera[0].@min);
			//if (camDist < camMinDist) camDist = camMinDist;
			targetZoom = zoom;
			camera.zoom = zoom;
			camera.z = -CAMERA_DISTANCE;
			
			camera.lookAt(new Vector3D(0, 0, 0));

			var centered:String = settings.scene[0].globe[0].@centered;
			if (centered == "true") {
				view.x = stage.stageWidth / 2;
				view.y = stage.stageHeight / 2;
			} else {
				view.x = settings.scene[0].globe[0].@x;
				view.y = settings.scene[0].globe[0].@y;
			}
			initRotSpeed = settings.scene[0].globe[0].@initialspin;
			
			view.mouseEnabled = true;
			view.doubleClickEnabled = true;
			
			segments = Number(settings.scene[0].globe[0].@segments);
			globe = new Sphere(globeMaterial, radius, segments, segments);
			tracker = new Sphere(new WireColorMaterial(), radius/20 , 10, 10);
			view.scene.addChild(globe);
			//view.scene.addChild(tracker);

			// initial orientation of the globe
			globe.transform.matrix3D.appendRotation(15, new Vector3D(0,0,1));
			targetRotMatrix.appendRotation(15, new Vector3D(0,0,1));
			targetRotSpeed = initRotSpeed;
			targetRotAxis = initRotAxis;
			
			initialized = true;
		}
		
		private function setupListeners():void
		{
			stage.addEventListener(Event.ACTIVATE, onActivate);
			stage.addEventListener(Event.DEACTIVATE, onDeactivate);
			
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);	
			
			view.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			view.addEventListener(MouseEvent.ROLL_OVER, onRollOver);
			view.addEventListener(MouseEvent.ROLL_OUT, onRollOut);
			stage.addEventListener(MouseEvent.CLICK, onClick);
			view.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick);
			
			view.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}
		
		// now the listener functions ------------------------
		private var dragMatrix:Matrix3D = new Matrix3D();
		private function onMouseDown(event:MouseEvent):void
		{
			lastMouseX = view.mouseX;
			lastMouseY = view.mouseY;
			lastRotMatrix = globe.transform.matrix3D.clone();
			dragMatrix.identity();
			move = true;
		}

		private function onMouseUp(event:MouseEvent):void
		{
			if (!move) {
				return;
			}
			if (!over) {
				deselectHotSpot();			
				targetRotAxis = initRotAxis;
				targetRotSpeed = initRotSpeed;
			}
	
			move = false;
		}
		
		private var lastDragVec:Vector3D = new Vector3D();
		private function onMouseMove(event:MouseEvent):void
		{
			if (!move) return;
			if (!event.buttonDown) {
				move = false;
				return;
			}
			
			var dragVec:Vector3D = new Vector3D(view.mouseX - lastMouseX, -lastMouseY + view.mouseY, 0);
			var aRadius:Number = radius / CAMERA_DISTANCE * camera.zoom * camera.focus;
			var rotation:Number = dragVec.length / aRadius * 180 / Math.PI;
			
			//if (rotationSpeed > MAX_ROTATION_SPEED) rotationSpeed = MAX_ROTATION_SPEED;
			
			var dragAxis:Vector3D = dragVec.crossProduct(new Vector3D(0,0,1));
			dragAxis.normalize();
			
			dragMatrix.identity();
			dragMatrix.appendRotation(rotation, dragAxis);
			
			targetRotMatrix = lastRotMatrix.clone();
			targetRotMatrix.append(dragMatrix);
			
			rotationAxis = dragAxis;

//			var dragVec:Vector3D = new Vector3D(view.mouseX - lastMouseX, -lastMouseY + view.mouseY, 0);
//			var aRadius:Number = radius / CAMERA_DISTANCE * camera.zoom * camera.focus;
//			var rotation:Number = dragVec.length / aRadius * 180 / Math.PI;
//
//			var dragAxis:Vector3D = dragVec.crossProduct(new Vector3D(0,0,1));
//			dragAxis.normalize();
//			
//			dragMatrix.identity();
//			dragMatrix.appendRotation(rotation, dragAxis);
//			
//			//targetRotMatrix = lastRotMatrix.clone();
//			targetRotMatrix.append(dragMatrix);
//			
//			lastMouseX = view.mouseX;
//			lastMouseY = view.mouseY;
		}
		
		private function bringToCenter(x:Number, y:Number):void {
			var dragVec:Vector3D = new Vector3D(-view.mouseX, -view.mouseY, 0);
			var aRadius:Number = radius / CAMERA_DISTANCE * camera.zoom * camera.focus;
			var rotation:Number = dragVec.length / aRadius * 180 / Math.PI;
			
			var dragAxis:Vector3D = dragVec.crossProduct(new Vector3D(0,0,1));
			dragAxis.normalize();
			
			dragMatrix.identity();
			dragMatrix.appendRotation(rotation, dragAxis);
			
			targetRotMatrix = lastRotMatrix.clone();
			targetRotMatrix.append(dragMatrix);
			
			rotationAxis = dragAxis;
		}
		
		private function onRollOver(event:MouseEvent):void {
			over = true;
		}
		
		private function onRollOut(event:MouseEvent):void {
			over = false;
		}
		
		private function onClick(event:MouseEvent):void {
			var dragVec:Vector3D = new Vector3D(0, -lastMouseY + view.mouseY, -view.mouseX + lastMouseX);
			
			move = false;
			
			var hit:Vector3D = Utilities.pickSphereXY(view.mouseX, view.mouseY, radius, camera);
			if (hit != null) { 
				tracker.x = hit.x; tracker.y = hit.y; tracker.z = hit.z; 
			}
			
			var hs:HotSpot = getHotSpotUnderMouse();
			
			if (dragVec.lengthSquared < 100) {
				if (hs == null || (selectedHS != hs && selectedHS != null)) {
					deselectHotSpot();
					targetRotAxis = initRotAxis;
					targetRotSpeed = initRotSpeed;
					//rotationSpeed = 0.12 * rotationSpeed;
				} else {
					// yes, we hit a hotspot!!
					selectHotSpot(hs);
					// stop rotation
					rotationSpeed = rotationSpeed * 0.12;
					targetRotSpeed = 0;
					bringToCenter(view.mouseX, view.mouseY);
				}
			} else {
				// user drags the mouse far enough so that it can't be called a click
				//if (hs != selectedHS) 
					deselectHotSpot();
					targetRotAxis = initRotAxis;
					targetRotSpeed = initRotSpeed;
			}
		}

		private function onDoubleClick(event:MouseEvent):void {
			//navigateToURL(new URLRequest("http://www.google.com.np"), '_blank');
			//return;
			
			var hs:HotSpot = getHotSpotUnderMouse();
			if (hs != null) {
				if (selectedHS == null) {
					selectHotSpot(hs);
					// stop rotation
					rotationSpeed = rotationSpeed * 0.12;
					targetRotSpeed = 0;
					bringToCenter(view.mouseX, view.mouseY);
				}
				
				hs.navigate();
			}
		}
		
		private function onMouseWheel(event:MouseEvent):void {
			targetZoom += event.delta * ZOOM_STEP;
			if (targetZoom > zoomMax) targetZoom = zoomMax;
			if (targetZoom < zoomMin) targetZoom = zoomMin;
		}
		
		private var dtBeforeSleep:Number = 0;
		private var prevFrameRate:Number = 60;
		protected function onActivate(event:Event):void {
			curTime = getTimer();
			lastTime = curTime - dtBeforeSleep;
			stage.frameRate = prevFrameRate;
		}
		
		protected function onDeactivate(event:Event):void {
			curTime = getTimer();
			dtBeforeSleep = curTime - lastTime;
			prevFrameRate = stage.frameRate;
			stage.frameRate = 0;
		}
		
		// the loop ------------------------------------------
		protected override function onPreRender():void {
			curTime = getTimer();
		    var dt:int = curTime - lastTime;
		
			// interpolate to original speed/direction
			if (!move) {
				var newAxis:Vector3D = globe.transform.matrix3D.transformVector(targetRotAxis);
				rotationAxis = Utilities.lerpVector3D(rotationAxis, newAxis, INTERPOLATION_SPEED * dt);
				rotationSpeed = Utilities.lerpNumber(rotationSpeed, targetRotSpeed, INTERPOLATION_SPEED * dt);
				
				//globe.transform.matrix3D.appendRotation(rotationSpeed * dt, rotationAxis);
				targetRotMatrix.appendRotation(rotationSpeed, rotationAxis);
			}
			
			globe.transform.matrix3D.interpolateTo(targetRotMatrix, 0.005 * dt);
			
			invMatrix = globe.transform.matrix3D.clone();
			invMatrix.invert();

			zoom = Utilities.lerpNumber(zoom, targetZoom, INTERPOLATION_SPEED * dt);
			//camera.z = -camDist;
			camera.zoom = zoom;
			
			// the timing
			lastTime = curTime;
		}
		
		public function getHotSpotUnderMouse():HotSpot {
			var i:int;
			
			var hit:Vector3D = Utilities.pickSphereXY(view.mouseX, view.mouseY, radius, camera);
			
			var noHit:Boolean = true;
			
			/** test code */
//			var v:Vector3D = hit;
//			v = Utilities.project(camera, v);
//			//debugText.x = view.x + v.x * camera.zoom;
//			//debugText.y = view.y + v.y * camera.zoom;
//			debugText.text = hit.toString() + " to " + v.toString();
			/*************/
			
			if (hit != null) {
				var uv:Point = Utilities.getRotatedUV(hit, invMatrix);
				
				var wx:int = uv.x * earthImage.width;
				var wy:int = uv.y * earthImage.height;
				
				for (i = 0; i < hotSpots.length; i++) {
					var hs:HotSpot = HotSpot(hotSpots[i]);
					
					// hotSpots already ordered according to z
					if (hs.checkHit(wx, wy)) {
						return hs;
					}
				}
			}
			
			return null;
		}
		
		private var selectedHS:HotSpot = null;
		
		private function selectHotSpot(hs:HotSpot):void {
			if (hs == null) return;
			if (hs == selectedHS) return;
			
			selectedHS = hs;
			
			// prepare the composite texture
			globeImage.copyPixels(earthImageBW, new Rectangle(0,0,earthImageBW.width, earthImageBW.height), new Point());
			globeImage.draw(hs.getImage(), new Matrix(1,0,0,1,hs.x, hs.y));
			
		}
		
		private function deselectHotSpot():void {
			globeImage.copyPixels(earthImage, new Rectangle(0,0,earthImageBW.width, earthImageBW.height), new Point());
			selectedHS = null;

		}
		
		private function setupDebug():void {
			debug1.selectable = false;
			debug1.mouseEnabled = false;
			debug1.mouseWheelEnabled = false;
			debug1.defaultTextFormat = new TextFormat("Tahoma", 12, 0x000000);
			debug1.autoSize = "left";
			debug1.x = 0;
			debug1.y = 0;
			debug1.textColor = 0xFFFFFF;
			debug1.filters = [new GlowFilter(0x000000, 1, 4, 4, 2, 1)];
			//debug1.wordWrap = true;
			
			addChild(debug1);	
			
			debug = false;
		}
		
		// members -------------------------------------------
		private var initialized:Boolean = false;
		
		private var resourceBase:String = "assets/";
		
		private var earthLoader:Loader;
		private var backLoader:Loader;
		private var earthImage:BitmapData = null;
		private var earthImageBW:BitmapData = null;
		private var globeImage:BitmapData = null;
	
		private var globeMaterial:BitmapMaterial = null;
		
		private var radius:Number = 150;
		private var segments:Number = 40;
		private var globe:Sphere = null;
		private var tracker:Sphere = null;
		
		private var move:Boolean = false;
		private var over:Boolean = false;
		
		private var lastMouseX:Number = 0;
		private var lastMouseY:Number = 0;
		
		private var zoom:Number = 750;
		private var targetZoom:Number = 750;
		private var zoomMin:Number = 600;
		private var zoomMax:Number = 800;
		private const ZOOM_STEP:Number = 1;
		
		private var rotMatrix:Matrix3D = new Matrix3D();
		private var invMatrix:Matrix3D = new Matrix3D();
		// current interpolated values
		private var rotationAxis:Vector3D  = new Vector3D();
		private var rotationSpeed:Number = 0;	
		// target values
		private var targetRotAxis:Vector3D  = new Vector3D();
		private var targetRotSpeed:Number = 0;	
		private var targetRotMatrix:Matrix3D = new Matrix3D();
		private var lastRotMatrix:Matrix3D = new Matrix3D();
		
		// residual rotation
		private const initRotAxis:Vector3D = new Vector3D(0,-1,0);
		private var initRotSpeed:Number = 0.15;
		
		// the hotspots
		private var hotSpots:Array = new Array();
		
		// debugging
		private var debug1:TextField = new TextField();
		private var debug2:TextField;
		
		private var lastTime:int;
		private var curTime:int;
		
		// settings
		private var settings:XML;
		private var settingsLoader:URLLoader = new URLLoader();
		
		public static var newTab:String = "true";
		
		// constants
		public static const CAMERA_DISTANCE:Number = 1500;
		
		public static const MAX_ROTATION_SPEED:Number = 0.08;
		public static const INTERPOLATION_SPEED:Number = 0.008;
	}
}