﻿///////////////////////////////////////////////////////////////////////////////////////
//
// WAMBATECH DRAG DROP MANAGER
//
// ANY DISPLAY OBJECT CAN USE THIS TO FACILITATE CREATING A COPY OF IT // AND PASSING A PAYLOAD TO ANY OBJECT THAT ITS DROPPED ON (ASSUMING THE OBJECT // SUPPORTS DRAG DROP).
//
// TODO:
//		DEEP OBJECT COPY
//		INIT DRAG
//		FIND OBJECTS UNDER MOUSE
//		QUERY VALID DROP TARGET
//		INIT DROP
//		CLEANUP
//
// FUTURE FEATURES:
//		HIGHLIGHT CURRENT DROP TARGET
//
///////////////////////////////////////////////////////////////////////////////////////

package com.wambatech.dragdrop
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.display.DisplayObject;	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Point;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;	
	import fl.transitions.easing.*; 
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.utils.getQualifiedClassName;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import com.wambatech.windowmanager.WTWindowContainer;
	
	public class DragDropManager extends MovieClip
	{				
		public static var DRAG_WAIT:Number = 500;
	
		public static var dragCopy:Sprite;		
		public static var theObject:Object;
		public static var objHandle:Object;
		public static var objDataType:String;
		public static var objData:Object;
		public static var dropTargetObject:Object;
		public static var dropTargets:Array;
		public static var dragTargets:Array;
		public static var delayTimer:Timer;
		public static var finishing:Boolean = false;
		public static var copyFadeInTween:Tween;
		public static var originalFadeOutTween:Tween;
		public static var returnTweenX:Tween;
		public static var returnTweenY:Tween;
		public static var returnTweenAlpha:Tween;
		public static var originalFadeInTween:Tween;
		public static var dropTargetResponseFunction:Function = null;
		public static var dropMarkerArray:Array;
		public static var dragOffset:Point;
		
		public static function registerDropObject(whatObject:Object, theDataType:String, theResponseFunction:Function = null):void
		{
			trace("registering " + whatObject);
			
			if (dropTargets == null)
				dropTargets = new Array();
				
			// dropTargetResponseFunction = responseFunction;
				
			dropTargets.push({object: whatObject, dataType: theDataType, responseFunction: theResponseFunction});
		}
		
		public static function unRegisterDropObject(whatObject:Object):void
		{
			if (dropTargets == null)
				return;
				
			for (var i:int = 0; i < dropTargets.length; i++)
			{
				if (dropTargets[i].object == whatObject)
				{
					dropTargets.splice(i, 1)
					break;
				}
			}
		}
		
		public static function registerDraggableObject(whatObject:Object, theDataType:String, theData:Object):void
		{					
			if (dragTargets == null)
				dragTargets = new Array();
				
			dragTargets.push({object: whatObject, dataType: theDataType, data: theData});
			
			whatObject.addEventListener(MouseEvent.MOUSE_DOWN, dragStart);
		}
		
		public static function unRegisterDraggableObject(whatObject:Object):void
		{
			whatObject.removeEventListener(MouseEvent.MOUSE_DOWN, dragStart);
			
			for (var i:int = 0; i < dragTargets.length; i++)
			{
				if (dragTargets[i].object == whatObject)
				{
					dropTargets.splice(i, 1)
					break;
				}
			}
		}
		
		public static function updateData(whatObject:Object, theData:Object)
		{
			for (var i:int = 0; i < dragTargets.length; i++)
			{
				if (dragTargets[i].object == whatObject)
				{
					dragTargets[i].data = theData
					break;
				}
			}
		}
		
		private static function dragStart(event:MouseEvent):void
		{
			if (dragOffset == null)
				dragOffset = new Point();
			
			dragOffset.x = event.localX;
			dragOffset.y = event.localY;
			
			if (getQualifiedClassName(event.target) == "flash.text::TextField")
			{
				//startDragDrop(event.target.parent);				
				theObject = event.currentTarget.parent;
				startDelayedStart();
			} else {
				//startDragDrop(event.target);
				theObject = event.currentTarget;
				startDelayedStart();
			}
			
			event.target.stage.addEventListener(MouseEvent.MOUSE_UP, dragStop);
		}
		
		private static function dragStop(event:MouseEvent):void
		{
			if (delayTimer == null)
				return;
				
			if (delayTimer.running)
			{
				delayTimer.stop();
				return;
			}
			
			stopDragDrop();
		}
		
		public static function startDelayedStart():void
		{
			if (delayTimer == null)
			{
				delayTimer = new Timer(DRAG_WAIT, 1);
				delayTimer.addEventListener(TimerEvent.TIMER, function() { startDragDrop(); });
			}
			
			delayTimer.start();
		}
		
		public static function startDragDrop():void
		{			
			for (var i:int = 0; i < dragTargets.length; i++)
			{
				if (dragTargets[i].object == theObject)
				{
					objDataType = dragTargets[i].dataType;
					objData = dragTargets[i].data;
					break;
				}
			}
			
			if (objDataType == null || objData == null)
				return;
		
			if (finishing)
				finishDragDrop();
									
			dragCopy = new Sprite();
			
			var dragCopyBMP:Sprite = new DragMarker(new Rectangle(0, 0, theObject.width, theObject.height));
			
			dragCopy.mouseEnabled = false;
			dragCopy.addChild(dragCopyBMP);
			dragCopy.startDrag();			
			
			var newPos:Point = new Point(theObject.stage.mouseX - dragOffset.x, theObject.stage.mouseY - dragOffset.y);
						
			dragCopy.x = newPos.x;
			dragCopy.y = newPos.y;
			
			objHandle = theObject;
			
			objHandle.stage.addChild(dragCopy);
			
			if (copyFadeInTween != null)
				copyFadeInTween.stop();
				
			if (originalFadeOutTween != null)
				originalFadeOutTween.stop();
			
			copyFadeInTween = new Tween(dragCopy, "alpha", Strong.easeOut, dragCopy.alpha, 0.5, 2, true);
									
			highlightDropTargets();
		}
				
		public static function stopDragDrop():void
		{
			objHandle.stage.removeEventListener(MouseEvent.MOUSE_UP, dragStop);
						
			finishing = true;
			dragCopy.stopDrag();
			
			if (dropTargetObject == null)
			{			
				var newPos:Point = objHandle.parent.localToGlobal(new Point(objHandle.x, objHandle.y));
				
				if (returnTweenX != null)
					returnTweenX.stop();
					
				if (returnTweenY != null)
					returnTweenY.stop();
					
				if (returnTweenAlpha != null)
					returnTweenAlpha.stop();
				
				returnTweenX = new Tween(dragCopy, "x", Strong.easeOut, dragCopy.x, newPos.x, .5, true);
				returnTweenY = new Tween(dragCopy, "y", Strong.easeOut, dragCopy.y, newPos.y, .5, true);
				returnTweenAlpha = new Tween(dragCopy, "alpha", Strong.easeOut, dragCopy.alpha, 0, .5, true);
				
				returnTweenAlpha.addEventListener(TweenEvent.MOTION_FINISH, finishDragDrop);
										
				if (originalFadeOutTween != null)
					originalFadeOutTween.stop();
				
				if (originalFadeInTween != null)
					originalFadeInTween.stop();
					
			} else {
				var globalPos:Point = new Point(dragCopy.x, dragCopy.y);
				var localPos:Point = dropTargetObject.globalToLocal(globalPos);
								
				if (dropTargetObject != null)
				{
					// get response function for the object were over				
					for (var i:int = 0; i < dropTargets.length; i++)
					{
						if (dropTargets[i].object == dropTargetObject)
						{
							dropTargets[i].responseFunction(objData, localPos);
							break;
						}
					}
				}
								
				finishDragDrop();
			}
		}
		
		public static function finishDragDrop(event:TweenEvent = null):void
		{			
			if (finishing == false || dragCopy.numChildren < 1)
				return;
			
			unHighlightDropTargets();
			
			finishing = false;
			
			if (returnTweenX != null)
				returnTweenX.stop();
				
			if (returnTweenY != null)
				returnTweenY.stop();
				
			if (returnTweenAlpha != null)
				returnTweenAlpha.stop();
				
			if (originalFadeOutTween != null)
				originalFadeOutTween.stop();
			
			if (originalFadeInTween != null)
				originalFadeInTween.stop();
				
			if (copyFadeInTween != null)
				copyFadeInTween.stop();
				
			if (originalFadeOutTween != null)
				originalFadeOutTween.stop();
				
			dragCopy.removeChildAt(0);
			objHandle.stage.removeChild(dragCopy);			
			objHandle = null;
			objDataType = null;
			objData = null;
			dropTargetObject = null;
		}
		
		public static function highlightDropTargets():void
		{
			if (dropTargets == null)
				return;
			
			if (dropTargets.length == 0)
				return;
				
			dropMarkerArray = new Array();
									
			for (var i:int = 0; i < dropTargets.length; i++)
			{
				if (dropTargets[i].dataType == objDataType && dropTargets[i].object.parent != null)
				{
					var soGhetto:Boolean = true;
					
					try
					{
						trace(dropTargets[i].object["dragDropMarkerLayer_mc"]);
					} catch(errObject:Error) {
						soGhetto = false;
					}
					
					if (soGhetto)
					{
						dropMarkerArray.push(new DropMarker(new Rectangle(0, 0, dropTargets[i].object.width, dropTargets[i].object.height), dropTargets[i].object));
						dropTargets[i].object["dragDropMarkerLayer_mc"].addChild(dropMarkerArray[(dropMarkerArray.length - 1)]);
					} else {
						dropMarkerArray.push(new DropMarker(new Rectangle(dropTargets[i].object.x, dropTargets[i].object.y, dropTargets[i].object.width, dropTargets[i].object.height), dropTargets[i].object));
						dropTargets[i].object.parent.addChild(dropMarkerArray[(dropMarkerArray.length - 1)]);
					}
				}
			}
		}
		
		public static function unHighlightDropTargets():void
		{					
			if (dropTargets == null)
				return;
				
			if (dropTargets.length == 0)
				return;
			
			for (var i:int = 0; i < dropMarkerArray.length; i++)
			{
				dropMarkerArray[i].destroy();
			}
		}
	}
}