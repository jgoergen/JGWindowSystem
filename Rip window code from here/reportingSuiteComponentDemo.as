///////////////////////////////////////////////////////////////////////////////////////
//
// WAMBATECH REPORTING SUITE TECH DEMO
//
// DEMONSTRATES HOW TO USE EACH OF THE NEW WT COMPONENTS AND HOW THEY WORK TOGETHER
//
// TODO:
//		procedurally add items to list panel instead of ghetto movieclip ref. (accepts an item key)
//			add custom even for when items are clicked, returns an itemkey
//		(alerting class (call alert, give a message and x y))
//		(input box like alert)
//		(properties dialogue facility)
//
// FUTURE FEATURES:
//
///////////////////////////////////////////////////////////////////////////////////////

package
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	
	import com.wambatech.components.accordian.WTNodeEvent;
	import com.wambatech.windowmanager.WTWindowManagerEvent;
	import com.wambatech.dragdrop.DragDropManager;
	
	public class reportingSuiteComponentDemo extends MovieClip
	{
		private var _linkPanel:WTLinkPanel;
		private var _accordian:WTAccordian;
		private var _windowManager:WTWindowManager;
		
		public function reportingSuiteComponentDemo()
		{
			addEventListener(Event.ENTER_FRAME, initialize);
		}
		
		private function initialize(event:Event)
		{
			removeEventListener(Event.ENTER_FRAME, initialize);
			stop();
			
			_linkPanel = getChildByName("linkPanel_mc") as WTLinkPanel;
			_accordian = getChildByName("accordian_mc") as WTAccordian;
			_windowManager = getChildByName("windowManager_mc") as WTWindowManager;
			
			if (_linkPanel != null)
				setupLinkPanel();
			
			if (_accordian != null)
				setupAccordian();
				 
			if (_windowManager != null)
				setupWindowManager();
				
		}
		
		private function setupLinkPanel():void
		{
			_linkPanel.addLinkCategory("Content", "content1");
			_linkPanel.addLinkCategory("Containers", "content2");
		}
		
		private function setupAccordian():void
		{
			// THIS EXAMPLE FILLS OUT A LARGE ACCORDIAN SETUP USING BATCH MODE.
			// ON CLICK OF A NODE WITH AN ARROW ON THE SIDE, IT WILL DROP TO REVEAL ITS CHILD NODES
			// ON CLICK OF A CHILD NODE WITHOUT AN ARROW (AN ITEM AS OPPOSED TO A FOLDER) WE ARE NOTIFIED
			// AND WE AUTOMATICALLY ADD 5 CHILDREN TO THAT ITEM AND SHOW THEM.
			// WE ARE ALSO USING 'REMOVE_ON_HIDE' TO DEMONSTRATE RESOURCE DESTRUCTION WHEN HIDING A NODES CHILDREN
			// THIS IS USEFULL IN SCENERIOS WHERE YOU WANT TO ONLY POPULATE A NODE WHEN ITS CLICKED, AND DESTROY
			// ITS CONTENTS WHEN THEIR HIDDEN (FOR EXTREMELY LIGHT RESOURCE USAGE)
			
			var newNodeIndex:int = 0;
			
			// begin batch mode
			// BATCH MODE DIRECTS THE ACCORDIAN CONTROL TO STOP RUNNING ANY VISUAL OR SORTING METHODS
			// WHICH GREATLY IMPROVES PREFORMANCE ON A ONE TIME DROP OF MANY FEILDS.
			_accordian.beginBatch();
			
			// PUBLIC PROPERTIES OF THE ACCORDIAN INCLUDE
			//			(BOOLEAN) USE_ANIMATION, WHICH WILL DISABLE ANY TWEENED ANIMATION (DEFAULT: TRUE)
			//			(NUMBER) ANIMATION_SPEED, WHICH IS THE NUMBER OF SECONDS EACH ANIMATION SHOULD TAKE (DEFAULT: 0.5)
			//			(BOOLEAN) NODE_INDENTION, WHICH IS WHETHER OR NOT THE CHILDREN NODES SHOULD INDENT TO THE RIGHT (DEFAULT: FALSE)
			//			(BOOLEAN) SINGLE_PATH, WHICH IS WHETHER OR NOT A USER IS LIMITED TO ONE PATH PER NODE (DEFAULT: TRUE)
			//			(BOOLEAN) REMOVE_ON_HIDE, WHICH INSTRUCTS NODES TO DESTROY ALL CHILDREN WHEN YOU HIDE THEM. (DEFAULT: FALSE)
			
			_accordian.REMOVE_ON_HIDE = true;
			
			// add 10 base nodes
			for (var i:int = 0; i < 5; i++)
			{
				// 'addNodeById' PAREMETERS ARE
				//			(INT) PARENT ID (0 BEING ROOT)
				//			(STRING) NODE TITLE (WHICH IS DISPLAYED ON THE NODE)
				//			(OBJECT) THE NODE 'KEY' WHICH CAN BE ANYTHING OBJECT YOU LIKE
				//			(BOOLEAN)(OPTIONAL AND NOT IGNORED DURING BATCH MODE) AUTOMATICALLY SHOW NODE WHEN READY.
				_accordian.addNodeById(0, "Item " + i, "main item " + i);
			}
						
			// add 10 nodes to each base node
			for (var o:int = 1; o <= 5; o++)
			{
				for (var p:int = 0; p < 5; p++)
				{
					_accordian.addNodeById(o, "Sub Item " + p, "sub item " + p);
				}
			}
						
			// add 1000 nodes randomly
			for (var j:int = 0; j < 1000; j++)
			{
				_accordian.addNodeById(Math.ceil(Math.random() * (_accordian.entries - 1)), "Random Sub Item " + j, "random item " + j);
			}
									
			// WHENEVER YOU BEGIN BATCH MODE YOU MUST USE 'endBatch' TO CLEANUP THE ENTRIES THAT WERE ADDED DURING THE BATCH PERIOD
			_accordian.endBatch();
			
			// AN EVENT IS PROVIDED FOR WHEN A CHILDLESS NODE IS SELECTED
			_accordian.addEventListener(WTNodeEvent.SELECTED, selectedHandler);
			
			function selectedHandler(event:WTNodeEvent):void
			{
				trace("Node selected " + event.itemKey);
				
				// BEFORE WE ADD NODES TO THIS OBJECT WE FIRST START ITS LOADING ANIMATION
				_accordian.toggleLoadingAnimationByKey(event.itemKey);
				
				// 'addNodeByKey' DEMONSTRATES HOW TO ADD A NODE TO ANOTHER NODE BY ITS KEY REFRENCE (WHICH CAN BE ANY OBJECT YOU CHOOSE)
				// ALSO NOTE THAT WERE USING AN EXTRA PARAMETER IN THIS ADD NODE FUNCTION (THE FINAL 'true') WHICH DIRECTS THE SYSTEM
				// TO AUTOMATICALLY SHOW THE NEW NODE (WHICH WILL OVERRIDE ANYTHING CURRENTLY BEING VIEWED)
				for (var l:int = 0; l < 5; l++)
				{
					var showNode:Boolean = false;
					
					// WHEN ADDING MORE THAN 1 NODE ALL OF WHICH YOU WANT TO AUTOMATICALLY SHOW, ONLY FLAG THE LAST NODE ADDED.
					// THIS OFCOURSE REQUIRES THAT ALL OF THESE NEW NODES BELONG TO THE SAME PARENT.
					if (l == 4)
						showNode = true;
						
					_accordian.addNodeByKey(event.itemKey, "new node " + newNodeIndex, "new node " + newNodeIndex, showNode);
					newNodeIndex ++;
				}
				
				// DONT FORGET TO STOP THE LOADING ANIMATION WHEN FINISHED
				_accordian.toggleLoadingAnimationByKey(event.itemKey);
			}
			
			// AUTOMATICALLY POP OPEN THE 500TH RANDOM NODE WE ADDED
			_accordian.showNodeByKey("random item 500");
		}
		
		public function dataDropped(theData:String, droppedPos:Point):void
		{			
			var setupData:Object = {x: droppedPos.x, y: droppedPos.y};
			
			switch(theData)
			{
				case "addContainer1_mc":
					_windowManager.createContainerWithParentID(0, 0, setupData);
				break;
				
				case "addContainer2_mc":
					_windowManager.createContainerWithParentID(0, 1, setupData);
				break;
				
				case "addContainer3_mc":
					_windowManager.createContainerWithParentID(0, 2, setupData);
				break;
				
				case "addContent1_mc":
					_windowManager.createWindowWithParentID(0, "testContent.swf", setupData);
				break;
				
				case "addContent2_mc":
					_windowManager.createWindowWithParentID(0, "testContent 2.swf", setupData);
				break;
				
				case "addContent3_mc":
					_windowManager.createWindowWithParentID(0, "testContent 3.swf", setupData);
				break;
			}
		}
		
		private function setupWindowManager():void
		{
			DragDropManager.registerDropObject(_windowManager.rootContainer, "windowManager", dataDropped);
			
			_windowManager.addEventListener(WTWindowManagerEvent.WINDOW_SELECTED, windowSelectedHandler);
			_windowManager.addEventListener(WTWindowManagerEvent.WINDOW_CONTENT_LOAD_ERROR, windowContentLoadError);
		}
		
		public function addExternalTextContent():void
		{
			_windowManager.createWindowWithParentID(0, "testContent.swf");
		}
		
		public function addExternalTextContent2():void
		{
			_windowManager.createWindowWithParentID(0, "testContent 2.swf");
		}
				
		public function addContainer():void
		{
			_windowManager.createContainerWithParentID(0);
		}
		
		public function addContainer2():void
		{
			_windowManager.createContainerWithParentID(0, 1);
		}
		
		public function addContainer3():void
		{
			_windowManager.createContainerWithParentID(0, 2);
		}
		
		private function windowSelectedHandler(event:WTWindowManagerEvent):void
		{
			trace("Window " + event.objectID + " has focus");
		}
		
		private function windowContentLoadError(event:WTWindowManagerEvent):void
		{
			trace("Window " + event.objectID + " had an io error loading its content and was closed.");
		}
	}
}