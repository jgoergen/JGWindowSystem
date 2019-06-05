package com.wambatech.components.linkpanel
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.display.Loader;
	import flash.utils.getDefinitionByName;
	
	public class WTContentContainer extends MovieClip
	{		
		public var titleManager:WTLinkPanel;
	
		private var showingContent:String = "";
		private var contentInstance:Object;
		private var contentLoader:Loader;
		
		public function WTContentContainer()
		{
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
			titleManager.cancelKill();
		}
		
		private function rollOutHandler(event:MouseEvent):void
		{
			titleManager.hideLinkCategories(null);
		}
		
		public function loadContent(lid:String):void 
		{
			if (showingContent == lid)
				return;
			
			if (showingContent != "")
				killContent();
				
			if (lid == "" && lid != null)
				return;
							
			// is this internal or external?
			if (lid.substr(lid.length - 4, 4) == ".swf")
			{
				contentLoader = new Loader(); 
				var url:URLRequest = new URLRequest(lid); 				
				contentLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, finishLoad);				
				contentLoader.load(url); 				
				showingContent = lid;
				return;
			} else {
				var classDefintion:Class = getDefinitionByName(lid) as Class;
				contentInstance = new classDefintion();
				addChild(contentInstance as MovieClip);
				showingContent = lid;
			}
		}
		
		private function finishLoad(event:Event):void
		{
			contentInstance = contentLoader.content;
		}
		
		public function killContent():void
		{
			showingContent = "";
			removeChild(contentInstance as MovieClip);
			contentInstance = null;
		}
	}
}