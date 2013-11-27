package rage
{
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Vector3D;
	
	import mx.utils.ColorUtil;

	public class BitmapUtils
	{
		public static function desaturate(bdata:BitmapData):void {
			var x:Number;
			var y:Number;
			var col:uint;
			var gray:uint;
			for (x = 0; x < bdata.width; x++) {
				for (y = 0; y < bdata.height; y++) {
					col = bdata.getPixel(x,y);
					gray = getGray(col);
					col = getColor(0,gray,gray,gray);
					bdata.setPixel(x,y, col);
				}
			}
			
		}
		
		public static function getColor(a:uint, r:uint, g:uint, b:uint):uint {
			return (a << 24) + (r << 16) + (g << 8) + b;
		}
		
		public static function getRGB(col:uint):Vector3D {
			var r:uint = (col >> 16) % 0x100;
			var g:uint = (col >> 8) % 0x100;
			var b:uint = col % 0x100;
			
			return new Vector3D(r,g,b);
		}
		
		public static function getAlpha(col:uint):uint {
			return (col >> 24) % 0x100;
		}
		
		public static function getGray(col:uint):uint {
			var r:uint = (col >> 16) % 0x100;
			var g:uint = (col >> 8) % 0x100;
			var b:uint = col % 0x100;
			
			return (r + g + b)/3;
		}
		
		/**
		 * Returns a new image (with alpha) at (x,y) in the source image, using the mask.
		 * Returned image same size as the mask.
		 * 
		 * Note: alpha 0 = transparent, 255 = opaque
		 */
		public static function composeMaskedImage(source:BitmapData, mask:BitmapData, xoff:uint, yoff:uint):BitmapData {
			var x:int;
			var y:int;
			var col:uint;
			var gray:uint;
			
			var img:BitmapData = new BitmapData(mask.width, mask.height, true);
			
			for (x = 0; x < img.width; x++) {
				for (y = 0; y < img.height; y++) {
					col = source.getPixel(xoff + x, yoff + y);
					gray = getGray(mask.getPixel(x,y));
					col = (col % 0x1000000) + ((gray) << 24);
					img.setPixel32(x, y, col);
				}
			}
			
			return img;
		}
	}
}