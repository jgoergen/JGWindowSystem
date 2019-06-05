package com.wambatech.components.linkpanel
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	public class WTLinkTitlePanel extends MovieClip
	{
		public var panelManager:WTLinkPanel;
		
		private var contentLocked:Boolean = false;
		private var linkTitles:Array;
		private var align:int = 0; // 0 == left, 1 == right
				
		public function WTLinkTitlePanel()
		{
			linkTitles = new Array();
			
			addEventListener(Event.ENTER_FRAME, initialize);
		}
		
		public function initialize(event:Event):void
		{
			stop();
			removeEventListener(Event.ENTER_FRAME, initialize);
			
			addEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
			addEventListener(MouseEvent.ROLL_OUT, rollOutHandler);			
		}
		
		private function rollOverHandler(event:MouseEvent):void
		{			
			panelManager.cancelKill();
		}
		
		private function rollOutHandler(event:MouseEvent):void
		{
			panelManager.hideLinkCategories(null);
		}
		
		public function addLinkTitle(title:String, content:String):void
		{
			var newLinkTitle = new WTLinkTitle(title, this, content);
			linkTitles.push(newLinkTitle);
		}
		
		public function update():void
		{
			// setup all the linktitles in order with ordering applied
			/*
				left start 	x: 3.35 y: 2.85
				right start 	x: 294.4 y: 2.85
			*/
			var index:int = 0;
			
			var leftPadding:Number = 3.35;
			var topPadding:Number = 2.85;
			var overlapAmount:Number = 2;			
			
			if (align == 0)
			{
				for each (var linkTitle:WTLinkTitle in linkTitles)
				{
					linkTitle.y = topPadding;
					linkTitle.x = (leftPadding + (linkTitle.width * index));
					
					if (index > 0)
						linkTitle.x -= overlapAmount * index;
					
					index ++;
				}
			}
			
		}
		
		public function linkMouseOver(link:WTLinkTitle):void
		{
			if (!contentLocked)
				panelManager.showLinkCategory(link);
		}
		
		public function linkMouseOut(link:WTLinkTitle):void
		{
			if (!contentLocked)
				panelManager.hideLinkCategories(link);
		}
		
		public function lockContent(link:WTLinkTitle):void
		{
			contentLocked = true;
			panelManager.showLinkCategory(link);
			
			for each (var linkTitle:WTLinkTitle in linkTitles)
			{
				if (linkTitle != link)
					linkTitle.forceStateUnlock();
			}
		}
		
		public function unlockContent(link:WTLinkTitle):void
		{
			contentLocked = false;
			
			for each (var linkTitle:WTLinkTitle in linkTitles)
			{
				if (linkTitle != link)
					linkTitle.forceStateUnlock();
			}
		}
	}
}