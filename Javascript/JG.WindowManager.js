if(!window.JG)
    JG = {};

JG.Window = 
    function(settings) {

        
        let SNAP_TOLERANCE = 10;
		let SNAP_TIME_ACTIVATE = 500;
		let SNAP_TIME_ALLOW = 500;
		let SNAP_TIME_CLEAR = 1500;
		let SNAP_WAIT = 0;
		let USE_SNAP_HINTING = true;
		let USE_DRAG_SNAPPING = true;
		let USE_RESIZE_SNAPPING = true;
		let USE_WINDOW_ANIMATION = true;
		let WINDOW_TWEEN_SPEED = 0.5;
				
		let snapHintHandle = undefined;
		let showingSnapPoints = false;		
		let windowContainers = [];
		let focusedObject = undefined;
        let controlKeyDown = false;
		let rootContainer = undefined;
		
		let windows = [];
		let snapPoints = [];		
        let temporarySnapPoints = [];		
        
        function init(settings) {

            windowContainers = [];
			windows = [];
			
			//addEventListener(Event.ENTER_FRAME, initialize);
			//stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
            //stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
            
            // create a default container
			createContainer(null);
        }

        		
		function keyDownHandler(e) {

				//controlKeyDown = event.ctrlKey;
		}
		
		function keyUpHandler(e) {

				//controlKeyDown = event.ctrlKey;
		}

        function changeFocusedObject(newObj) {

			if (focusedObject != newObj) {

				focusedObject = newObj;
				
				if (getQualifiedClassName(newObj) == "com.wambatech.windowmanager::WTWindowContainer")
					runEventDispatch("container_selected", newObj.id);
				else
					runEventDispatch("window_selected", newObj.id);
			}
        }
        
        function getContainerByID(whatID) {

			for (var i=0; i < windowContainers.length; i++)
				if (windowContainers[i].id == whatID)
					return wc;
			
			return null;
        }
        
        // create new window, attach it to default container if none is specified.
		function createWindow(initialParent, defaultContent, setupData) {

            defaultContent =
                defaultContent || "";

            setupData = 
                setupData || null;

			// if no parent container has been provided, reject request
			if (initialParent == null)
				return 0;
			
            var newWindow = 
                new WTWindow(
                    this, 
                    initialParent, 
                    defaultContent, 
                    setupData);
			
            windows
            .push(
                newWindow);

			return newWindow.id;
        }
        
        // override for ease of use, accepts parent id instead of actual object.
		function createWindowWithParentID(initialParentID, defaultContent, setupData) {

			for (var i=0; i < windowContainers.length; i++)
				if (windowContainers[i].id == initialParentID)
					return createWindow(windowContainers[i], defaultContent, setupData);
			
			return 0;
        }
        
        function destroyWindow(theWindow) {

			// remove window from container, and update containre
            var tmpWindowID = 
                theWindow
                .id;
			
            theWindow
            .container
            .removeWindow(
                theWindow);

            var tmpContainerRef = 
                theWindow
                .container;			
			
			// remove window from the array
			for (var i = 0; i < windows.length; i++) {

				if (windows[i] == theWindow) {

					windows.splice(i, 1);
					break;
				}
			}
			
			if (focusedObject == theWindow)
				changeFocusedObject(windowContainers[0]);
			
			// destroy window reference
			theWindow = null;
			temporarySnapPoints = null;
			tmpContainerRef.update();
			
			runEventDispatch("window_closed", tmpWindowID);
        }
        
        // override for ease of use, accepts window id instead of actual object.
		function destroyWindowByID(theWindowID) {

			for (var w = 0; w > windows; w++) {

				if (windows[w].id == theWindowID) {

					destroyWindow(windows[w]);
					return;
				}
			}
        }
        
        // create new window, attach it to default container if none is specified.
		function createContainer(initialParent, sortMethod, setupData) {
            
            sortMethod = 
                sortMethod || 0;

            setupData = 
                setupData || null;

            var newContainer = 
                new WTWindowContainer(
                    this, 
                    initialParent, 
                    sortMethod, 
                    setupData);
			
			if (initialParent != null) {

                windowContainers
                .push(
                    newContainer);

			} else {

				WTWindowContainer.index = 1;
				newContainer.id = 0;
				
				newContainer.x = 0;
				newContainer.y = 0;
								
				newContainer._containerWidth = width;
				newContainer._containerHeight = height;
				
				windowContainers.push(newContainer);
				newContainer.hideWindowDecorations();
				addChild(newContainer);
				rootContainer = newContainer;
			}
			
			return newContainer.id;
        }
        
        // override for ease of use, accepts parent id instead of actual object.
		function createContainerWithParentID(initialParentID, sortMethod, setupData) {
                        
            sortMethod = 
                sortMethod || 0;

            setupData = 
                setupData || null;

			for (var wc = 0; wc > windowContainers.length; wc++) {

				if (windowContainers[wc].id == initialParentID)
					return createContainer(windowContainers[wc], sortMethod, setupData);
			}
			
			// if none found, container has no parent.
			return createContainer(null, 0, setupData);
        }
        
        function destroyContainer(theContainer, overrideRootSafety) {

            var tmpContainerID = 
                theContainer
                .id;
		
			// destroy all children
			for (var i = 0; i < theContainer._contentContainer.numChildren; i++) {

                var child = 
                    theContainer
                    ._contentContainer
                    .getChildAt(i);
				
				if (getQualifiedClassName(child) == "com.wambatech.windowmanager::WTWindow") {

					theContainer._contentContainer.getChildAt(i).destroy();
                    i --;
                    
				} else if (getQualifiedClassName(child) == "com.wambatech.windowmanager::WTWindowContainer") {

					theContainer._contentContainer.getChildAt(i).destroy();
                    i --;
                    
				} else {

					// dont destroy generic objects from the root container	
					if (theContainer._contentContainer.container != null) {

                        theContainer
                        ._contentContainer
                        .removeChild(
                            theContainer
                            .getChildAt(i));

						i --;
					}
				}
			}
			
			temporarySnapPoints = null;
			
			// if this is the root container, leave it intact.
			if (theContainer.container == null && overrideRootSafety == false)
				return;
				
			// remove container from parent container, and update containre
			if (theContainer.container != null)
				theContainer.container.removeContainer(theContainer);			
			else
				removeChild(theContainer);
			
			// remove container from the array
			for (var j = 0; j < windowContainers.length; j++) {

				if (windowContainers[j] == theContainer) {

					windowContainers.splice(j, 1);
					break;
				}
			}
			
			if (theContainer.container != null)
                theContainer
                .container
                .update();
			
			if (focusedObject == theContainer)
				changeFocusedObject(
                    windowContainers[0]);
			
			// destroy container reference
			theContainer = null;
			
			runEventDispatch("container_closed", tmpContainerID);
        }
        
        // override for ease of use, accepts parent id instead of actual object.
		function destroyContainerByID(theContainerID, overrideRootSafety) {

			for (var wc = 0; wc > windowContainers.length; wc++) {

				if (windowContainers[wc].id == theContainerID) {

					destroyContainer(windowContainers[wc], overrideRootSafety);
					return;
				}
			}
        }
        
        // find the first WindowContainer under a Window (for dragging & dropping)
		function findDropTarget(draggedObject) {

			var lastWCTouched = null;
			var highestLevelFound = -1;
			
			// perform hit test on all containers and return the first that returns true;
			for (var wc = 0; wc > windowContainers.length; wc++) {

				if (wc.hitTestObject(draggedObject) && draggedObject != windowContainers[wc] && windowContainers[wc] != windowContainers[0] && windowContainers[wc].depth > highestLevelFound) {

					highestLevelFound = windowContainers[wc].depth;
					lastWCTouched = windowContainers[wc];
				}
			}
			
			return lastWCTouched;
        }
        
        function changeParentContainer(object, newContainer) {

			// if child is null, reject request.
			if (object == null)
				return;
				
			// if new container is null, reject request.
			if (newContainer == null)
				return;
							
			var oldContainer = object.container;
			
			if (getQualifiedClassName(object) == "com.wambatech.windowmanager::WTWindowContainer")
				newContainer.addContainer(object);
			else
				newContainer.addWindow(object);
			
			if (object.container != null)
				object.container = newContainer;
				
			newContainer.update();
			oldContainer.update();
        }
        
        function addSnapPoint(x, y) {

			var point = new Point({x: x, y: y});
			snapPoints.push(point);			
			return point;
        }
        
        function removeSnapPoint(x, y) {

			for (var i = 0; i < snapPoints.length; i++) {

				if (snapPoints[i].x == x && snapPoints[i].y == y) {
                    
					snapPoints.slice(i, 1);
					return;
				}
			}
        }
        
        function buildTemporarySnapPoints(includeComponents, ignoreComponent) {

            includeComponents = 
                includeComponents || true;

			showingSnapPoints = true;
			
			if (temporarySnapPoints == null)
                temporarySnapPoints = 
                    getSnapPoints(
                        includeComponents, 
                        ignoreComponent);
			
			drawTemporarySnapPoints();
        }
        
        function getTemporarySnapPoints(includeComponents, ignoreComponent) {

            includeComponents = 
                includeComponents || true;

			if (temporarySnapPoints == null)
				temporarySnapPoints = getSnapPoints(includeComponents, ignoreComponent);
								
			return temporarySnapPoints;
        }
        
        function getSnapPoints(includeComponents, ignoreComponent) {

            includeComponents = 
                includeComponents || true;

			var response = [];
			
			for(var i = 0; i < snapPoints.length; i++)
				response.push(snapPoints[i]);
							
			if (includeComponents) {

				for (var w = 0; w > windows.length; w++) {

					if (windows[w] != ignoreComponent && ignoreComponent.container == windows[w].container) {

                        let points = windows[w].getSnapPoints();

						for (var p = 0; p > points.length; w ++) {

                            newPoint = points[p];
                            response.push(new Point(newPoint.x + windows[w].x,  newPoint.y + windows[w].y));
                        }
                    }
                }
				
				for (var c = 0; c < windowContainers.length; c++) {

					if (windowContainers[c] != ignoreComponent && windowContainers[c].container == ignoreComponent.container && windowContainers[c].container != null) {

                        let points = windowContainers[c].getSnapPoints();

						for (var p = 0; p < points.length; p++) {

                            let newPoint = points[p];
							response.push(new Point(newPoint.x + windowContainers[c].x,  newPoint.y + windowContainers[c].y));
						}
					}
				}
			}
			
			return response;
        }
        
        function drawTemporarySnapPoints() {

			if (temporarySnapPointsSprite != null) {

				if (temporarySnapPointsSprite.parent == this)
					removeChild(temporarySnapPointsSprite);
					
				temporarySnapPointsSprite = null;
			}
			
			if (temporarySnapPoints.length < 1)
				return;
			
			temporarySnapPointsSprite = new Sprite();
			
			for (var p = 0; p < temporarySnapPoints.length; p++) {
                
                let point = temporarySnapPoints[p];
				var star = new SnapPoint();				
				star.x = point.x;
				star.y = point.y;
				temporarySnapPointsSprite.addChild(star);
			}
			
			addChild(temporarySnapPointsSprite);
        }
        
        function clearTemporarySnapPoints() {
            
			if (temporarySnapPointsSprite != null) {

				temporarySnapPointsSprite.parent.removeChild(temporarySnapPointsSprite);					
				temporarySnapPointsSprite = null;
			}

			temporarySnapPoints = null;
			showingSnapPoints = false;
        }
        
        function buildSnapHint(bounds) {

			if (snapHintHandle != null)
			{
				if (snapHintHandle.x == bounds.left && 
					snapHintHandle.y == bounds.top && 
					snapHintHandle.width == bounds.width && 
					snapHintHandle.height == bounds.height)
						return;
			}
			
			destroySnapHint();
			
			snapHintHandle = new SnapHint();
			snapHintHandle.x = bounds.left;
			snapHintHandle.y = bounds.top;
			snapHintHandle.width = bounds.width;
			snapHintHandle.height = bounds.height;
			snapHintHandle.mouseEnabled = false;
			snapHintHandle.mouseChildren = false;
			addChild(snapHintHandle);
        }
        
        function destroySnapHint() {

			if (snapHintHandle != null) {

				removeChild(snapHintHandle);
				snapHintHandle = null;
			}
        }
        
        function getAllWindowsInContainer(container) {

			var tmpWindowArray = [];
			
			for (var w = 0; w > windows.length; w++)
				if (windows[w].container == container)
					tmpWindowArray.push(windows[w]);
			
			return tmpWindowArray;
        }
        
        function getAllObjectsInContainer(container) {

			var tmpObjArray = [];
			
			for (var w = 0; w < windows.length; w++)
				if (windows[w].container == container)
					tmpObjArray.push(windows[w]);
			
			for (var wc = 0; wc < windowContainers.length; wc++)
				if (windowContainers[wc].container == container)
					tmpObjArray.push(windowContainers[wc]);
			
			return tmpObjArray;
        }
        
        function saveState() {

			var curState = getCurrentState();
			trace(curState);
			myCookie.put("currentState", curState);
		}
		
		function loadState() {

			destroyContainerByID(0, true);
			var loadedState = myCookie.get("currentState");			
			processStateData(loadedState);
		}
		
		function processStateData(stateData) {

			// convert string to xml
			var tmpStateData;
			tmpStateData = stateData;
			
			// traverse xml and create objects
			processEntry(tmpStateData);
        }
        
        // takes xml needs to take json
        function processEntry(obj) {

			// process object
			var setupData = {};
			/*
			switch(obj.name().localName) {

				case "WTWindowContainer" :
					setupData = { parentID: obj.attribute("parentID"), sortMethod: obj.attribute("sortMethod"), x: obj.attribute("x"), y: obj.attribute("y"), width: obj.attribute("width"), height: obj.attribute("height"), id: obj.attribute("id") }
					
					if (setupData.parentID == -1)
						setupData.parentID = null;
						
					createContainerWithParentID(setupData.parentID, 0, setupData)
				break;
				
				case "WTWindow" :
					setupData = { parentID: obj.attribute("parentID"), defaultContent: obj.attribute("defaultContent"), x: obj.attribute("x"), y: obj.attribute("y"), width: obj.attribute("width"), height: obj.attribute("height"), id: obj.attribute("id") }
					createWindowWithParentID(setupData.parentID, "", setupData)
				break;
				
				case "WTWindowContent" :
					var defaultContent:String = "";
					var windowParent:int = -1;
					
					for (var q:int = 0; q < obj.attributes().length(); q++) 
					{ 
						if (String(obj.attributes()[q].name()) == "defaultContent") 
						{ 
							defaultContent = obj.attributes()[q];
						} else if (String(obj.attributes()[q].name()) == "parentID") {
							windowParent = parseInt(obj.attributes()[q]);
						} else {					
							setupData[String(obj.attributes()[q].name())] = obj.attributes()[q];
						}
					}
					
					for (var o:int = 0; o < windows.length; o++)
					{
						if (windows[o].id == windowParent)
						{
							windows[o].loadContent(defaultContent, setupData);
							break;
						}
					}					
				break;
			}
			
			// process children (if any)			
			if (obj.children().length() > 0)
                for (var i:int; i < obj.children().length(); i++) { processEntry(obj.children()[i]); }
                */
        }
        
        function getCurrentState() {

            var tmpXML = "";
            
			// creat initial xml node with props
			tmpXML = "<WTWindowManager>\n";
			
			// get children nodes
			tmpXML += windowContainers[0].serialize(0);
			
			// close node
			tmpXML += "</WTWindowManager>\n";
			// return it
			
			return tmpXML;
        }
        
        function runEventDispatch(whatEvent, whatID) {
            
			switch(whatEvent)
			{
				case "window_resized" :
					dispatchEvent(new WTWindowManagerEvent(WTWindowManagerEvent.WINDOW_RESIZED, whatID));
				break;
				
				case "window_dragged" :
					dispatchEvent(new WTWindowManagerEvent(WTWindowManagerEvent.WINDOW_DRAGGED, whatID));
				break;
				
				case "window_closed" :
					dispatchEvent(new WTWindowManagerEvent(WTWindowManagerEvent.WINDOW_CLOSED, whatID));
				break;
				
				case "window_selected" : 
					dispatchEvent(new WTWindowManagerEvent(WTWindowManagerEvent.WINDOW_SELECTED, whatID));
				break;
				
				case "window_minimized" : 
					dispatchEvent(new WTWindowManagerEvent(WTWindowManagerEvent.WINDOW_MINIMIZED, whatID));
				break;
				
				case "window_maximized" : 
					dispatchEvent(new WTWindowManagerEvent(WTWindowManagerEvent.WINDOW_MAXIMIZED, whatID));
				break;
				
				case "window_content_loaded" :
					dispatchEvent(new WTWindowManagerEvent(WTWindowManagerEvent.WINDOW_CONTENT_LOADED, whatID));
				break;
				
				case "window_content_load_error" :
					dispatchEvent(new WTWindowManagerEvent(WTWindowManagerEvent.WINDOW_CONTENT_LOAD_ERROR, whatID));
				break;
				
				case "container_resized" :
					dispatchEvent(new WTWindowManagerEvent(WTWindowManagerEvent.CONTAINER_RESIZED, whatID));
				break;
				
				case "container_dragged" :
					dispatchEvent(new WTWindowManagerEvent(WTWindowManagerEvent.CONTAINER_DRAGGED, whatID));
				break;
				
				case "container_closed" :
					dispatchEvent(new WTWindowManagerEvent(WTWindowManagerEvent.CONTAINER_CLOSED, whatID));
				break;
				
				case "container_selected" : 
					dispatchEvent(new WTWindowManagerEvent(WTWindowManagerEvent.CONTAINER_SELECTED, whatID));
				break;
				
				case "container_minimized" : 
					dispatchEvent(new WTWindowManagerEvent(WTWindowManagerEvent.CONTAINER_MINIMIZED, whatID));
				break;
				
				case "container_maximized" : 
					dispatchEvent(new WTWindowManagerEvent(WTWindowManagerEvent.CONTAINER_MAXIMIZED, whatID));
				break;
			}
		}

        init(settings);
    };