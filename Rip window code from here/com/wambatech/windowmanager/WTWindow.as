
		
		
		public function rollOverhandler(event:MouseEvent):void 
		{ 
			if (contentInstance != null)
				contentInstance.dispatchEvent(new WTWindowContentEvent(WTWindowContentEvent.WINDOW_MOUSE_OVER)); 
		}
		
		public function rollOuthandler(event:MouseEvent):void 
		{ 
			if (contentInstance != null)
				contentInstance.dispatchEvent(new WTWindowContentEvent(WTWindowContentEvent.WINDOW_MOUSE_OUT)); 
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
						widthTween = new Tween(this, "_windowWidth", Strong.easeOut, _windowWidth, bounds.width, WTWindowManager.WINDOW_TWEEN_SPEED, true);
					
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
				
				manager.runEventDispatch("window_maximized", id);
			}
		}
		
		private function minimize(event:MouseEvent):void
		{
			if (container.sortMethod==0)
			{
				changeTo(new Rectangle(x, y, _windowWidth, (_topRightCorner.height + _bottomRightCorner.height)), false);
				manager.runEventDispatch("window_minimized", id);
			}
		}
		
		public function update():void
		{
			if (maximized == true)
			{
				lastX = x;
				lastY = y;
				lastHeight = _windowHeight;
				lastWidth = _windowWidth;
				
				changeTo(new Rectangle(0, 0, container.innerWidth, container.innerHeight), true);
			}
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
			
			if (lateHideWindowDecorations)
			{
				lateHideWindowDecorations = false;
				hideWindowDecorations();
			}
			
			manager.destroySnapHint();
			manager.runEventDispatch("window_resized", id);
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
			
			if (lateHideWindowDecorations)
			{
				lateHideWindowDecorations = false;
				hideWindowDecorations();
			}
			
			globalDragTimer.stop();
			manager.destroySnapHint();
			
			manager.runEventDispatch("window_dragged", id);			
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
				contentLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadError);				
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
			manager.runEventDispatch("window_content_loaded", this.id);
			contentInstance = contentLoader.content;
			contentInstance.loadSetupData(this, delayedSetupData);
		}
		
		private function loadError(event:IOErrorEvent):void
		{
			manager.runEventDispatch("window_content_load_error", this.id);
			destroy();
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
			
			return response;
		}
		
		public function hideWindowDecorations():void 
		{
			if (resizing || globalDrag || hideWindowDecoration)
			{
				lateHideWindowDecorations = true;
				return;
			}
			
			_topSide.alpha = 0;
			_topSide.enabled = false;
			_topSide.x = 0;
			_topSide.y = 0;
			
			_bottomSide.alpha = 0;
			_bottomSide.enabled = false;
			_bottomSide.x = 0;
			_bottomSide.y = 0;
			
			_topRightCorner.alpha = 0;
			_topRightCorner.enabled = false;
			_topRightCorner.x = 0;
			_topRightCorner.y = 0;
			
			_topLeftCorner.alpha = 0;
			_topLeftCorner.enabled = false;
			_topLeftCorner.x = 0;
			_topLeftCorner.y = 0;
			
			_bottomRightCorner.alpha = 0;
			_bottomRightCorner.enabled = false;
			_bottomRightCorner.x = 0;
			_bottomRightCorner.y = 0;
			
			_bottomLeftCorner.alpha = 0;
			_bottomLeftCorner.enabled = false;
			_bottomLeftCorner.x = 0;
			_bottomLeftCorner.y = 0;
			
			_rightSide.alpha = 0;
			_rightSide.enabled = false;
			_rightSide.x = 0;
			_rightSide.y = 0;
			
			_leftSide.alpha = 0;
			_leftSide.enabled = false;
			_leftSide.x = 0;
			_leftSide.y = 0;
			
			_closeBtn.alpha = 0;
			_closeBtn.enabled = false;
			_closeBtn.x = 0;
			_closeBtn.y = 0;
			
			_maximizeBtn.alpha = 0;
			_maximizeBtn.enabled = false;
			_maximizeBtn.x = 0;
			_maximizeBtn.y = 0;
			
			_minimizeBtn.alpha = 0;
			_minimizeBtn.enabled = false;
			_minimizeBtn.x = 0;
			_minimizeBtn.y = 0;
			
			_titlebarText.alpha = 0;
			//_titlebarText.enabled = false;
			_titlebarText.x = 0;
			_titlebarText.y = 0;
			
			_closeBtn.alpha = 0;
			_closeBtn.enabled = false;
			
			_maximizeBtn.alpha = 0;
			_maximizeBtn.enabled = false;
			
			_minimizeBtn.alpha = 0;
			_minimizeBtn.enabled = false;
			
			hideWindowDecoration = true;
			
			_windowWidth = _windowWidth + 1;
			_windowWidth = _windowWidth - 1
			_windowHeight = _windowHeight + 1;
			_windowHeight = _windowHeight - 1;
		}
		
		public function showWindowDecorations():void
		{
			lateHideWindowDecorations = false;
			
			if (!hideWindowDecoration)
				return;
			
			_topSide.alpha = 1;
			_topSide.enabled = true;			
			
			_bottomSide.alpha = 1;
			_bottomSide.enabled = true;			
			
			_topRightCorner.alpha = 1;
			_topRightCorner.enabled = true;
						
			_topLeftCorner.alpha = 1;
			_topLeftCorner.enabled = true;
						
			_bottomRightCorner.alpha = 1;
			_bottomRightCorner.enabled = true;
						
			_bottomLeftCorner.alpha = 1;
			_bottomLeftCorner.enabled = true;
						
			_rightSide.alpha = 1;
			_rightSide.enabled = true;
						
			_leftSide.alpha = 1;
			_leftSide.enabled = true;
			
			_closeBtn.alpha = 1;
			_closeBtn.enabled = true;
			
			_maximizeBtn.alpha = 1;
			_maximizeBtn.enabled = true;
			
			_minimizeBtn.alpha = 1;
			_minimizeBtn.enabled = true;
			
			_titlebarText.alpha = 1;
			//_titlebarText.enabled = true;
			
			_closeBtn.alpha = 1;
			_closeBtn.enabled = true;
			
			_maximizeBtn.alpha = 1;
			_maximizeBtn.enabled = true;
			
			_minimizeBtn.alpha = 1;
			_minimizeBtn.enabled = true;
						
			hideWindowDecoration = false;
			
			_windowWidth = _windowWidth + 1;
			_windowWidth = _windowWidth - 1;
			_windowHeight = _windowHeight + 1;
			_windowHeight = _windowHeight - 1;
		}
		
		public function set _windowWidth(val:Number):void
		{
			if (contentInstance != null && CurrentWindowWidth != val)
			{
				if (hideWindowDecoration)
				{
					contentInstance.dispatchEvent(new WTWindowContentEvent(WTWindowContentEvent.WINDOW_WIDTH_CHANGED, val));			
				} else {
					contentInstance.dispatchEvent(new WTWindowContentEvent(WTWindowContentEvent.WINDOW_WIDTH_CHANGED, val - (_leftSide.width + _rightSide.width)));			
				}
			}
			
			CurrentWindowWidth = val;		
			
			if (_topSide == null)
				return;
				
			if (hideWindowDecoration)
			{
				_background.x = 0;
				_contentMask.x = 0;
				_contentContainer.x = 0;
				_background.width = val;
				_contentMask.width = val;
			} else {			
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
			}
		}	
		public function get _windowWidth():Number
		{
			return CurrentWindowWidth;
		}
		
		public function set _windowHeight(val:Number):void
		{
			if (contentInstance != null && CurrentWindowHeight != val)
			{
				if (hideWindowDecoration)
				{
					contentInstance.dispatchEvent(new WTWindowContentEvent(WTWindowContentEvent.WINDOW_HEIGHT_CHANGED, val));			
				} else {
					contentInstance.dispatchEvent(new WTWindowContentEvent(WTWindowContentEvent.WINDOW_HEIGHT_CHANGED, val - (_topSide.height + _bottomSide.height)));			
				}
			}
			
			CurrentWindowHeight = val;
			
			if (_topSide == null)
				return;
			
			if (hideWindowDecoration)
			{
				_background.y = 0;
				_contentMask.y = 0;
				_contentContainer.y = 0;
				_background.height = val;
				_contentMask.height = val;
			} else {			
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