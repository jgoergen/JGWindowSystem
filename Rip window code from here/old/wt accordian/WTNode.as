///////////////////////////////////////////////////////////////////////////////////////
//
// WAMBATECH ACCORDIAN NODE
//
// VISUAL AND INTERACTIVE NODES WHICH MAKEUP THE ACCORDIAN CONTROL
//
// TODO:
//
// FUTURE FEATURES:
//		ADD SUPPORT FOR ICONS
//
///////////////////////////////////////////////////////////////////////////////////////

package
{
	import flash.display.MovieClip;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;	
	import fl.transitions.easing.*; 
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.geom.ColorTransform;
	
	public class WTNode extends MovieClip
	{
		public static var index:int = 0;
		
		public var parentNode:WTNode;
		public var id:int = 0;
		public var level:int = 0;
		public var _contentContainer:MovieClip;
		public var realHeight:Number = 29;
		public var active:Boolean = false;
		public var displayed:Boolean = false;
		public var collapsed:Boolean = false;
		public var children:int = 0;
		public var itemKey:Object;
		public var disposed:Boolean = false;
		public var loadingAnimationPlaying:Boolean = false; 
		
		private var _arrow:MovieClip;
		private var _titleText:TextField;
		private var _clickCatch:MovieClip;		
		private var _contentMask:MovieClip;
		private var _background:MovieClip;
		private var _loadingAnimation:MovieClip;
		private var xTween:Tween;
		private var yTween:Tween;
		private var maskTween:Tween;
		private var arrowTween:Tween;
		private var fadeTween:Tween;		
		private var title:String = "";
		private var manager:WTAccordian;
		private var showNodeWhenActive:Boolean = false;
		private var lateShowChildren:Boolean = false; 
		private var lateShowChildrenUpdateParent:Boolean = false;
		
		public function WTNode(theManager:WTAccordian, nodeLevel:int = 0, theTitle:String = "Default Title", theItemKey:Object = null, showWhenActive:Boolean = false)
		{
			id = index;			
			level = nodeLevel;
			title = theTitle;
			manager = theManager;
			itemKey = theItemKey;
			showNodeWhenActive = showWhenActive;
			
			index++;
			
			addEventListener(Event.ENTER_FRAME, initialize);
		}
	
		private function initialize(event:Event)
		{			
			removeEventListener(Event.ENTER_FRAME, initialize);
			gotoAndStop(level + 1);
						
			_arrow = getChildByName("arrow_mc") as MovieClip;
			_arrow.alpha = 0;
			
			_titleText = getChildByName("title_txt") as TextField;
			_titleText.text = title;
			
			_clickCatch = getChildByName("clickCatch_mc") as MovieClip;			
			_clickCatch.addEventListener(MouseEvent.CLICK, clickHandler);
			_clickCatch.buttonMode = true;
			_clickCatch.useHandCursor = true;
			
			_background = getChildByName("background_mc") as MovieClip;
			
			// color background according to to the 'level' of this node.
			//var testClipTransform:ColorTransform = new ColorTransform(0, 0, 0, 1, (level * 40), (level * 40), (level * 40), 0);
			//_background.transform.colorTransform = testClipTransform;
			
			_contentMask = getChildByName("contentMask_mc") as MovieClip;
			
			_contentContainer = getChildByName("contentContainer_mc") as MovieClip;
			
			_loadingAnimation = getChildByName("loadingAnimation_mc") as MovieClip;
			_loadingAnimation.alpha = 0;
			_loadingAnimation.gotoAndStop(1);
						
			if (manager.USE_ANIMATION)
				fadeTween = new Tween(this, "alpha", Strong.easeOut, 0, 1, manager.ANIMATION_SPEED, true);
				
			active = true;
			manager.reportReady(this);
			
			if (children > 0)
				_arrow.alpha = 1;
				
			if (parentNode == null)
			{
				displayed = true;
				manager._container.addChild(this);
				manager.updateNodePositions();
			}
			
			if (showNodeWhenActive)
			{
				if (parentNode != null)				
					parentNode.clickHandler(null, true);
			}
			
			if (loadingAnimationPlaying)
			{
				loadingAnimationPlaying = false;
			 	toggleLoadingAnimation();
			}
			
			if (lateShowChildren)
			{
				showChildren(lateShowChildrenUpdateParent);
				
				lateShowChildren = false;
				lateShowChildrenUpdateParent = false;				
			}
		}
		
		public function addNode(theNode:WTNode):void
		{			
			if (active)
				_arrow.alpha = 1;		
			
			children++;
			
			manager.nodes.push(theNode);
			theNode.parentNode = this;
			updateNodePositions();
		}
		
		public function updateNodePositions(updateParent:Boolean = true):void
		{													
			var childrenFound:int = 0;
			
			if (!active || manager.batching)
				return;
				
			var lastY:Number = 0;
			
			if (collapsed)
				lastY += 29;
			
			for each (var node:WTNode in manager.nodes)
			{				
				if (node.parentNode == this && node.active == true)
				{
					childrenFound ++;
					
					if (manager.NODE_INDENTION)
					{
						node.moveTo(new Point(((level + 1) * 5), lastY));
					} else {
						node.moveTo(new Point(node.x, lastY));
					}
					
					if (collapsed)
					{
						if (node.displayed == false)
							_contentContainer.addChild(node);
							
						node.displayed = true;
						lastY += node.realHeight;
					} else {						
						node.realHeight = 29;
						node.displayed = false;
						node.hideChildren(false);
					}
				}
			}
			
			if (collapsed)
			{
				realHeight = lastY;
			} else {
				realHeight = 29;
			}
			
			//_titleText.text = id + " kids " + childrenFound + " rh " + realHeight;
			
			if (manager.USE_ANIMATION)
			{
				if (maskTween != null)
					maskTween.stop();
				
				if (_contentMask.height != realHeight)
				{				
					maskTween = new Tween(_contentMask, "height", Strong.easeOut, _contentMask.height, realHeight, manager.ANIMATION_SPEED, true);
					maskTween.addEventListener(TweenEvent.MOTION_FINISH, doCleanup);
				}
			} else {
				_contentMask.height = realHeight;
				doCleanup();
			}
			
			if (parentNode != null)
			{
				if (updateParent)
					parentNode.updateNodePositions(updateParent);
			} else {
				if (updateParent)
					manager.updateNodePositions();
			}
		}
				
		public function moveTo(newPosition:Point):void
		{
			if (active == false)
				return;
			
			if (newPosition == null)
				return;
			
			if (x == newPosition.x && y == newPosition.y)
				return;
						
			if (manager.USE_ANIMATION)
			{				
				if (xTween != null)
					xTween.stop();
					
				if (yTween != null)
					yTween.stop();
			
				if (newPosition.x != x)
					xTween = new Tween(this, "x", Strong.easeOut, x, newPosition.x, manager.ANIMATION_SPEED, true);
					
				if (newPosition.y != y)
					yTween = new Tween(this, "y", Strong.easeOut, y, newPosition.y, manager.ANIMATION_SPEED, true);
				
			} else {
				x = newPosition.x;
				y = newPosition.y;
			}
		}
		
		public function clickHandler(event:MouseEvent, forceCollapse:Boolean = false):void
		{			
			if (children > 0 || forceCollapse == true)
			{
				if (collapsed)
				{
					hideChildren();				
				} else {					
					if (manager.SINGLE_PATH)
					{
						if (parentNode == null)
						{
							manager.closeAllOtherNodes(this);
						} else {
							parentNode.closeAllOtherNodes(this);
						}
					}
					
					showChildren();
				}
			} else {
				// there are no nodes under this one, report it as a clicked end point
				manager.itemClicked(this);
			}
		}
		
		public function showChildren(updateParent:Boolean = true):void
		{
			if (manager.batching)
			{
				// if were rejecting this request because the manager is in batch mode, save it for when batching is complete.
				manager.lateNodeToShow = this;
				return;
			}
			
			if (!active)
			{
				// if were rejecting this request because this node isnt active yet, save it for when it has become active.
				lateShowChildren = true;
				lateShowChildrenUpdateParent = updateParent;
				return;
			}
						
			if (updateParent && parentNode != null)
				parentNode.showChildren(true);
						
			if (collapsed == false)
			{								
				collapsed = true;
				
				if (arrowTween != null)
					arrowTween.stop();
					
				arrowTween = new Tween(_arrow, "rotation", Strong.easeOut, _arrow.rotation, 90, manager.ANIMATION_SPEED, true);
							
				updateNodePositions(updateParent);
			}
		}
		
		public function hideChildren(updateParent:Boolean = true):void
		{
			if (collapsed == false)
				return;
			
			collapsed = false;
			
			if (arrowTween != null)
				arrowTween.stop();
				
			arrowTween = new Tween(_arrow, "rotation", Strong.easeOut, _arrow.rotation, 0, manager.ANIMATION_SPEED, true);
			
			updateNodePositions(updateParent);			
			
		}
		
		private function doCleanup(event:Event = null):void
		{
			for (var i:int = 0; i < manager.nodes.length; i++)
			{				
				var node:WTNode = manager.nodes[i];
				
				if (node.parentNode != null)
				{
					if (node.parentNode.disposed == true)
						node.disposed = true;
					
					if (node.parentNode == this && node.active == true && node.displayed == false)
					{					
						if (manager.REMOVE_ON_HIDE)
						{
							children--;
							node.disposed = true;
						} else {
							_contentContainer.removeChild(node);
						}
					}
				}
			}
			
			if (children < 1)
				_arrow.alpha = 0;
			
			manager.cleanupDeadNodes();
			manager._scrollPane.update();
		}
		
		public function closeAllOtherNodes(theNode:WTNode):void
		{
			for each (var node:WTNode in manager.nodes)
			{
				if (node.parentNode == this && node != theNode && node.collapsed == true)
					node.hideChildren(false);
			}
		}
		
		public function toggleLoadingAnimation():void 
		{
			if (loadingAnimationPlaying)
			{
				loadingAnimationPlaying = false;
				
				if (!active)
					return;
					
				_loadingAnimation.alpha = 0;
				_loadingAnimation.gotoAndStop(1);
				
				if (children > 0)
					_arrow.alpha = 1;
				
			} else {
				loadingAnimationPlaying = true;
				
				if (!active)
					return;
					
				_loadingAnimation.alpha = 1;
				_loadingAnimation.play();
				_arrow.alpha = 0;
				
			}
		}
	}
}