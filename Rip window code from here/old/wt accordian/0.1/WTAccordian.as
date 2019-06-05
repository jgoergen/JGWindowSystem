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
		public var ANIMATION_SPEED:Number = 1;
		public var NODE_INDENTION:Boolean = false;
		public var SINGLE_PATH:Boolean = true;
		
		public var headers:Array;
		public var batching:Boolean = false;		
		public var _scrollPane:ScrollPane;
		public var _container:Sprite;		
		
		private var batchSpawned:int = 0;
		private var batchReady:int = 0;
		private var batchBegin:Number = 0;
		
		public function WTAccordian()
		{
			headers = new Array();
			
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
		
		public function reportReady(header:WTHeader):void { batchReady ++; }
		
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
			
			trace(batchSpawned + " headers added in " + (getTimer() - batchBegin) + " milliseconds.");
			batchSpawned = 0;
		}
		
		public function addHeader(parentHeader:WTHeader, theTitle:String, theItemKey:Object = null):void
		{
			if (batching)
				batchSpawned++;
			
			var newHeader:WTHeader;
			
			if (parentHeader == null)
			{
				// root level header
				newHeader = new WTHeader(this, 0, theTitle, theItemKey);
				headers.push(newHeader);
			} else {
				newHeader = new WTHeader(this, (parentHeader.level + 1), theTitle, theItemKey);				
				parentHeader.addHeader(newHeader);
			}
		}
		
		public function addHeaderById(parentID:int, theTitle:String, theItemKey:Object = null):void
		{
			if (parentID == 0)
			{
				addHeader(null, theTitle);
			} else {
				addHeader(headers[parentID - 1], theTitle, theItemKey);
			}
		}
		
		public function updateHeaderPositions():void
		{
			var lastY:Number = 0;
			
			for each (var header:WTHeader in headers)
			{
				if (header.parentHeader == null)
				{
					header.moveTo(new Point(header.x, lastY));
					
					lastY += header.realHeight;
				}
			}
		}
		
		public function closeAllOtherHeaders(theHeader:WTHeader):void
		{
			for each (var header:WTHeader in headers)
			{
				if (header.parentHeader == null && header != theHeader && header.collapsed == true)
					header.hideChildren(true);
			}
		}
		
		public function get entries():int
		{
			return headers.length;
		}
		
		public function itemClicked(itemKey:Object):void
		{
			dispatchEvent(new WTHeaderEvent(WTHeaderEvent.SELECTED, itemKey));
		}
	}
}