///////////////////////////////////////////////////////////////////////////////////////
//
// WAMBATECH NODE EVENTS
//
// CUSTOM EVENTS FOR NODES
//
// TODO:
//		ADD EVENT FOR NODE COLLAPSING / UNCOLLAPSING
//
// FUTURE FEATURES:
//
///////////////////////////////////////////////////////////////////////////////////////

package 
{ 
 	import flash.events.Event;
   
	public class WTNodeEvent extends Event 
	{   
   		public static const SELECTED:String = "selected";
		
		public var itemKey:Object;
		
		public function WTNodeEvent(type:String, customArg:Object = null, bubbles:Boolean=false, cancelable:Boolean=false) 
		{
			super(type, bubbles, cancelable);
			this.itemKey = customArg;
		}
		
		public override function clone():Event 
		{
			return new WTNodeEvent(type, itemKey, bubbles, cancelable);
		}
		
		public override function toString():String 
		{
			return formatToString("WTNodeEvent", "type", "itemKey", "bubbles", "cancelable", "eventPhase");
		}
	}
}

