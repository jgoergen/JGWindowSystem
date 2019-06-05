///////////////////////////////////////////////////////////////////////////////////////
//
// WAMBATECH WINDOW MANAGER
//
// CREATES & DESTROYS WINDOWS & CONTAINERS.
// FACILITATES CONTAINER SWAPPING
//
// TODO:
//		RECURSIVE STATE SAVING AND LOADING FOR CONTAINERS, WINDOWS, AND WINDOW CONTENT
//		XML DATA EXCHANGE FOR STATE SAVE / LOAD
//		AUTOMATICALLY MAKE 'ROOT' WINDOW CONTAINER FIT THE ENTIRE WINDOW MANAGER SIZE
//		HIDE WINDOW MANAGER GRAPHIC REPRESENTATION @ RUNTIME
//
///////////////////////////////////////////////////////////////////////////////////////

package
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.utils.getQualifiedClassName;
	import flash.geom.Point;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.events.KeyboardEvent;
	
	import Cookie;
	
	public class WTWindowManager extends MovieClip
	{
		public static var SNAP_TOLERANCE:Number = 10;
		public static var SNAP_TIME_ACTIVATE:Number = 500;
		public static var SNAP_TIME_ALLOW:Number = 500;
		public static var SNAP_TIME_CLEAR:Number = 1500;
		public static var SNAP_WAIT:Number = 0;
		public static var USE_SNAP_HINTING:Boolean = true;
		public static var USE_DRAG_SNAPPING:Boolean = true;
		public static var USE_RESIZE_SNAPPING:Boolean = true;
		public static var USE_WINDOW_ANIMATION:Boolean = true;
		public static var WINDOW_TWEEN_SPEED:Number = 0.5;
				
		public var snapHintHandle:MovieClip;
		public var showingSnapPoints:Boolean = false;		
		public var windowContainers:Array;
		public var focusedObject:Object;
		public var controlKeyDown:Boolean = false;
		
		private var windows:Array;
		private var snapPoints:Array;		
		private var temporarySnapPoints:Array;
		private var temporarySnapPointsSprite:Sprite;				
		
		var myCookie:Cookie;
		
		// Constructor
		public function WTWindowManager()
		{			
			windowContainers = new Array();
			windows = new Array();
			
			myCookie = new Cookie("WTWindowManagerTest");
			
			addEventListener(Event.ENTER_FRAME, initialize);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
		}
		
		// ensure flash is actually ready to go before kicking manager into gear.
		private function initialize(event:Event)
		{
			removeEventListener(Event.ENTER_FRAME, initialize);
			stop();
			
			// create a default container
			createContainer(null);
		}
		
		private function keyDownHandler(event:KeyboardEvent):void
		{
				controlKeyDown = event.ctrlKey;
		}
		
		private function keyUpHandler(event:KeyboardEvent):void
		{
				controlKeyDown = event.ctrlKey;
		}
		
		public function changeFocusedObject(newObj:Object):void
		{
			if (focusedObject != newObj)
			{
				focusedObject = newObj;
				
				if (getQualifiedClassName(newObj) == "WTWindowContainer")
					this.parent["updateContainerInfo"]();
			}
		}
		
		public function getContainerByID(whatID:int):WTWindowContainer
		{
			for each (var wc in windowContainers)
			{
				if (wc.id == whatID)
				{
					return wc;
				}
			}
			
			return null;
		}
		
		// create new window, attach it to default container if none is specified.
		public function createWindow(initialParent:WTWindowContainer, defaultContent:String = "", setupData:Object = null):int
		{
			// if no parent container has been provided, reject request
			if (initialParent == null)
				return 0;
			
			var newWindow:WTWindow = new WTWindow(this, initialParent, defaultContent, setupData);
			
			windows.push(newWindow);			
			return newWindow.id;
		}
		
		// override for ease of use, accepts parent id instead of actual object.
		public function createWindowWithParentID(initialParentID:int, defaultContent:String = "", setupData:Object = null):int
		{
			for each (var wc in windowContainers)
			{
				if (wc.id == initialParentID)
				{
					return createWindow(wc, defaultContent, setupData);
				}
			}
			
			return 0;
		}
		
		public function destroyWindow(theWindow:WTWindow):void
		{			
			// remove window from container, and update containre
			theWindow.container.removeWindow(theWindow);
			var tmpContainerRef:WTWindowContainer = theWindow.container;			
			
			// remove window from the array
			for (var i:int = 0; i < windows.length; i++)
			{
				if (windows[i] == theWindow)
				{
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
		}
		
		// override for ease of use, accepts window id instead of actual object.
		public function destroyWindowByID(theWindowID:int):void
		{
			for each (var w in windows)
			{
				if (w.id == theWindowID)
				{
					destroyWindow(w);
					return;
				}
			}
		}
				
		// create new window, attach it to default container if none is specified.
		public function createContainer(initialParent:WTWindowContainer, setupData:Object = null):int
		{					
			var newContainer:WTWindowContainer = new WTWindowContainer(this, initialParent, setupData);
			
			if (initialParent != null)
			{
				windowContainers.push(newContainer);
			} else {
				WTWindowContainer.index = 1;
				newContainer.id = 0;
				
				newContainer.x = 0;
				newContainer.y = 0;
								
				newContainer._containerWidth = width;
				newContainer._containerHeight = height;
				
				windowContainers.push(newContainer);
				addChild(newContainer);
			}
			
			return newContainer.id;
		}
		
		// override for ease of use, accepts parent id instead of actual object.
		public function createContainerWithParentID(initialParentID:int, setupData:Object = null):int
		{			
			for each (var wc in windowContainers)
			{
				if (wc.id == initialParentID)
				{
					return createContainer(wc, setupData);
				}
			}
			
			// if none found, container has no parent.
			return createContainer(null, setupData);
		}
		
		public function destroyContainer(theContainer:WTWindowContainer, overrideRootSafety:Boolean = false):void
		{			
			// destroy all children
			for (var i:int = 0; i < theContainer._contentContainer.numChildren; i++)
			{
				var child = theContainer._contentContainer.getChildAt(i);
				
				if (getQualifiedClassName(child) == "WTWindow")
				{
					(theContainer._contentContainer.getChildAt(i) as WTWindow).destroy();
					i --;
				} else if (getQualifiedClassName(child) == "WTWindowContainer") {
					(theContainer._contentContainer.getChildAt(i) as WTWindowContainer).destroy();
					i --;
				} else {
					// dont destroy generic objects from the root container	
					if (theContainer._contentContainer.container != null)
					{
						theContainer._contentContainer.removeChild(theContainer.getChildAt(i));
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
			{
				theContainer.container.removeContainer(theContainer);			
			} else {
				removeChild(theContainer);
			}
			
			// remove container from the array
			for (var j:int = 0; j < windowContainers.length; j++)
			{
				if (windowContainers[j] == theContainer)
				{
					windowContainers.splice(j, 1);
					break;
				}
			}
			
			if (theContainer.container != null)
				theContainer.container.update();
			
			if (focusedObject == theContainer)
				changeFocusedObject(windowContainers[0]);
			
			// destroy container reference
			theContainer = null;
		}
		
		// override for ease of use, accepts parent id instead of actual object.
		public function destroyContainerByID(theContainerID:int, overrideRootSafety:Boolean = false):void
		{
			for each (var wc in windowContainers)
			{
				if (wc.id == theContainerID)
				{
					destroyContainer(wc, overrideRootSafety);
					return;
				}
			}
		}
		
		// find the first WindowContainer under a Window (for dragging & dropping)
		public function findDropTarget(draggedWindow:WTWindow):WTWindowContainer
		{
			var lastWCTouched:WTWindowContainer = null;
			
			// perform hit test on all containers and return the first that returns true;
			for each (var wc in windowContainers)
			{
				if (wc.hitTestObject(draggedWindow))
				{
					lastWCTouched = wc;
				}
			}
			
			return lastWCTouched;
		}
		
		public function changeParentContainer(window:WTWindow, newContainer:WTWindowContainer):void
		{
			// if child is null, reject request.
			if (window == null)
				return;
				
			// if new container is null, reject request.
			if (newContainer == null)
				return;
			
			var oldContainer:WTWindowContainer = window.container;
			
			newContainer.addWindow(window);
			window.container = newContainer;
			newContainer.update();
			oldContainer.update();
		}
		
		public function addSnapPoint(x:Number, y:Number):Point
		{			
			var point:Point = new Point(x, y);			
			snapPoints.push(point);			
			return point;
		}
		
		public function removeSnapPoint(x:Number, y:Number):void
		{			
			for (var i:Number = 0; i < snapPoints.length; i++)
			{
				if (snapPoints[i].x == x && snapPoints[i].y == y)
				{
					snapPoints.slice(i, 1);
					return;
				}
			}
		}
		
		public function buildTemporarySnapPoints(includeComponents:Boolean = true, ignoreComponent:WTWindow = null):void
		{
			showingSnapPoints = true;
			
			if (temporarySnapPoints == null)
				temporarySnapPoints = getSnapPoints(includeComponents, ignoreComponent);
			
			drawTemporarySnapPoints();
		}
		
		public function getTemporarySnapPoints(includeComponents:Boolean = true, ignoreComponent:WTWindow = null):Array
		{
			if (temporarySnapPoints == null)
				temporarySnapPoints = getSnapPoints(includeComponents, ignoreComponent);
								
			return temporarySnapPoints;
		}
		
		public function getSnapPoints(includeComponents:Boolean = true, ignoreComponent:WTWindow = null):Array
		{
			var response:Array = new Array();
			
			for each(var point:Point in snapPoints)
				response.push(point);
							
			if (includeComponents)
			{
				for each (var w in windows)
				{					
					if (w != ignoreComponent && ignoreComponent.container == w.container)
					{
						for each(var newPoint:Point in w.getSnapPoints())
						{
							response.push(new Point(newPoint.x + w.x,  newPoint.y + w.y));
						}
					}
				}
			}
			
			return response;
		}
		
		public function drawTemporarySnapPoints():void
		{			
			if (temporarySnapPointsSprite != null)
			{
				if (temporarySnapPointsSprite.parent == this)
					removeChild(temporarySnapPointsSprite);
					
				temporarySnapPointsSprite = null;
			}
			
			if (temporarySnapPoints.length < 1)
				return;
			
			temporarySnapPointsSprite = new Sprite();
			
			for each(var point:Point in temporarySnapPoints)
			{				
				var star:SnapPoint = new SnapPoint();				
				star.x = point.x;
				star.y = point.y;
				temporarySnapPointsSprite.addChild(star);
			}
			
			addChild(temporarySnapPointsSprite);
		}
		
		public function clearTemporarySnapPoints():void
		{
			if (temporarySnapPointsSprite != null)
			{
				if (temporarySnapPointsSprite.parent == this)
					removeChild(temporarySnapPointsSprite);
					
				temporarySnapPointsSprite = null;
			}

			temporarySnapPoints = null;
			showingSnapPoints = false;
		}
		
		public function buildSnapHint(bounds:Rectangle):void
		{
			if (snapHintHandle != null)
			{
				if (snapHintHandle.x == bounds.left && 
					snapHintHandle.y == bounds.top && 
					snapHintHandle.width == bounds.width && 
					snapHintHandle.height == bounds.height)
						return;
			}
			
			destroySnapHint();
			
			snapHintHandle = new SnapHint() as MovieClip;
			snapHintHandle.x = bounds.left;
			snapHintHandle.y = bounds.top;
			snapHintHandle.width = bounds.width;
			snapHintHandle.height = bounds.height;
			snapHintHandle.mouseEnabled = false;
			snapHintHandle.mouseChildren = false;
			addChild(snapHintHandle);
		}
		
		public function destroySnapHint():void
		{
			if (snapHintHandle != null)
			{
				removeChild(snapHintHandle);
				snapHintHandle = null;
			}
		}
		
		public function getAllWindowsInContainer(container:WTWindowContainer):Array
		{
			var tmpWindowArray:Array = new Array();
			
			for each(var window:WTWindow in windows)
			{				
				if (window.container == container)
					tmpWindowArray.push(window);
			}
			
			return tmpWindowArray;
		}
		
		public function getAllObjectsInContainer(container:WTWindowContainer):Array
		{
			var tmpObjArray:Array = new Array();
			
			for each(var theWindow:WTWindow in windows)
			{				
				if (theWindow.container == container)
					tmpObjArray.push(theWindow);
			}
			
			for each(var theContainer:WTWindowContainer in windowContainers)
			{				
				if (theContainer.container == container)
					tmpObjArray.push(theContainer);
			}
			
			return tmpObjArray;
		}
		
		public function saveState():void
		{
			var curState:String = getCurrentState();
			trace(curState);
			myCookie.put("currentState", curState);
		}
		
		public function loadState():void
		{
			destroyContainerByID(0, true);
			var loadedState:String = myCookie.get("currentState") as String;			
			processStateData(loadedState);
		}
		
		private function processStateData(stateData:String):void
		{
			// convert string to xml
			var tmpStateData:XML;
			tmpStateData = new XML(stateData);
			
			// traverse xml and create objects
			processEntry(tmpStateData);
		}
		
		private function processEntry(obj:XML):void
		{
			// process object
			var setupData:Object = new Object();
			
			switch(obj.name().localName)
			{
				case "WTWindowContainer" :
					setupData = { parentID: obj.attribute("parentID"), sortMethod: obj.attribute("sortMethod"), x: obj.attribute("x"), y: obj.attribute("y"), width: obj.attribute("width"), height: obj.attribute("height"), id: obj.attribute("id") }
					
					if (setupData.parentID == -1)
						setupData.parentID = null;
						
					createContainerWithParentID(setupData.parentID, setupData)
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
		}
		
		private function getCurrentState():String
		{
			var tmpXML:String = "";
			// creat initial xml node with props
			tmpXML = "<WTWindowManager>\n";
			
			// get children nodes
			tmpXML += windowContainers[0].serialize(0);
			
			// close node
			tmpXML += "</WTWindowManager>\n";
			// return it
			
			return tmpXML;
		}
	}
}