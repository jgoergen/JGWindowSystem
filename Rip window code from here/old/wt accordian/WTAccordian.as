///////////////////////////////////////////////////////////////////////////////////////
//
// WAMBATECH ACCORDIAN CONTROL
//
// AN ACCORDIAN STYLE DATA BROWSER
//
// TODO:
//
// FUTURE FEATURES:
//
///////////////////////////////////////////////////////////////////////////////////////

package
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.utils.getTimer;
	import fl.containers.ScrollPane;
	import flash.events.EventDispatcher;
	
	public class WTAccordian extends MovieClip
	{
		public var USE_ANIMATION:Boolean = true;
		public var ANIMATION_SPEED:Number = .5;
		public var NODE_INDENTION:Boolean = false;
		public var SINGLE_PATH:Boolean = true;
		public var REMOVE_ON_HIDE:Boolean = false;
		
		public var nodes:Array;
		public var batching:Boolean = false;		
		public var _scrollPane:ScrollPane;
		public var _container:Sprite;		
		public var lateNodeToShow:WTNode;
		
		private var batchSpawned:int = 0;
		private var batchReady:int = 0;
		private var batchBegin:Number = 0;
		
		public function WTAccordian()
		{
			nodes = new Array();
			
			addEventListener(Event.ENTER_FRAME, initialize);
		}
		
		private function initialize(event:Event)
		{
			removeEventListener(Event.ENTER_FRAME, initialize);
			stop();
			
			_scrollPane = getChildByName("scrollPane_sp") as ScrollPane;
			_scrollPane.setSize(width, height);
			
			_container = new Sprite();
			this.addChild(_container);

			_scrollPane.source = _container;
		}
		
		public function reportReady(node:WTNode):void { batchReady ++; }
		
		public function beginBatch():void
		{
			batchBegin = getTimer();
			batching = true;
		}
		
		public function endBatch():void
		{
			addEventListener(Event.ENTER_FRAME, waitForBatchComplete);
		}
		
		public function waitForBatchComplete(event:Event):void
		{
			if (batchSpawned > batchReady)
				return;
				
			removeEventListener(Event.ENTER_FRAME, waitForBatchComplete);
			
			batching = false;
			
			trace(batchSpawned + " nodes added in " + (getTimer() - batchBegin) + " milliseconds.");
			batchSpawned = 0;
			
			if (lateNodeToShow != null)
			{
				showNode(lateNodeToShow);
				lateNodeToShow = null;
			}
		}
		
		public function addNode(parentNode:WTNode, theTitle:String, theItemKey:Object = null, showWhenActive:Boolean = false):void
		{
			if (batching)
			{
				showWhenActive = false;
				batchSpawned++;
			}
			
			var newNode:WTNode;
			
			if (parentNode == null)
			{
				// root level node
				newNode = new WTNode(this, 0, theTitle, theItemKey, showWhenActive);
				nodes.push(newNode);
			} else {
				newNode = new WTNode(this, (parentNode.level + 1), theTitle, theItemKey, showWhenActive);				
				parentNode.addNode(newNode);
			}
		}
		
		public function addNodeById(parentID:int, theTitle:String, theItemKey:Object = null, showWhenActive:Boolean = false):void
		{
			if (parentID == 0)
			{
				addNode(null, theTitle, theItemKey);
			} else {
				addNode(nodes[parentID - 1], theTitle, theItemKey, showWhenActive);
			}
		}
		
		public function addNodeByKey(parentItemkey:Object, theTitle:String, theItemKey:Object = null, showWhenActive:Boolean = false):void
		{
			for each (var node:WTNode in nodes)
			{
				if (node.itemKey == parentItemkey)
				{
					addNode(node, theTitle, theItemKey, showWhenActive);
					return;
				}
			}
		}
		
		public function showNode(theNode:WTNode):void
		{
			theNode.showChildren(true);
		}
		
		public function showNodeById(nodeID:int):void
		{			
			showNode(nodes[nodeID - 1]);
		}
		
		public function showNodeByKey(nodeItemKey:Object):void
		{
			for each (var node:WTNode in nodes)
			{
				if (node.itemKey == nodeItemKey)
				{
					showNode(node);
					return;
				}
			}
		}
		
		public function toggleLoadingAnimation(theNode:WTNode):void
		{
			theNode.toggleLoadingAnimation();
		}
		
		public function toggleLoadingAnimationById(nodeID:int):void
		{			
			toggleLoadingAnimation(nodes[nodeID - 1]);
		}
		
		public function toggleLoadingAnimationByKey(nodeItemKey:Object):void
		{
			for each (var node:WTNode in nodes)
			{
				if (node.itemKey == nodeItemKey)
				{
					toggleLoadingAnimation(node);
					return;
				}
			}
		}
		
		public function updateNodePositions():void
		{
			var lastY:Number = 0;
			
			for each (var node:WTNode in nodes)
			{
				if (node.parentNode == null)
				{
					node.moveTo(new Point(node.x, lastY));
					
					lastY += node.realHeight;
				}
			}
		}
		
		public function closeAllOtherNodes(theNode:WTNode):void
		{
			for each (var node:WTNode in nodes)
			{
				if (node.parentNode == null && node != theNode && node.collapsed == true)
					node.hideChildren(true);
			}
		}
		
		public function get entries():int
		{
			return nodes.length;
		}
		
		public function itemClicked(nodeClicked:WTNode):void
		{
			dispatchEvent(new WTNodeEvent(WTNodeEvent.SELECTED, nodeClicked.itemKey));
		}
		
		public function cleanupDeadNodes():void
		{
			for (var i:int = 0; i < nodes.length; i++)
			{				
				var node:WTNode = nodes[i];
				
				if (node.disposed == true)
				{
					node = null;
					nodes.splice(i,1);
					i--;
				}
			}
		}
	}
}