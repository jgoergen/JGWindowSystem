package 
{ 
 	import flash.events.Event;
   
	public class WTHeaderEvent extends Event 
	{   
   		public static const SELECTED:String = "selected";
		
		public var itemKey:Object;
		
		public function WTHeaderEvent(type:String, customArg:Object = null, bubbles:Boolean=false, cancelable:Boolean=false) 
		{
			super(type, bubbles, cancelable);
			this.itemKey = customArg;
		}
		
		public override function clone():Event 
		{
			return new WTHeaderEvent(type, itemKey, bubbles, cancelable);
		}
		
		public override function toString():String 
		{
			return formatToString("WTHeaderEvent", "type", "itemKey", "bubbles", "cancelable", "eventPhase");
		}
	}
}

