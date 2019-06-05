///////////////////////////////////////////////////////////////////////////////////////
//
// WAMBATECH WINDOW MANAGER EVENTS
//
// CUSTOM EVENTS FOR WINDOWS AND WINDOW CONTAINERS
//
// TODO:
//
// FUTURE FEATURES:
//
///////////////////////////////////////////////////////////////////////////////////////

package com.wambatech.windowmanager
{ 
 	import flash.events.Event;
   
	public class WTWindowManagerEvent extends Event 
	{   
   		public static const WINDOW_MAXIMIZED:String = "Window_Maximixed";
		public static const WINDOW_MINIMIZED:String = "Window_Minimuzed";
		public static const WINDOW_SELECTED:String = "Window_Selected";
		public static const WINDOW_CLOSED:String = "Window_Closed";
		public static const WINDOW_DRAGGED:String = "Window_Dragged";
		public static const WINDOW_RESIZED:String = "Window_Resized";
		public static const WINDOW_CONTENT_LOADED:String = "Window_Content_Loaded";
		public static const WINDOW_CONTENT_LOAD_ERROR:String = "Window_Content_Load_Error";
		
		public static const CONTAINER_MAXIMIZED:String = "Container_Maximixed";
		public static const CONTAINER_MINIMIZED:String = "Container_Minimuzed";
		public static const CONTAINER_SELECTED:String = "Container_Selected";
		public static const CONTAINER_CLOSED:String = "Container_Closed";
		public static const CONTAINER_DRAGGED:String = "Container_Dragged";
		public static const CONTAINER_RESIZED:String = "Container_Resized";
		
		public var objectID:Object;
		
		public function WTWindowManagerEvent(type:String, customArg:Object = null, bubbles:Boolean=false, cancelable:Boolean=false) 
		{
			super(type, bubbles, cancelable);
			this.objectID = customArg;
		}
		
		public override function clone():Event 
		{
			return new WTWindowManagerEvent(type, objectID, bubbles, cancelable);
		}
		
		public override function toString():String 
		{
			return formatToString("WTWindowManagerEvent", "type", "objectID", "bubbles", "cancelable", "eventPhase");
		}
	}
}

