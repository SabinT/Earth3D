package rage
{
	import flash.display.Loader;
	import flash.events.Event;
	import flash.net.URLRequest;

	public class LoaderUtils
	{
		private static var  loaders:Array = new Array();
		private static var total:int = 0;
		private static var loaded:int = 0;
		
		private static var callback:Function = null;
		
		public static function load(url:URLRequest):Loader {
			var loader:Loader = new Loader();
			loaders.push(loader);
			total++;
			
			loader.load(url);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, singleLoadComplete);
			
			return loader;
		}
		
		// Done all loading. Now dispose and reset.
		public static function clear():void {
			loaders = new Array();
			total = 0;
			loaded = 0;
			callback = null;
		}
		
		/**
		 * Call this function after adding all the loaders. A no-parameter function expected.
		 */
		public static function setCallback(fn:Function):void {
			callback = fn;
			checkCompletion();
		}
		
		private static function singleLoadComplete(event:Event):void {
			loaded++;
			checkCompletion();
		}
		
		private static function checkCompletion():void {
			if (loaded == total) {
				if (callback != null) { 
					callback();
				}
			}
		}
	}
}