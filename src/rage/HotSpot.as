package rage
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import org.osmf.utils.URL;

	public class HotSpot
	{
		public function HotSpot() {
			
		}
		
		public function load(imageURL:String, _x:int, _y:int, _z:int, linkURL:String, _baseMap:BitmapData):void
		{
			x = _x;
			y = _y;
			z = _z;
			setLink(linkURL);
			baseMap = _baseMap;
			
			// start loading the image
			loader = LoaderUtils.load(new URLRequest(imageURL));
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
		}
		
		private function loadXML (xml:XML):void {

		}
		
		private function imageLoaded(event:Event):void {
			bdata = Bitmap(loader.content).bitmapData;
			w = bdata.width;
			h = bdata.height;
			// extract portion of image from the original map			
			bdata = BitmapUtils.composeMaskedImage(baseMap, bdata, x, y);
			// dispose the original b/w map
			Bitmap(loader.content).bitmapData.dispose();
			loader = null;
		}
		
		// x and y are relative to the base-map, not the hotspot!
		public function checkHit(wx:int, wy:int):Boolean {
			if (wx < x || wx >= x + bdata.width) return false;
			if (wy < y || wy >= y + bdata.height) return false;
			
			wx -= x;
			wy -= y;
			
			var col:uint = bdata.getPixel32(wx, wy);
			if (BitmapUtils.getAlpha(col) > 128) return true;
			else return false;
		}
			
		public function navigate():void {
			try {
				if (Globe.newTab == "true")
					navigateToURL(link, '_blank');
				else
					navigateToURL(link, '_self');
			} catch (e:Error) {
				trace("Error occurred while trying to navigate to: " + link.url);
			}
		}
		// members -----------------------------------
		
		// the rectangular image of the hotspot. threshold 50%. white means selected regions
		private var bdata:BitmapData = null;
		private var loader:Loader = null;
		
		// reference to the base map
		private var baseMap:BitmapData = null;
		
		// the position of the hotspot on the original map, y positive downwards
		// make sure the big map and this hotspot's image are the same scale
		public var x:int = 0;
		public var y:int = 0;
		public var w:uint = 0;
		public var h:uint = 0;
		// the layering order, higher z shows over lower z
		public var z:int = 0;
		
		private var link:URLRequest = new URLRequest("http://www.google.com");
		
		// getters and setters ------------------------
		public function getImage():BitmapData { return bdata; }
		
		public function getLink():URLRequest { return link; }
		public function setLink(url:String):void {
			link = new URLRequest(url);
			if (link == null) {
				link = new URLRequest("http://www.google.com");
			}
		}
	}
}