package
{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.events.Event;
	import flash.geom.Point;
	
	import com.wambatech.windowmanager.WTWindowContent;
	import com.wambatech.windowmanager.WTWindowContentEvent;
	import com.wambatech.dragdrop.DragDropManager;
		
	public class testContent extends WTWindowContent
	{		
		private var _textbox:TextField;
		private var _topLeft:MovieClip;
		private var _topRight:MovieClip;
		private var _bottomLeft:MovieClip;
		private var _bottomRight:MovieClip;
		private var _bg:MovieClip;
		public var myWidth:Number = 0;
		public var myHeight:Number = 0;
		
		public override function initialize(firstRun:Boolean):void
		{
			stop();
				
			_textbox = getChildByName("textbox_txt") as TextField;
			_topLeft = getChildByName("topLeft_mc") as MovieClip;
			_topRight = getChildByName("topRight_mc") as MovieClip;
			_bottomLeft = getChildByName("bottomLeft_mc") as MovieClip;
			_bottomRight = getChildByName("bottomRight_mc") as MovieClip;
			_bg = getChildByName("bg_mc") as MovieClip;
							
			if (firstRun)
			{
				storedData["myText"] = "some text";
			}
			
			_textbox.text = storedData["myText"];
			
			_textbox.addEventListener(Event.CHANGE, function() { storedData["myText"] = _textbox.text; });
			
			// event listeners for reactions to window events
			// NOTE: these events get called OFTEN so keep their handlers light.
			//		 this level of update detail will provide content the ability to seem well tied to resize 
			//		 events and their 'tweening' if animation is enabled.
			addEventListener(WTWindowContentEvent.WINDOW_WIDTH_CHANGED, widthResizeHandler);
			addEventListener(WTWindowContentEvent.WINDOW_HEIGHT_CHANGED, heightResizeHandler);
						
			DragDropManager.registerDropObject(this, "string", dataDropped);
						
			reDraw();
		}
		
		public function dataDropped(theData:String, droppedPos:Point):void
		{			
			_textbox.text = theData;
		}
		
		private function widthResizeHandler(event:WTWindowContentEvent):void
		{
			myWidth = event.newValue;
			reDraw();
		}
		
		private function heightResizeHandler(event:WTWindowContentEvent):void
		{
			myHeight = event.newValue;
			reDraw();
		}
				
		private function reDraw():void
		{			
			var cornerPadding:Number = 10;
			
			_topLeft.x = 0 + cornerPadding;
			_topLeft.y = 0 + cornerPadding;
			
			_topRight.x = myWidth - _topRight.width - cornerPadding;
			_topRight.y = 0 + cornerPadding;
			
			_bottomLeft.x = 0 + cornerPadding;
			_bottomLeft.y = myHeight - _bottomLeft.height - cornerPadding;
			
			_bottomRight.x = myWidth - _bottomRight.width - cornerPadding;
			_bottomRight.y = myHeight - _bottomRight.height - cornerPadding;
			
			_textbox.width = myWidth - (cornerPadding * 2) - 12;
			_textbox.x = 0 + cornerPadding + 4;
			_textbox.y = (myHeight / 2) - (_textbox.height / 2);
			
			_bg.x = 0;
			_bg.y = 0;
			_bg.width = myWidth;
			_bg.height = myHeight;
		}
	}
}