///////////////////////////////////////////////////////////////////////////////////////
//
// WAMBATECH WINDOW CONTAINER
//
// STORES CONTAINERS & WINDOWS AS CHILDREN
// FACILITATES DISPLAY METHODS SUCH AS FREEFORM AND TILED
//
// TODO:
//		add drag snapping
//		add fulscreenining
//		add resize snapping
//
// FUTURE FEATURES:
//		OPTION TO HAVE WINDOW DECORATIONS HIDE UNTIL MOUSE IS OVER CONTAINER
//
///////////////////////////////////////////////////////////////////////////////////////

package
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.geom.Point;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;	
	import fl.transitions.easing.*;
	import flash.display.DisplayObject;
	import flash.text.TextField;
	
	public class WTWindowContainer extends MovieClip
	{
		public static var index:int = 0;
		
		public var id:int;
		public var container:WTWindowContainer;
		public var manager:WTWindowManager;
		public var sortMethod:int = 0; // 0 == normal (no sort), 1 == Width wise, 2 == Height wise.
		public var innerWidth:Number = 0;
		public var innerHeight:Number = 0;
		public var globalInnerBounds:Rectangle;
		public var sortOrder:Number = 0;
		public var defaultBounds:Rectangle;
		public var _contentContainer:MovieClip;
		
		private var maximized:Boolean = false;
		private var resizing:Boolean = false;
		private var resizeTimer:Timer;
		private var changeToTimeout:Timer;
		private var resetPositions = false;
		private var CurrentContainerWidth:Number = 200;
		private var CurrentContainerHeight:Number = 200;
		private var _titlebarText:TextField;
		private var _topSide:MovieClip;
		private var _leftSide:MovieClip;
		private var _rightSide:MovieClip;
		private var _bottomSide:MovieClip;
		private var _topLeftCorner:MovieClip;
		private var _topRightCorner:MovieClip;
		private var _bottomLeftCorner:MovieClip;
		private var _bottomRightCorner:MovieClip;
		private var _minimizeBtn:MovieClip;
		private var _maximizeBtn:MovieClip;
		private var _closeBtn:MovieClip;
		private var _contentMask:MovieClip;
		private var _background:MovieClip;
		private var widthTween:Tween;
		private var heightTween:Tween;
		private var xTween:Tween;
		private var yTween:Tween;		
		private var fadeTween:Tween;
		private var dragStartX:Number = 0;
		private var dragStartY:Number = 0;
		private var storedSetupData:Object;
		
		// Constructor
		public function WTWindowContainer(theWindowManager:WTWindowManager, initialContainer:WTWindowContainer, setupData:Object = null)
		{
			// if no WindowManager is provide, reject request.
			if (theWindowManager == null)
				return;
			
			manager = theWindowManager;
			id = WTWindowContainer.index;			
			WTWindowContainer.index ++;
			
			if (setupData != null)
			{
				id = setupData.id;					
				sortMethod = setupData.sortMethod;
				storedSetupData = setupData;
			}
						
			if (initialContainer != null)
				container = initialContainer;
							
			globalInnerBounds = new Rectangle();
			
			addEventListener(Event.ENTER_FRAME, initialize);
		}
		
		// ensure flash is actually ready to go before kicking into gear.
		private function initialize(event:Event)
		{
			removeEventListener(Event.ENTER_FRAME, initialize);
			stop();
			
			sortOrder = id;
			
			_titlebarText = getChildByName("titleBar_txt") as TextField;
			_topSide = getChildByName("TopSide_mc") as MovieClip;
			_leftSide = getChildByName("LeftSide_mc") as MovieClip;
			_rightSide = getChildByName("RightSide_mc") as MovieClip;
			_bottomSide = getChildByName("BottomSide_mc") as MovieClip;
			_topLeftCorner = getChildByName("TopLeftCorner_mc") as MovieClip;
			_topRightCorner = getChildByName("TopRightCorner_mc") as MovieClip;
			_bottomLeftCorner = getChildByName("BottomLeftCorner_mc") as MovieClip;
			_bottomRightCorner = getChildByName("BottomRightCorner_mc") as MovieClip;
			_minimizeBtn = getChildByName("min_btn") as MovieClip;
			_maximizeBtn = getChildByName("max_btn") as MovieClip;
			_closeBtn = getChildByName("close_btn") as MovieClip;
			_contentMask = getChildByName("contentMask_mc") as MovieClip;
			_background = getChildByName("Background_mc") as MovieClip;
			_contentContainer = getChildByName("contentContainer_mc") as MovieClip;
			
			_titlebarText.text = "Window Container";
			
			_closeBtn.addEventListener(MouseEvent.CLICK, closeContainer);
			
			_bottomRightCorner.addEventListener(MouseEvent.MOUSE_DOWN, startResize);
			resizeTimer = new Timer(1, 0);
			resizeTimer.addEventListener(TimerEvent.TIMER, doResize);
			_bottomRightCorner.useHandCursor = true;
			
			_topSide.addEventListener(MouseEvent.MOUSE_DOWN, dragStart);
			_titlebarText.addEventListener(MouseEvent.MOUSE_DOWN, dragStart);
			_topLeftCorner.addEventListener(MouseEvent.MOUSE_DOWN, dragStart);
			_topRightCorner.addEventListener(MouseEvent.MOUSE_DOWN, dragStart);
			
			_containerWidth = CurrentContainerWidth;
			_containerHeight = CurrentContainerHeight;
			
			if (container != null)
				container.addContainer(this);
			
			if (WTWindowManager.USE_WINDOW_ANIMATION)
				fadeTween = new Tween(this, "alpha", Strong.easeOut, 0, 1, WTWindowManager.WINDOW_TWEEN_SPEED, true);
				
			addEventListener(MouseEvent.MOUSE_DOWN, getFocus);
			
			if (storedSetupData != null)
			{
				x = storedSetupData.x;
				y = storedSetupData.y;
				_containerWidth = storedSetupData.width;
				_containerHeight = storedSetupData.height;
				
				if (storedSetupData.sortOrder)
					sortOrder = storedSetupData.sortOrder;
			} else {
				if (container != null)
					container.update();
			}
		}
		
		public function changeTo(bounds:Rectangle, dontSaveBounds:Boolean = false):void
		{
			if (dontSaveBounds == false && bounds != null)
				updateDefaultPosition();
			
			if (WTWindowManager.USE_WINDOW_ANIMATION)
			{
				// verify the new position is possible.
				if (qualifyDimensions(bounds))
				{
					if (changeToTimeout != null)
						changeToTimeout.stop()
						
					changeToTimeout = new Timer((WTWindowManager.WINDOW_TWEEN_SPEED * 1000), 1);
					changeToTimeout.addEventListener(TimerEvent.TIMER, changeToComplete);
					
					// stop & null any tweens that might be active already
					if (widthTween != null)
						widthTween.stop();
						
					if (heightTween != null)
						heightTween.stop();
					
					if (xTween != null)
						xTween.stop();
					
					if (yTween != null)
						yTween.stop();
					
					// figure out what aspects actuall need to be tweened to
					if (bounds.width != _containerWidth)
						widthTween = new Tween(this, "_containerWidth", Strong.easeOut, _containerWidth, bounds.width, WTWindowManager.WINDOW_TWEEN_SPEED, true);

					if (bounds.height != _containerHeight)
						heightTween = new Tween(this, "_containerHeight", Strong.easeOut, _containerHeight, bounds.height, WTWindowManager.WINDOW_TWEEN_SPEED, true);
						
					if (bounds.x != x)
						xTween = new Tween(this, "x", Strong.easeOut, x, bounds.x, WTWindowManager.WINDOW_TWEEN_SPEED, true);
						
					if (bounds.y != y)
						yTween = new Tween(this, "y", Strong.easeOut, y, bounds.y, WTWindowManager.WINDOW_TWEEN_SPEED, true);
				
					changeToTimeout.start();
				} 
			} else {
				// skip animation and just change the windows properties.
				x = bounds.x;
				y = bounds.y;
				_containerWidth = bounds.width;
				_containerHeight = bounds.height;
				update();
			}			
		}
		
		// called after animation has finished (if animation is enabled)
		private function changeToComplete(event:Event):void { update(); }
		
		public function updateDefaultPosition():void
		{
			if (container != null)
			{
				if (container.sortMethod == 0)			
					defaultBounds = new Rectangle(x, y, _containerWidth, _containerHeight);
			}
		}
		
		// used to verify that a rectangle exists inside its container.
		private function qualifyDimensions(bounds:Rectangle):Boolean
		{
			if (container == null)
				return true;
			
			if (bounds == null)
				return false;
			
			if (bounds.x < 0 || bounds.right > container.width || bounds.y < 0 || bounds.bottom > container.height)
				return false;
				
			return true;
		}
		
		private function startResize(event:MouseEvent):void
		{			
			if (container == null)
				return;
		
			if(maximized == false && container.sortMethod == 0) 
			{
				resizing = true;
				_bottomRightCorner.startDrag(false, new Rectangle(60, 30, container.innerWidth - _bottomRightCorner.width - 60 - x, container.innerHeight - _bottomRightCorner.height - 30 - y));
				activateDragFailsafe();
				resizeTimer.start();
			}
		}
		
		private function stopResize(event:MouseEvent):void
		{
			resizing = false;			
			_bottomRightCorner.stopDrag();
			resizeTimer.stop();
			update();
			//dragDockTimer.stop();
			_containerWidth = CurrentContainerWidth;
			_containerHeight = CurrentContainerHeight;
		}
		
		private function doResize(event:TimerEvent):void
		{
			_containerWidth = _bottomRightCorner.x + _bottomRightCorner.width;
			_containerHeight = _bottomRightCorner.y + _bottomRightCorner.height;
		}
		
		private function activateDragFailsafe():void
		{
			stage.addEventListener(MouseEvent.MOUSE_UP, deactivateDragFailsafe);
		}
		
		private function deactivateDragFailsafe(event:MouseEvent = null):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, deactivateDragFailsafe);
			
			if (resizing)
			{
				stopResize(null);
			} else {
				dragStop(null);
			}
		}
		
		private function dragStart(event:MouseEvent)
		{
			if (container == null)
				return;
				
			if(maximized == false) 
			{
				startDrag(false, new Rectangle(0, 0, (container.innerWidth - _containerWidth), (container.innerHeight - _containerHeight)));				
				activateDragFailsafe();
			}
	  	}
		
		private function dragStop(event:MouseEvent)
		{			
			var dragDirX:Number = 0;
			var dragDirY:Number = 0;
			
			if (dragStartX > x) {dragDirX = -1;}
			if (dragStartX < x) {dragDirX = 1;}
			if (dragStartY > y) {dragDirY = -1;}
			if (dragStartY < y) {dragDirY = 1;}
					
			if(maximized == false && container != null) 
				stopDrag();				
				
			if (container != null)
				container.resortChildren(this, dragDirX, dragDirY);
	  	}
		
		public function addWindow(window:WTWindow):void 
		{ 
			_contentContainer.addChild(window); 
		}
		
		public function removeWindow(window:WTWindow):void 
		{ 
			_contentContainer.removeChild(window);
		}
		
		public function addContainer(container:WTWindowContainer):void 
		{
			_contentContainer.addChild(container);
		}
		
		public function removeContainer(container:WTWindowContainer):void 
		{ 
			_contentContainer.removeChild(container); 
		}
		
		// if windows are automatically arranged in some fashion, do it now.
		public function update() { runPositionSorting(); }
		
		public function resortChildren(priorityWindow:Object, dragDirX:Number, dragDirY:Number):void
		{
			var windows:Array;
			var sortIndex:int;
			var tmpObj:Object;
			
			if (sortMethod == 1)
			{
				priorityWindow.x += dragDirX;
				windows = manager.getAllObjectsInContainer(this);
				windows.sortOn("x", Array.NUMERIC);
				
				for each(tmpObj in windows)
				{
					tmpObj.sortOrder = sortIndex;					
					sortIndex ++;
				}
				
				priorityWindow.x -= dragDirX;
			} else if (sortMethod == 2) {
				priorityWindow.y += dragDirY;
				windows = manager.getAllObjectsInContainer(this);
				windows.sortOn("y", Array.NUMERIC);
				
				for each(tmpObj in windows)
				{
					tmpObj.sortOrder = sortIndex;					
					sortIndex ++;
				}
				
				priorityWindow.y -= dragDirY;
			}
			
			update();
		}
		
		private function runPositionSorting():void
		{
			var windows:Array;
			var numberOfWindows:int;
			var i:int;
			
			if (sortMethod == 1)
			{
				windows = manager.getAllObjectsInContainer(this);
				windows.sortOn("sortOrder", Array.NUMERIC);
				numberOfWindows = windows.length;
				
				if (numberOfWindows == 0)
					return;
					
				var perWindowWidth:Number = (innerWidth / numberOfWindows);
					
				for (i = 0; i < windows.length; i++)
				{
					var newX:Number = (i * perWindowWidth);					
					windows[i].changeTo(new Rectangle(newX, 0, perWindowWidth, innerHeight), true);
				}				
				
				resetPositions = true;
			} else if (sortMethod == 2) {
				windows = manager.getAllObjectsInContainer(this);
				windows.sortOn("sortOrder", Array.NUMERIC);
				numberOfWindows = windows.length;
				
				if (numberOfWindows == 0)
					return;
					
				var perWindowHeight:Number = (innerHeight / numberOfWindows);
					
				for (i = 0; i < windows.length; i++)
				{
					var newY:Number = (i * perWindowHeight);					
					windows[i].changeTo(new Rectangle(0, newY, innerWidth, perWindowHeight), true);
				}				
				
				resetPositions = true;
			} else if (sortMethod == 0) {
				if (resetPositions)
				{					
					windows = manager.getAllObjectsInContainer(this);
					
					for (i = 0; i < windows.length; i++)
					{
						windows[i].changeTo(windows[i].defaultBounds, true);
					}				
					
					resetPositions = false;
				}
			}
		}
				
		public function closeContainer(event:MouseEvent):void
		{
			if (WTWindowManager.USE_WINDOW_ANIMATION && container != null)
			{
				fadeTween = new Tween(this, "alpha", Strong.easeOut, alpha, 0, WTWindowManager.WINDOW_TWEEN_SPEED, true);
				fadeTween.addEventListener(TweenEvent.MOTION_FINISH, finishCloseContainer);
			} else {
				destroy();
			}
		}
				
		private function finishCloseContainer(event:TweenEvent):void { destroy(); }
		
		public function destroy() { manager.destroyContainer(this); }
		
		public function serialize(level:int):String
		{
			var tmpXML:String = "";
			var tabPadding:String = "";			
			for (var o:int = 0; o <= level; o++) { tabPadding += "\t"; }
			var parentID:int = -1;
			
			if (container != null)
				parentID = container.id;
			
			tmpXML = tabPadding + "<WTWindowContainer sortOrder='" + sortOrder + "' parentID='" + parentID + "' sortMethod='" + sortMethod + "' x='" + x + "' y='" + y + "' width='" + _containerWidth + "' height='" + _containerHeight + "' id='" + id + "'>\n";
			
			var children:Array;
			children = manager.getAllObjectsInContainer(this);
			
			for (var i:int = 0; i < children.length; i++) { tmpXML += children[i].serialize((level + 1)); }
			
			tmpXML += tabPadding + "</WTWindowContainer>\n";
			return tmpXML;
		}
		
		public function getFocus(event:MouseEvent):void 
		{ 
			setFocus(); 
			event.stopPropagation();
		}
		
		public function setFocus():void
		{
			if (container != null)
			{
				container.forceFocus(this);
			} else {
				manager.changeFocusedObject(this)
			}
		}
		
		public function forceFocus(whichObject:DisplayObject):void
		{			
			manager.changeFocusedObject(whichObject);
											
			if((_contentContainer.numChildren - 1) > _contentContainer.getChildIndex(whichObject))
      			_contentContainer.swapChildrenAt((_contentContainer.numChildren - 1), _contentContainer.getChildIndex(whichObject));
		}
		
		public function getGlobalOffsets():Point
		{
			var tmpPoint:Point = new Point(0,0);
			var tmpObj:Object = this;
			
			while (tmpObj != null)
			{
				tmpPoint.x += tmpObj.x + tmpObj._contentContainer.x;
				tmpPoint.y += tmpObj.y + tmpObj._contentContainer.y;
				
				if (tmpObj.container != null)
				{
					tmpObj = tmpObj.container;
				} else {
					tmpObj = null;
				}
			}
			
			return tmpPoint;
		}
		
		public function set _containerWidth(val:Number):void
		{
			CurrentContainerWidth = val;
			
			if (_topSide == null)
				return;
			
			// resize each piece of the 'window' movieclip individually.
			_topSide.x = _topLeftCorner.width - 2;
			_topSide.width = (val - (_topLeftCorner.width + _topRightCorner.width)) + 4;
			
			_bottomSide.x = _bottomLeftCorner.width - 2;
			_bottomSide.width = (val - (_bottomLeftCorner.width + _bottomRightCorner.width)) + 4;
			
			_topRightCorner.x = val - _topRightCorner.width;
			_bottomRightCorner.x = val - _bottomRightCorner.width;
			
			_topLeftCorner.x = 0;
			_bottomLeftCorner.x = 0;
			
			_rightSide.x = val - _rightSide.width;
			_leftSide.x = 0;
	
			_titlebarText.x = _topLeftCorner.width - 5;
			_titlebarText.width = val - (_leftSide.width + _rightSide.width + _closeBtn.width + _maximizeBtn.width + _minimizeBtn.width);
	
			_background.x = _leftSide.width;
			_contentMask.x = _leftSide.width;
			_contentContainer.x = _leftSide.width;
			_background.width = val - (_leftSide.width + _rightSide.width);
			_contentMask.width = val - (_leftSide.width + _rightSide.width);
			
			_closeBtn.x = (val - _topRightCorner.width - _closeBtn.width) + 17;
			_maximizeBtn.x = _closeBtn.x - _maximizeBtn.width;
			_minimizeBtn.x = (_maximizeBtn.x - _minimizeBtn.width) - 1;
			
			innerWidth = val - (_leftSide.width + _rightSide.width);
			
			var tmpPoint:Point = getGlobalOffsets();
			
			globalInnerBounds.left = tmpPoint.x;
			globalInnerBounds.right = tmpPoint.x + (val - (_leftSide.width + _rightSide.width));
		}	
		public function get _containerWidth():Number
		{
			return CurrentContainerWidth;
		}
		
		public function set _containerHeight(val:Number):void
		{
			CurrentContainerHeight = val;
			
			if (_topSide == null)
				return;
			
			// resize each piece of the 'window' movieclip individually.
			_topSide.y = 0;
			_bottomSide.y = val - _bottomSide.height;
			
			_leftSide.y = _topLeftCorner.height - 2;
			_leftSide.height = (val - (_topLeftCorner.height + _bottomLeftCorner.height)) + 4;
			
			_rightSide.y = _topRightCorner.height - 2;
			_rightSide.height = (val - (_topRightCorner.height + _bottomRightCorner.height)) + 4;
					
			_bottomLeftCorner.y = val - _bottomLeftCorner.height;
			//if (this._parent[ActualName].resizing==false) {this._parent[ActualName].BottomRightCorner_mc._y=(val-(this._parent[ActualName].BottomRightCorner_mc._height));}
			_bottomRightCorner.y = val - _bottomRightCorner.height;
			
			_topLeftCorner.y = 0;
			_topRightCorner.y = 0;
			
			_titlebarText.y = 0;
			
			_background.y = _topSide.height;
			_contentMask.y = _topSide.height;
			_contentContainer.y = _topSide.height;
			_background.height = val - (_topSide.height + _bottomSide.height);
			_contentMask.height = val - (_topSide.height + _bottomSide.height);
			
			_titlebarText.y = 4;
			
			_closeBtn.y = 5;
			_maximizeBtn.y = 5;
			_minimizeBtn.y = 5;
			
			innerHeight = val - (_topSide.height + _bottomSide.height);
			
			var tmpPoint:Point = getGlobalOffsets();
			globalInnerBounds.top = tmpPoint.y;
			globalInnerBounds.bottom = tmpPoint.y + (val - (_topSide.height + _bottomSide.height));
		}	
		public function get _containerHeight():Number
		{
			return CurrentContainerHeight;
		}
	}
}