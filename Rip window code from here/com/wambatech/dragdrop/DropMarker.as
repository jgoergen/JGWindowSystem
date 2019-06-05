///////////////////////////////////////////////////////////////////////////////////////
//
// WAMBATECH DROP MARKER
//
// VISUALLY SHOW DROP TARGETS FOR THE DRAG DROP SYSTEM
//
// TODO:
//
// FUTURE FEATURES:
//
///////////////////////////////////////////////////////////////////////////////////////

package com.wambatech.dragdrop
{
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.events.Event;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;	
	import fl.transitions.easing.*; 
	import flash.geom.Rectangle;
	import flash.geom.ColorTransform;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import com.wambatech.dragdrop.DragDropManager;
	
	public class DropMarker extends Sprite
	{
		public var targetBounds:Rectangle;
		
		private var graphicObject:Object;
		private var targetRef:Object;
		
		public function DropMarker(targetMarkerSize:Rectangle, theTargetRef:Object)
		{
			trace("dm made");
			targetBounds = targetMarkerSize;
			targetRef = theTargetRef;
			
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
									
			graphicObject.transform.colorTransform = new ColorTransform(0, 0, 0, 0, 100, 0, 0, 80);
			
			addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
			addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
		}
		
		private function mouseOverHandler(event:MouseEvent):void
		{
			DragDropManager.dropTargetObject = targetRef;				
			graphicObject.transform.colorTransform = new ColorTransform(100, 100, 0, 0, 100, 100, 0, 80);
		}
		
		private function mouseOutHandler(event:MouseEvent):void
		{			
			if (parent == null)
				return;
			
			if (DragDropManager.dropTargetObject == targetRef)
				DragDropManager.dropTargetObject = null;
				
			graphicObject.transform.colorTransform = new ColorTransform(0, 0, 0, 0, 100, 0, 0, 80);
		}
		
		public function destroy():void
		{
			removeEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
			removeEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
			
			parent.removeChild(this);
		}
	}
}