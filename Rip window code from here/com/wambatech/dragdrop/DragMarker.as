///////////////////////////////////////////////////////////////////////////////////////
//
// WAMBATECH DRAG MARKER
//
// VISUALLY REPRESENT THE OBJECT YOUR DRAGGING FOR THE DRAG DROP SYSTEM
//
// TODO:
//
// FUTURE FEATURES:
//
///////////////////////////////////////////////////////////////////////////////////////

package com.wambatech.dragdrop
{
	import flash.display.Sprite;
	import flash.events.Event;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;	
	import fl.transitions.easing.*; 
	import flash.geom.Rectangle;
	import flash.geom.ColorTransform;
	
	public class DragMarker extends Sprite
	{
		public var targetBounds:Rectangle;
		
		private var graphicObject:Object;
		
		public function DragMarker(targetMarkerSize:Rectangle)
		{
			targetBounds = targetMarkerSize;
			
			addEventListener(Event.ENTER_FRAME, initialize);
		}
		
		private function initialize(event:Event)
		{
			removeEventListener(Event.ENTER_FRAME, initialize);
			
			graphicObject = getChildAt(0);
			
			x = targetBounds.x;
			y = targetBounds.y;
			graphicObject.width = targetBounds.width;
			graphicObject.height = targetBounds.height;
			
			this.mouseEnabled = false;
			this.mouseChildren = false;
						
			graphicObject.transform.colorTransform = new ColorTransform(0, 0, 0, 0, 0, 0, 100, 80);
		}
	}
}