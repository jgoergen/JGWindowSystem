package com.wambatech.components.linkpanel
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
		
	public class WTLinkPanel extends MovieClip
	{
		public static const ANIMATION_SPEED:Number = 0.5;
				
		private var _contentMask:WTContentMask;
		private var _contentContainer:WTContentContainer;
		private var _linkTitlePanel:WTLinkTitlePanel;		
		
		private var hideWaitTimer:Timer;
		
		public function WTLinkPanel()
		{
			addEventListener(Event.ENTER_FRAME, initialize);
		}
		
		public function initialize(event:Event):void
		{
			stop();
			removeEventListener(Event.ENTER_FRAME, initialize);
			
			_contentMask = getChildByName("contentMask_mc") as WTContentMask;
			_contentContainer = getChildByName("contentContainer_mc") as WTContentContainer;
			_linkTitlePanel = getChildByName("linkTitlePanel_mc") as WTLinkTitlePanel;
			
			_contentContainer.titleManager = this;			
			_linkTitlePanel.panelManager = this;
			
			hideWaitTimer = new Timer(100, 1);
			hideWaitTimer.addEventListener(TimerEvent.TIMER, finishHide);
		}
		
		public function cancelKill():void
		{
			hideWaitTimer.stop();
		}
		
		public function addLinkCategory(title:String, content:String):void
		{
			_linkTitlePanel.addLinkTitle(title, content);
		}
		
		public function showLinkCategory(link:WTLinkTitle):void
		{
			hideWaitTimer.stop();
			_contentMask.showMask();
			_contentContainer.loadContent(link.content);			
		}
		
		public function hideLinkCategories(link:WTLinkTitle):void
		{
			hideWaitTimer.start();			
		}
		
		private function finishHide(event:TimerEvent):void
		{
			_linkTitlePanel.unlockContent(null);
			_contentMask.hideMask();
		}
		
		public function killContent():void
		{
			_contentContainer.killContent();
		}
	}
}