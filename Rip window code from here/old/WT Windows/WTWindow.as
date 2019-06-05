///////////////////////////////////////////////////////////////////////////////////////
//
// WAMBATECH WINDOW
//
// CONTAINS WINDOW CONTENT
// FACILITATES WINDOW CONTENT COMMUNICATION WITH WINDOW MANAGER
// FACILITATES DRAGGING, SNAPPING, RESIZING AND DECORATION
//
// TODO:
//		FIX BOUNDS QUALIFIER
//
// FUTURE FEATURES:
//		OPTION TO HAVE WINDOW DECORATIONS HIDE UNTIL MOUSE IS OVER CONTAINER
//		CONSIDER GESTURE BASED ACTIONS 
//			CORNERS FOR MAXIMIZE
//
///////////////////////////////////////////////////////////////////////////////////////

package
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.utils.getDefinitionByName;
	import flash.events.MouseEvent;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import flash.utils.getTimer;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;	
	import fl.transitions.easing.*; 
	import flash.net.URLRequest;
	import flash.display.Loader;
	import flash.text.TextField;
	
	public class WTWindow extends MovieClip
	{
		public static var index:int = 0;
		public var maximized:Boolean = false;
		public var resizing:Boolean = false;
		public var lastX:Number = 0;
		public var lastY:Number = 0;
		public var lastHeight:Number = 0;
		public var lastWidth:Number = 0;
		public var id:int;
		public var container:WTWindowContainer;
		public var manager:WTWindowManager;
		public var sortOrder:Number = 0;
		public var defaultBounds:Rectangle;
		
		private var CurrentWindowWidth:Number = 200;
		private var CurrentWindowHeight:Number = 200;
		private var windowTitle:String = "Generic Window";
		private var resizeTimer:Timer;
		private var dragDockTimer:Timer;
		private var globalDragTimer:Timer;
		private var snapTime:int = 0;
		private var snappingActive:Boolean = false;
		private var snapWait:int = 0;		
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
		private var _contentContainer:MovieClip;
		private var widthTween:Tween;
		private var heightTween:Tween;
		private var xTween:Tween;
		private var yTween:Tween;
		private var fadeTween:Tween;
		private var dragStartX:Number = 0;
		private var dragStartY:Number = 0;
		private var defaultContent:String = "";
		private var contentInstance:Object;
		private var globalDrag:Boolean = false;
		private var storedSetupData:Object;
		private var contentLoader:Loader;
		private var delayedSetupData:Object;
		
		// Constructor
		public function WTWindow(theWindowManager:WTWindowManager, initialContainer:WTWindowContainer, theDefaultContent:String = "", setupData:Object = null)
		{
			// if no WindowManager is provide, reject request.
			if (theWindowManager == null)
				return;
			
			// if no container is provided toss the request out.
			if (initialContainer == null)
				return;
			
			manager = theWindowManager;
			container = initialContainer;
			id = WTWindow.index;
			WTWindow.index ++;
			
			if (setupData != null)
			{
				id = setupData.id;					
				storedSetupData = setupData;
			}
			
			defaultContent = theDefaultContent;
			
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
			
			_titlebarText.text = windowTitle;
			_titlebarText.doubleClickEnabled = true;			
			_titlebarText.addEventListener(MouseEvent.DOUBLE_CLICK, maximize);
			
			_topSide.doubleClickEnabled = true;
			_topSide.addEventListener(MouseEvent.DOUBLE_CLICK, maximize);
			
			_closeBtn.addEventListener(MouseEvent.CLICK, closeWindow);
			_maximizeBtn.addEventListener(MouseEvent.CLICK, maximize);
			_minimizeBtn.addEventListener(MouseEvent.CLICK, minimize);
						
			_topSide.addEventListener(MouseEvent.MOUSE_DOWN, dragStart);
			//_topSide.addEventListener(MouseEvent.MOUSE_UP, dragStop);
			_titlebarText.addEventListener(MouseEvent.MOUSE_DOWN, dragStart);
			//_titlebarText.addEventListener(MouseEvent.MOUSE_UP, dragStop);
			_topLeftCorner.addEventListener(MouseEvent.MOUSE_DOWN, dragStart);
			//_topLeftCorner.addEventListener(MouseEvent.MOUSE_UP, dragStop);
			_topRightCorner.addEventListener(MouseEvent.MOUSE_DOWN, dragStart);
			//_topRightCorner.addEventListener(MouseEvent.MOUSE_UP, dragStop);
						
			_bottomRightCorner.addEventListener(MouseEvent.MOUSE_DOWN, startResize);
			//_bottomRightCorner.addEventListener(MouseEvent.MOUSE_UP, stopResize);
			resizeTimer = new Timer(1, 0);
			resizeTimer.addEventListener(TimerEvent.TIMER, doResize);
			
			dragDockTimer = new Timer(1, 0);
			dragDockTimer.addEventListener(TimerEvent.TIMER, doDocking);
			
			globalDragTimer = new Timer(100, 0);
			globalDragTimer.addEventListener(TimerEvent.TIMER, watchForGlobaldrag);
			
			_bottomRightCorner.useHandCursor = true;
			
			_windowWidth = CurrentWindowWidth;
			_windowHeight = CurrentWindowHeight;
			
			addEventListener(MouseEvent.MOUSE_DOWN, getFocus);
			
			if (WTWindowManager.USE_WINDOW_ANIMATION)
				fadeTween = new Tween(this, "alpha", Strong.easeOut, 0, 1, WTWindowManager.WINDOW_TWEEN_SPEED, true);
				
			container.addWindow(this);
						
			defaultBounds = new Rectangle(0, 0, _windowWidth, _windowHeight);
						
			if (storedSetupData != null)
			{
				x = storedSetupData.x;
				y = storedSetupData.y;
				_windowWidth = storedSetupData.width;
				_windowHeight = storedSetupData.height;
				defaultContent = storedSetupData.defaultContent;
				
				if (storedSetupData.sortOrder)
					sortOrder = storedSetupData.sortOrder;
					
				//_contentContainer.addChild(WTWindowContent(contentInstance));
			} else {
				container.update();
				loadContent(defaultContent);
			}
		}
		
		public function getFocus(event:MouseEvent):void 
		{ 
			setFocus(); 
			event.stopPropagation();
		}
		
		public function changeTo(bounds:Rectangle, dontSaveBounds:Boolean = false):void
		{
			if (bounds == null)
				return;
			
			if (dontSaveBounds == false)
				updateDefaultPosition();
			
			if (WTWindowManager.USE_WINDOW_ANIMATION)
			{
				// verify the new position is possible.
				if (qualifyDimensions(bounds))
				{
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
					if (bounds.width != _windowWidth)
					{
						widthTween = new Tween(this, "_windowWidth", Strong.easeOut, _windowWidth, bounds.width, WTWindowManager.WINDOW_TWEEN_SPEED, true);
					}
					if (bounds.height != _windowHeight)
						heightTween = new Tween(this, "_windowHeight", Strong.easeOut, _windowHeight, bounds.height, WTWindowManager.WINDOW_TWEEN_SPEED, true);
						
					if (bounds.x != x)
						xTween = new Tween(this, "x", Strong.easeOut, x, bounds.x, WTWindowManager.WINDOW_TWEEN_SPEED, true);
						
					if (bounds.y != y)
						yTween = new Tween(this, "y", Strong.easeOut, y, bounds.y, WTWindowManager.WINDOW_TWEEN_SPEED, true);
				} 
			} else {
				// skip animation and just change the windows properties.
				x = bounds.x;
				y = bounds.y;
				_windowWidth = bounds.width;
				_windowHeight = bounds.height;
			}
		}
		
		private function activateDragFailsafe():void { stage.addEventListener(MouseEvent.MOUSE_UP, deactivateDragFailsafe); }
		
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
		
		private function maximize(event:MouseEvent):void
		{
			if(maximized == true)
			{
				maximized = false;
				
				changeTo(new Rectangle(lastX, lastY, lastWidth, lastHeight), true);
				
			} else {
				maximized = true;
				
				lastX = x;
				lastY = y;
				lastHeight = _windowHeight;
				lastWidth = _windowWidth;
				
				changeTo(new Rectangle(0, 0, container.innerWidth, container.innerHeight), true);
			}
		}
		
		private function minimize(event:MouseEvent):void
		{
			if (container.sortMethod==0)
				changeTo(new Rectangle(x, y, _windowWidth, (_topRightCorner.height + _bottomRightCorner.height)), false);
		}
		
		private function startResize(event:MouseEvent):void
		{			
			if(maximized == false && container.sortMethod == 0) 
			{
				resizing = true;
				_bottomRightCorner.startDrag(false, new Rectangle(60, 30, container.innerWidth - _bottomRightCorner.width - 60 - x, container.innerHeight - _bottomRightCorner.height - 30 - y));
				activateDragFailsafe();
				resizeTimer.start();
				
				if (WTWindowManager.USE_RESIZE_SNAPPING)
				{
					snapWait = getTimer();
					dragDockTimer.start();
				}
			}
		}
		
		private function stopResize(event:MouseEvent):void
		{
			resizing = false;			
			_bottomRightCorner.stopDrag();				
			resizeTimer.stop();
			_windowWidth = CurrentWindowWidth;
			_windowHeight = CurrentWindowHeight;
			dragDockTimer.stop();
			manager.clearTemporarySnapPoints();
			
			// if snaphint was showing on stop then use it.
			if (manager.snapHintHandle != null)
			{
				changeTo(new Rectangle(manager.snapHintHandle.x - container.globalInnerBounds.left, manager.snapHintHandle.y - container.globalInnerBounds.top, manager.snapHintHandle.width, manager.snapHintHandle.height));
			}  else {
				updateDefaultPosition();
			}
			
			manager.destroySnapHint();
		}
		
		private function doResize(event:TimerEvent):void
		{
			_windowWidth = _bottomRightCorner.x + _bottomRightCorner.width;
			_windowHeight = _bottomRightCorner.y + _bottomRightCorner.height;
		}
		
		private function watchForGlobaldrag(event:TimerEvent):void
		{
			if (manager.controlKeyDown && globalDrag == false)
			{
				startGlobalDrag();
			} else if (manager.controlKeyDown == false && globalDrag) {
				cancelGlobalDrag();
			}
		}
		
		private function startGlobalDrag():void
		{			
			// clean up from regular drag
			stopDrag();
			
			globalDrag = true;
			container._contentContainer.removeChild(this);
			manager.addChild(this);
								
			startDrag(true, new Rectangle(0, 0, manager.width, manager.height));				
			//activateDragFailsafe();
								
			var tmpPoint:Point = container.getGlobalOffsets();
			x += tmpPoint.x;
			y += tmpPoint.y;
			
			changeTo(new Rectangle(x, y, 100, 100), true);
			
			dragStartX = x;
			dragStartY = y;
		}
		
		private function cancelGlobalDrag():void
		{
			dragStop(null);
			dragStart(null);
		}
		
		private function dragStart(event:MouseEvent)
		{
			if(maximized == false) 
			{
				startDrag(false, new Rectangle(0, 0, (container.innerWidth - _windowWidth), (container.innerHeight - _windowHeight)));				
				activateDragFailsafe();
				
				dragStartX = x;
				dragStartY = y;
				
				if (WTWindowManager.USE_DRAG_SNAPPING && container.sortMethod == 0)
				{
					snapWait = getTimer();
					dragDockTimer.start();
				}
				
				globalDragTimer.start();
			}
	  	}
		
		private function dragStop(event:MouseEvent)
		{
			var dragDirX:Number = 0;
			var dragDirY:Number = 0;
			
			if(maximized == false) 
			{
				if (globalDrag)
				{
					globalDrag = false;
					
					manager.clearTemporarySnapPoints();
					stopDrag();
					dragDockTimer.stop();
					
					var newContainer:WTWindowContainer = manager.findDropTarget(this);
					
					if (newContainer == null) 
						newContainer = manager.windowContainers[0];
					
					manager.changeParentContainer(this, newContainer);
					
					changeTo(new Rectangle(x, y, defaultBounds.width, defaultBounds.height), true);
					
					var tmpPoint:Point = container.getGlobalOffsets();
					x -= tmpPoint.x;
					y -= tmpPoint.y; 
						
					container.resortChildren(this, dragDirX, dragDirY);
				} else {
					manager.clearTemporarySnapPoints();
					stopDrag();
					dragDockTimer.stop();
					
					// if snaphint was showing on stop then use it.
					if (manager.snapHintHandle != null)
					{
						if (dragStartX > manager.snapHintHandle.x) {dragDirX = -1;}
						if (dragStartX < manager.snapHintHandle.x) {dragDirX = 1;}
						if (dragStartY > manager.snapHintHandle.y) {dragDirY = -1;}
						if (dragStartY < manager.snapHintHandle.y) {dragDirY = 1;}
						
						if (container.sortMethod == 0)
							changeTo(new Rectangle(manager.snapHintHandle.x - container.globalInnerBounds.left, manager.snapHintHandle.y - container.globalInnerBounds.top, _windowWidth, _windowHeight), false);
	
					} else {
						updateDefaultPosition();
					}
						
					container.resortChildren(this, dragDirX, dragDirY);
				}
			}
			
			globalDragTimer.stop();
			manager.destroySnapHint();
	  	}
		
		public function updateDefaultPosition():void
		{
			defaultBounds = new Rectangle(x, y, _windowWidth, _windowHeight);
		}
		
		private function doDocking(event:TimerEvent):void
		{
			if ((snapWait + WTWindowManager.SNAP_WAIT) > getTimer())
				return;
			
			if (manager.showingSnapPoints == false)
				manager.buildTemporarySnapPoints(true, this);
				
			if (snapTime + WTWindowManager.SNAP_TIME_ALLOW > getTimer())
			{
				if (resizing)
				{
					checkResizeSnapping();
				} else {
					checkDockSnapping();
				}				
			} else if (snapTime + WTWindowManager.SNAP_TIME_CLEAR < getTimer()) {
				if (resizing)
				{
					checkResizeSnapping();
				} else {
					checkDockSnapping();
				}
			}
		}
		
		private function checkResizeSnapping():void
		{
			var snapRect:Rectangle = new Rectangle();
			var snapFound:Boolean = false;
			
			var adjustedPosition:Rectangle = new Rectangle(x + container.globalInnerBounds.left, y + container.globalInnerBounds.top, _windowWidth, _windowHeight);
			
			for each(var point:Point in manager.getTemporarySnapPoints(true, this))
			{				
				if (adjustedPosition.left + _windowWidth >= point.x - WTWindowManager.SNAP_TOLERANCE && 
					adjustedPosition.left + _windowWidth <= point.x + WTWindowManager.SNAP_TOLERANCE &&
					adjustedPosition.top + _windowHeight >= point.y - WTWindowManager.SNAP_TOLERANCE && 
					adjustedPosition.top + _windowHeight <= point.y + WTWindowManager.SNAP_TOLERANCE)
				{
					if (snapTime + WTWindowManager.SNAP_TIME_CLEAR < getTimer())
						snapTime = getTimer();
						
					snapRect.left = adjustedPosition.left;
					snapRect.top = adjustedPosition.top;
					snapRect.bottomRight = point;
					snapFound = true;
					
				} else if (
					adjustedPosition.left >= point.x - WTWindowManager.SNAP_TOLERANCE && 
					adjustedPosition.left <= point.x + WTWindowManager.SNAP_TOLERANCE &&
					adjustedPosition.top + _windowHeight >= point.y - WTWindowManager.SNAP_TOLERANCE && 
					adjustedPosition.top + _windowHeight <= point.y + WTWindowManager.SNAP_TOLERANCE)
				{
					if (snapTime + WTWindowManager.SNAP_TIME_CLEAR < getTimer())
						snapTime = getTimer();
						
					snapRect.left = adjustedPosition.left;
					snapRect.top = adjustedPosition.top;
					snapRect.bottom = point.y;
					snapRect.right = adjustedPosition.left + _windowWidth;
					snapFound = true;
				} else if (
					adjustedPosition.left + _windowWidth >= point.x - WTWindowManager.SNAP_TOLERANCE && 
					adjustedPosition.left + _windowWidth <= point.x + WTWindowManager.SNAP_TOLERANCE &&
					adjustedPosition.top >= point.y - WTWindowManager.SNAP_TOLERANCE && 
					adjustedPosition.top <= point.y + WTWindowManager.SNAP_TOLERANCE)
				{
					if (snapTime + WTWindowManager.SNAP_TIME_CLEAR < getTimer())
						snapTime = getTimer();
						
					snapRect.left = adjustedPosition.left;
					snapRect.top = adjustedPosition.top;
					snapRect.bottom = adjustedPosition.top + _windowHeight;
					snapRect.right = point.x;
					snapFound = true;
				}
				
				if (snapFound && qualifyDimensions(snapRect))
				{
					if (WTWindowManager.USE_SNAP_HINTING)
					{
						manager.buildSnapHint(snapRect);
					} else {
						x = manager.snapHintHandle.x;
						y = manager.snapHintHandle.y;
						_windowWidth = snapRect.width;
						_windowHeight = snapRect.height;
					}
				} else {
					manager.destroySnapHint();
				}
			}
		}
		
		private function checkDockSnapping():void		
		{
			var snapRect:Rectangle = new Rectangle();
			var snapFound:Boolean = false;
			
			var adjustedPosition:Rectangle = new Rectangle(x + container.globalInnerBounds.left, y + container.globalInnerBounds.top, _windowWidth, _windowHeight);
			
			for each(var point:Point in manager.getTemporarySnapPoints(true, this))
			{				
				if (
					adjustedPosition.left >= point.x - WTWindowManager.SNAP_TOLERANCE && 
					adjustedPosition.left <= point.x + WTWindowManager.SNAP_TOLERANCE &&
					adjustedPosition.top >= point.y - WTWindowManager.SNAP_TOLERANCE && 
					adjustedPosition.top <= point.y + WTWindowManager.SNAP_TOLERANCE)
				{
					if (snapTime + WTWindowManager.SNAP_TIME_CLEAR < getTimer())
						snapTime = getTimer();
						
					snapRect.left = point.x;
					snapRect.top = point.y;
					snapFound = true;
				}
				else if (
					adjustedPosition.left + _windowWidth >= point.x - WTWindowManager.SNAP_TOLERANCE && 
					adjustedPosition.left + _windowWidth <= point.x + WTWindowManager.SNAP_TOLERANCE &&
					adjustedPosition.top >= point.y - WTWindowManager.SNAP_TOLERANCE && 
					adjustedPosition.top <= point.y + WTWindowManager.SNAP_TOLERANCE)
				{
					if (snapTime + WTWindowManager.SNAP_TIME_CLEAR < getTimer())
						snapTime = getTimer();
						
					snapRect.left = point.x - _windowWidth;
					snapRect.top = point.y;
					snapFound = true;
				}
				else if (
					adjustedPosition.left + _windowWidth >= point.x - WTWindowManager.SNAP_TOLERANCE && 
					adjustedPosition.left + _windowWidth <= point.x + WTWindowManager.SNAP_TOLERANCE &&
					adjustedPosition.top + _windowHeight >= point.y - WTWindowManager.SNAP_TOLERANCE && 
					adjustedPosition.top + _windowHeight <= point.y + WTWindowManager.SNAP_TOLERANCE)
				{
					if (snapTime + WTWindowManager.SNAP_TIME_CLEAR < getTimer())
						snapTime = getTimer();
						
					snapRect.left = point.x - _windowWidth;
					snapRect.top = point.y - _windowHeight;
					snapFound = true;
				}
				else if (
					adjustedPosition.left >= point.x - WTWindowManager.SNAP_TOLERANCE && 
					adjustedPosition.left <= point.x + WTWindowManager.SNAP_TOLERANCE &&
					adjustedPosition.top + _windowHeight >= point.y - WTWindowManager.SNAP_TOLERANCE && 
					adjustedPosition.top + _windowHeight <= point.y + WTWindowManager.SNAP_TOLERANCE)
				{
					if (snapTime + WTWindowManager.SNAP_TIME_CLEAR < getTimer())
						snapTime = getTimer();
						
					snapRect.left = point.x;
					snapRect.top = point.y - _windowHeight;
					snapFound = true;
				}
				
				if (snapFound && qualifyDimensions(snapRect))
				{
					if (WTWindowManager.USE_SNAP_HINTING)
					{
						snapRect.width = _windowWidth;
						snapRect.height = _windowHeight;
						
						manager.buildSnapHint(snapRect);
					} else {
						x = snapRect.left;
						y = snapRect.top;
					}
				} else {
					manager.destroySnapHint();
				}
			}
		}
		
		// used to verify that a rectangle exists inside its container.
		private function qualifyDimensions(bounds:Rectangle):Boolean
		{
			return true;
			
			if (bounds == null)
				return false;
			
			if (bounds.x < 0 || bounds.right > container.width || bounds.y < 0 || bounds.bottom > container.height)
				return false;
				
			return true;
		}
		
		public function loadContent(lid:String, setupData:Object = null):void 
		{
			if (lid == "" && lid != null)
				return;
							
			// is this internal or external?
			if (lid.substr(lid.length - 4, 4) == ".swf")
			{
				contentLoader = new Loader(); 
				var url:URLRequest = new URLRequest(lid); 				
				delayedSetupData = setupData;				
				contentLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, finishLoad);				
				contentLoader.load(url); 				
				return;
			} else {
				var classDefintion:Class = getDefinitionByName(lid) as Class;
				contentInstance = new classDefintion();
			}
			
			// when being restored the content container will not exist yet, init will handle this in that event.
			//if (_contentContainer != null)
				//_contentContainer.addChild(WTWindowContent(contentInstance));
						
			contentInstance.loadSetupData(this, setupData);
		}
		
		private function finishLoad(event:Event):void
		{
			contentInstance = contentLoader.content;
			contentInstance.loadSetupData(this, delayedSetupData);
		}
		
		public function addContent(theContent:WTWindowContent):void { _contentContainer.addChild(theContent); }
		
		public function contentReady(theWidth, theHeight):void { trace("Content ready signal recieved"); }
		
		public function showWindow():void { }
		
		public function closeWindow(event:MouseEvent):void
		{
			if (WTWindowManager.USE_WINDOW_ANIMATION)
			{
				fadeTween = new Tween(this, "alpha", Strong.easeOut, alpha, 0, WTWindowManager.WINDOW_TWEEN_SPEED, true);
				fadeTween.addEventListener(TweenEvent.MOTION_FINISH, finishCloseWindow);
			} else {
				destroy();
			}
		}
		
		private function finishCloseWindow(event:TweenEvent):void { destroy(); }
		
		public function destroy() { manager.destroyWindow(this); }
		
		public function serialize(level:int):String
		{
			var tmpXML:String = "";
			var tabPadding:String = "";			
			for (var o:int = 0; o <= level; o++) { tabPadding += "\t"; }

			tmpXML = tabPadding + "<WTWindow sortOrder='" + sortOrder + "' defaultContent='" + defaultContent + "' parentID='" + container.id + "' x='" + x + "' y='" + y + "' width='" + _windowWidth + "' height='" + _windowHeight + "' id='" + id + "'>\n";
			
			if (contentInstance != null && defaultContent != "")
				tmpXML += tabPadding + "\t" + contentInstance.serialize(defaultContent, id);
				
			tmpXML += tabPadding + "</WTWindow>\n";			
			return tmpXML;
		}
		
		public function getSnapPoints():Array
		{
			var response:Array = new Array();
			
			response.push(new Point(0 + container.globalInnerBounds.left, 0 + container.globalInnerBounds.top));
			response.push(new Point(_windowWidth + container.globalInnerBounds.left, 0 + container.globalInnerBounds.top));
			response.push(new Point(0 + container.globalInnerBounds.left, _windowHeight + container.globalInnerBounds.top));
			response.push(new Point(_windowWidth + container.globalInnerBounds.left, _windowHeight + container.globalInnerBounds.top));			
			
			/* non adjusted
			response.push(new Point(0, 0));
			response.push(new Point(_windowWidth, 0));
			response.push(new Point(0, _windowHeight));
			response.push(new Point(_windowWidth, _windowHeight));			
			*/
			
			return response;
		}
		
		public function set _windowWidth(val:Number):void
		{
			CurrentWindowWidth = val;		
			
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
			
			//this._parent[ActualName].contentContainer_mc._x=this._parent[ActualName].LeftSide_mc._width;
			//this._parent[ActualName].contentContainer_mc._width=(val-(this._parent[ActualName].LeftSide_mc._width+this._parent[ActualName].RightSide_mc._width));
			
			_closeBtn.x = (val - _topRightCorner.width - _closeBtn.width) + 17;
			_maximizeBtn.x = _closeBtn.x - _maximizeBtn.width;
			_minimizeBtn.x = (_maximizeBtn.x - _minimizeBtn.width) - 1;
		}	
		public function get _windowWidth():Number
		{
			return CurrentWindowWidth;
		}
		
		public function set _windowHeight(val:Number):void
		{
			CurrentWindowHeight = val;
			
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
		}	
		public function get _windowHeight():Number
		{
			return CurrentWindowHeight;
		}
		
		public function setFocus():void
		{
			if (!manager.controlKeyDown)
				container.forceFocus(this);
		}
	}
}