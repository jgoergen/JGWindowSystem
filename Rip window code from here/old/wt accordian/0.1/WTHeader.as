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
	
	public class WTHeader extends MovieClip
	{
		public static var index:int = 0;
		
		public var parentHeader:WTHeader;
		public var id:int = 0;
		public var level:int = 0;
		public var _contentContainer:MovieClip;
		public var realHeight:Number = 29;
		public var active:Boolean = false;
		public var displayed:Boolean = false;
		public var collapsed:Boolean = false;
		public var children:int = 0;
		public var itemKey:Object;
		
		private var _arrow:MovieClip;
		private var _titleText:TextField;
		private var _clickCatch:MovieClip;		
		private var _contentMask:MovieClip;
		private var _background:MovieClip;
		private var xTween:Tween;
		private var yTween:Tween;
		private var maskTween:Tween;
		private var arrowTween:Tween;
		private var fadeTween:Tween;		
		private var title:String = "";
		private var manager:WTAccordian;		
		
		public function WTHeader(theManager:WTAccordian, nodeLevel:int = 0, theTitle:String = "Default Title", theItemKey:Object = null)
		{						
			id = index;			
			level = nodeLevel;
			title = theTitle;
			manager = theManager;
			itemKey = theItemKey;
			
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
			
			if (parentHeader == null)
			{
				displayed = true;
				manager._container.addChild(this);
				manager.updateHeaderPositions();
			}
			
			if (manager.USE_ANIMATION)
				fadeTween = new Tween(this, "alpha", Strong.easeOut, 0, 1, manager.ANIMATION_SPEED, true);
				
			active = true;
			manager.reportReady(this);
			
			if (children > 0)
				_arrow.alpha = 1;
		}
		
		public function addHeader(theHeader:WTHeader):void
		{			
			if (active)
				_arrow.alpha = 1;
		
			children++;
			manager.headers.push(theHeader);
			theHeader.parentHeader = this;
			updateHeaderPositions();
		}
		
		public function updateHeaderPositions(updateParent:Boolean = true):void
		{										
			var childrenFound:int = 0;
			
			if (!active || manager.batching)
				return;
				
			var lastY:Number = 0;
			
			if (collapsed)
				lastY += 29;
			
			for each (var header:WTHeader in manager.headers)
			{				
				if (header.parentHeader == this && header.active == true)
				{
					childrenFound ++;
					
					if (manager.NODE_INDENTION)
					{
						header.moveTo(new Point(((level + 1) * 5), lastY));
					} else {
						header.moveTo(new Point(header.x, lastY));
					}
					
					if (collapsed)
					{
						if (header.displayed == false)
							_contentContainer.addChild(header);
							
						header.displayed = true;
						lastY += Math.floor(header.realHeight);
					} else {						
						header.displayed = false;
						header.hideChildren(false);
					}
				}
			}
			
			if (collapsed)
			{
				realHeight = lastY;
			} else {
				realHeight = 29;
			}
			
			if (childrenFound == 0)
				return;
			
			if (manager.USE_ANIMATION)
			{
				if (maskTween != null)
					maskTween.stop();
				
				maskTween = new Tween(_contentMask, "height", Strong.easeOut, _contentMask.height, realHeight, manager.ANIMATION_SPEED, true);
				maskTween.addEventListener(TweenEvent.MOTION_FINISH, doCleanup);
			} else {
				_contentMask.height = realHeight;
				doCleanup();
			}
			
			if (parentHeader != null && updateParent)
			{
				parentHeader.updateHeaderPositions();
			} else {
				manager.updateHeaderPositions();
			}
		}
				
		public function moveTo(newPosition:Point):void
		{
			if (newPosition == null)
				return;
			
			if (x == newPosition.x && y == newPosition.y)
				return;
			
			if (manager.USE_ANIMATION)
			{
				// stop & null any tweens that might be active already				
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
		
		public function clickHandler(event:MouseEvent):void
		{
			if (children > 0)
			{
				if (collapsed)
				{
					hideChildren();				
				} else {
					showChildren();
					
					if (manager.SINGLE_PATH)
					{
						if (parentHeader == null)
						{
							manager.closeAllOtherHeaders(this);
						} else {
							parentHeader.closeAllOtherHeaders(this);
						}
					}
				}
			} else {
				// there are no nodes under this one, report it as a clicked end point
				manager.itemClicked(itemKey);
			}
		}
		
		public function showChildren(updateParent:Boolean = true):void
		{
			if (collapsed == true)
				return;
			
			collapsed = true;
			
			if (arrowTween != null)
				arrowTween.stop();
				
			arrowTween = new Tween(_arrow, "rotation", Strong.easeOut, _arrow.rotation, 90, manager.ANIMATION_SPEED, true);
			
			updateHeaderPositions(updateParent);
		}
		
		public function hideChildren(updateParent:Boolean = true):void
		{
			if (collapsed == false)
				return;
			
			collapsed = false;
			
			if (arrowTween != null)
				arrowTween.stop();
				
			arrowTween = new Tween(_arrow, "rotation", Strong.easeOut, _arrow.rotation, 0, manager.ANIMATION_SPEED, true);
			
			updateHeaderPositions(updateParent);			
			
		}
		
		private function doCleanup(event:Event = null):void
		{
			for each (var header:WTHeader in manager.headers)
			{				
				if (header.parentHeader == this && header.active == true && header.displayed == false && header.parent != null)
					_contentContainer.removeChild(header);
			}
			
			manager._scrollPane.update();
		}
		
		public function closeAllOtherHeaders(theHeader:WTHeader):void
		{
			for each (var header:WTHeader in manager.headers)
			{
				if (header.parentHeader == this && header != theHeader && header.collapsed == true)
					header.hideChildren(true);
			}
		}
	}
}