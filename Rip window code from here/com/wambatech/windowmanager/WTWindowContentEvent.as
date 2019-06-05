///////////////////////////////////////////////////////////////////////////////////////
//
// WAMBATECH WINDOW CONTENT EVENTS
//
// CUSTOM EVENTS FOR WINDOW CONTENT
//
// TODO:
//
// FUTURE FEATURES:
//
///////////////////////////////////////////////////////////////////////////////////////

package com.wambatech.windowmanager
{ 
 	import flash.events.Event;
   
	public class WTWindowContentEvent extends Event 
	{   
   		public static const WINDOW_HEIGHT_CHANGED:String = "Window_Height_Changed";
		public static const WINDOW_WIDTH_CHANGED:String = "Window_Width_Changed";
		public static const WINDOW_MOUSE_OVER:String = "Window_Mouse_Over";
		public static const WINDOW_MOUSE_OUT:String = "Window_Mouse_Out";
		
		public var newValue:Number;
		
		public function WTWindowContentEvent(type:String, customArg:Number = 0, bubbles:Boolean=false, cancelable:Boolean=false) 
		{
			super(type, bubbles, cancelable);
			this.newValue = customArg;
		}
		
		public override function clone():Event 
		{
			return new WTWindowContentEvent(type, newValue, bubbles, cancelable);
		}
		
		public override function toString():String 
		{
			return formatToString("WTWindowContentEvent", "type", "newValue", "bubbles", "cancelable", "eventPhase");
		}
	}
}

