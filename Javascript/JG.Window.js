if(!window.JG)
    JG = {};

JG.Window = 
    function(settings) {

		let index = 0;
		let maximized = false;
		let resizing = false;
		let lastX = 0;
		let lastY = 0;
		let lastHeight = 0;
		let lastWidth = 0;
		let id = undefined;
		let container = undefined;
		let manager = undefined;
		let sortOrder = 0;
		let defaultBounds = undefined;
		let hideWindowDecoration = false;
		let depth = 0;
		
		let CurrentWindowWidth = 200;
		let CurrentWindowHeight = 200;
		let windowTitle = "Generic Window";
		let resizeTimer = undefined;
		let dragDockTimer = undefined;
		let globalDragTimer = undefined;
		let snapTime = 0;
		let snappingActive = false;
		let snapWait = 0;		
		let _titlebarText = undefined;
		let _topSide = undefined;
		let _leftSide = undefined;
		let _rightSide = undefined;
		let _bottomSide = undefined;
		let _topLeftCorner = undefined;
		let _topRightCorner = undefined;
		let _bottomLeftCorner = undefined;
		let _bottomRightCorner = undefined;
		let _minimizeBtn = undefined;
		let _maximizeBtn = undefined;
		let _closeBtn = undefined;
		let _contentMask = undefined;
		let _background = undefined;
		let _contentContainer = undefined;
		let widthTween = undefined;
		let heightTween = undefined;
		let xTween = undefined;
		let yTween = undefined;
		let fadeTween = undefined;
		let dragStartX = 0;
		let dragStartY = 0;
		let defaultContent = "";
		let contentInstance = undefined;
		let globalDrag = false;
		let storedSetupData = undefined;
		let contentLoader = undefined;
		let delayedSetupData = undefined;
		let lateHideWindowDecorations = false;

		function init(settings) {

			theWindowManager = settings.windowManager;
			initialContainer = settings.initialContainer;
			theDefaultContent = settings.theDefaultContent || "";
			setupData = settings.setupData || null;

			this.alpha = 0;
			
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
			
			if (setupData.id != null)
				id = setupData.id;					
					
			storedSetupData = setupData;
			defaultContent = theDefaultContent;
			sortOrder = id;
			
			_titlebarText = getChildByName("titleBar_txt");
			_topSide = getChildByName("TopSide_mc");
			_leftSide = getChildByName("LeftSide_mc");
			_rightSide = getChildByName("RightSide_mc");
			_bottomSide = getChildByName("BottomSide_mc");
			_topLeftCorner = getChildByName("TopLeftCorner_mc");
			_topRightCorner = getChildByName("TopRightCorner_mc");
			_bottomLeftCorner = getChildByName("BottomLeftCorner_mc");
			_bottomRightCorner = getChildByName("BottomRightCorner_mc");
			_minimizeBtn = getChildByName("min_btn");
			_maximizeBtn = getChildByName("max_btn");
			_closeBtn = getChildByName("close_btn");
			_contentMask = getChildByName("contentMask_mc");
			_background = getChildByName("Background_mc");
			_contentContainer = getChildByName("contentContainer_mc");
			
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
			
			addEventListener(MouseEvent.MOUSE_OVER, rollOverhandler);
			addEventListener(MouseEvent.MOUSE_OUT, rollOuthandler);
			addEventListener(MouseEvent.MOUSE_DOWN, getFocus);
			
			if (WTWindowManager.USE_WINDOW_ANIMATION)
			{
				fadeTween = new Tween(this, "alpha", Strong.easeOut, 0, 1, WTWindowManager.WINDOW_TWEEN_SPEED, true);
			} else {
				this.alpha = 1;
			}
				
			container.addWindow(this);
						
			defaultBounds = new Rectangle(0, 0, _windowWidth, _windowHeight);
									
			if (storedSetupData.x != null)
				x = storedSetupData.x;
				
			if (storedSetupData.y != null)
				y = storedSetupData.y;
				
			if (storedSetupData.width != null)
				_windowWidth = storedSetupData.width;
				
			if (storedSetupData.height != null)
				_windowHeight = storedSetupData.height;
				
			if (storedSetupData.defaultContent != null)
			{
				defaultContent = storedSetupData.defaultContent;
			} else {
				loadContent(defaultContent);
			}
			
			if (storedSetupData.sortOrder)
				sortOrder = storedSetupData.sortOrder;
				
			//_contentContainer.addChild(WTWindowContent(contentInstance));
			
			//if (storedSetupData == null)
				container.update();
				
			_windowWidth = CurrentWindowWidth;
			_windowHeight = CurrentWindowHeight;
		}


		init(settings);
    };