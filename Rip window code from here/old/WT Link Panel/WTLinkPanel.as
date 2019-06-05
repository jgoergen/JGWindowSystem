package
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
		
	public class WTLinkPanel extends MovieClip
	{
		public static const ANIMATION_SPEED:Number = 1;
		
		private var _contentMask:WTContentMask;
		private var _contentContainer:WTContentContainer;
		private var _linkTitlePanel:WTLinkTitlePanel;
		
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
			
			_linkTitlePanel.panelManager = this;
		}
		
		public function addLinkCategory(title:String, content:String):void
		{
			_linkTitlePanel.addLinkTitle(title, content);
		}
		
		public function showLinkCategory(link:WTLinkTitle):void
		{
			_contentMask.showMask();
			_contentContainer.loadContent(link.content);
		}
		
		public function hideLinkCategories(link:WTLinkTitle):void
		{
			_contentMask.hideMask();
		}
		
		public function killContent():void
		{
			_contentContainer.killContent();
		}
	}
}