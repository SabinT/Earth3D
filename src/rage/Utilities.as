package rage
{
	import away3dlite.cameras.Camera3D;
	
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.sampler.NewObjectSample;

	public class Utilities
	{
		public function Utilities() {
			
		}
		
		public static function unproject(mX:Number, mY:Number, camera:Camera3D):Vector3D
		{	
//			var persp:Number = (camera.focus * camera.zoom) / camera.focus;
//			var vector:Vector3D = new Vector3D(mX/persp, -mY/persp, camera.focus);
//			vector = camera.transform.matrix3D.deltaTransformVector(vector);
			
			var vector:Vector3D = new Vector3D(mX/camera.zoom, -mY/camera.zoom, camera.focus);
			vector = camera.transform.matrix3D.deltaTransformVector(vector);
			
			return vector;
		}
		
		public static function project(camera:Camera3D, v:Vector3D):Vector3D {
			var m:Matrix3D = camera.transform.matrix3D.clone();
			m.invert();
			v = m.transformVector(v);
			v = camera.projectionMatrix3D.transformVector(v);
			return v;
		}
		
		// retrieve the 3-D point on the given sphere corresponding to the screen coordinates
		public static function pickSphereXY(x:Number, y:Number, radius:Number, camera:Camera3D):Vector3D {
			var rayDir:Vector3D = unproject(x * 1.05, y * 1.05, camera);
			rayDir.normalize();	
			//var p:Vector3D = new Vector3D(x,y,
			return	pickSphere(camera.transform.matrix3D.position, rayDir, radius);
		}
		
		public static function pickSphere(p:Vector3D, d:Vector3D, r:Number):Vector3D {
			var a:Number = d.x*d.x + d.y*d.y + d.z*d.z;
			var b:Number = 2 * (p.x * d.x + p.y * d.y + p.z * d.z);
			var c:Number = p.x * p.x + p.y * p.y + p.z * p.z - r*r;
			
			var det:Number = b*b - 4*a*c;
			
			if (det < 0) return null;
			
		
			// out of the two intersections, return the one closer to p on the given direction
			var u1:Number = (-b + Math.sqrt(det)) / 2*a;
			var u2:Number = (-b - Math.sqrt(det)) / 2*a;
		
			/**
			* The y-axis is positive downwards in Away3D Lite, so fix the coordinates
			*/
			var hit1:Vector3D = new Vector3D();
			hit1.x = p.x + d.x * u1;
			hit1.y = -(p.y + d.y * u1);
			hit1.z = p.z + d.z * u1;
			
			var hit2:Vector3D = new Vector3D();
			hit2.x = p.x + d.x * u2;
			hit2.y = -(p.y + d.y * u2);
			hit2.z = p.z + d.z * u2;
			
			//if (d.dotProduct(hit1) >= 0) return hit2;
			//else return hit1;
			
			if ((hit1.subtract(p)).lengthSquared > (hit1.subtract(p)).lengthSquared ) return hit1;
			else return hit2;
		}
		
		/**
		 * Correct the apparent point on a rotated sphere to its original position and
		 * return the UV.
		 * @invMatrix is the inverse transform of the rotated sphere
		 */
		public static function getRotatedUV(p:Vector3D, invMatrix:Matrix3D):Point {
			return getUV(invMatrix.transformVector(p));
		}
		
		/** Get the UV of a point as wrapped in a sphere centered at origin.
		 *  Note: since Away3DLite is y-downwards, the V is goes from 0 to 1 downwards.
		 */
		public static function getUV(p:Vector3D):Point {
			var lat:Number = Math.asin(p.y / Math.sqrt(p.x*p.x + p.y*p.y + p.z*p.z)) * 180 / Math.PI;
			
			var longi:Number = Math.atan(p.z / p.x) * 180 / Math.PI;
			if (p.x < 0) { 
				longi += 180;
			}
			else if (p.z < 0) {
				longi += 360;
			}
			
			return new Point(longi/360.0, lat/180.0 + 0.5);
		}
		
		public static function getVector3D(uv:Point):Vector3D {
			var u:Number = uv.x;
			var v:Number = uv.y;
			
			var theta:Number = (v - 0.5) * 2 * 90 * Math.PI / 180;
			var phi:Number = u * 360 * Math.PI / 180;
			
			// for unit sphere
			var y:Number = 1 * Math.sin(theta);
			var rxz:Number = Math.cos(theta);
			
			var x:Number = rxz * Math.cos(phi);
			var z:Number = rxz * Math.sin(phi);
			
			return new Vector3D(x, y, z);
		}
		
		/**
		 * Transform the apparent UV on a rotated sphere to the actual location 
		 * on the original sphere.
		 */
		public static function transformUV (current:Point, invMatrix:Matrix3D):Point {
			var p:Vector3D = getVector3D(current);
			return getRotatedUV(p, invMatrix);
		}
		
		/**
		 * Some functions to ease interpolation 
		 * The factor f should be ideally in the range [0,1], 
		 * other values would result in extrapolation
		 */
		public static function lerpNumber (a:Number, b:Number, f:Number):Number {
			return a + (b - a) * f;
		}
		
		public static function lerpVector3D (a:Vector3D, b:Vector3D, f:Number):Vector3D {
			var d:Vector3D = b.subtract(a);
			d.scaleBy(f);
			return d.add(a);
		}
	}
}