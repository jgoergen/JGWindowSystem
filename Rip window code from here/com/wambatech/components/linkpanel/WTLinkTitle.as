package com.wambatech.components.linkpanel
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	public class WTLinkTitle extends MovieClip
	{
		private static var index:int = 0;
		
		public var titleManager:WTLinkTitlePanel;
		public var id:int;
		public var content:String = "";
		
		private var lockState:Boolean = false;
		private var title:String = "";
		private var _mouseCatch:MovieClip;
		
		
		public function WTLinkTitle(theTitle:String, theTitleManager:WTLinkTitlePanel, theContent:String)
		{			
			title = theTitle;
			titleManager = theTitleManager;
			id = index;
			content = theContent;
			
			index ++;
			
			addEventListener(Event.ENTER_FRAME, initialize);
		}
		
		public function initialize(event:Event):void
		{
			gotoAndStop(1);
			removeEventListener(Event.ENTER_FRAME, initialize);
			
			// ghetto, on actual instantiation this should be setup by its manager.
			
			(getChildByName("title_txt") as TextField).text = title;
			
			_mouseCatch = getChildByName("mouseCatch_mc") as MovieClip;
			
			_mouseCatch.addEventListener(MouseEvent.MOUSE_OVER, showHighLightState);
			_mouseCatch.addEventListener(MouseEvent.MOUSE_OUT, showNormalState);
			_mouseCatch.addEventListener(MouseEvent.MOUSE_DOWN, showClickedState);
			
			titleManager.addChild(this);
			titleManager.update();
		}
		
		public function showHighLightState(event:MouseEvent = null):void
		{
			if (!lockState)
			{
				titleManager.linkMouseOver(this);
				gotoAndStop(2);
			}
		}
		
		public function showNormalState(event:MouseEvent = null):void
		{
			if (!lockState)
			{
				titleManager.linkMouseOut(this);
				gotoAndStop(1);
			}
		}
		
		public function showClickedState(event:MouseEvent = null):void
		{
			if (lockState == false)
			{
				lockState = true;
				titleManager.lockContent(this);
				gotoAndStop(3);
			} else {
				lockState = false;
				titleManager.unlockContent(this);
				gotoAndStop(2);
			}
		}
		
		public function forceStateUnlock():void
		{
			lockState = false;
			gotoAndStop(1);
		}
	}
}