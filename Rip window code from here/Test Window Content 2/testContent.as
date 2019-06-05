package
{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	
	import com.wambatech.windowmanager.WTWindowContent;
	import com.wambatech.windowmanager.WTWindowContentEvent;
		
	public class testContent extends WTWindowContent
	{		
		private var _circle:MovieClip;
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
				
			_circle = getChildByName("circle_mc") as MovieClip;
			_topLeft = getChildByName("topLeft_mc") as MovieClip;
			_topRight = getChildByName("topRight_mc") as MovieClip;
			_bottomLeft = getChildByName("bottomLeft_mc") as MovieClip;
			_bottomRight = getChildByName("bottomRight_mc") as MovieClip;
			_bg = getChildByName("bg_mc") as MovieClip;
							
			if (firstRun)
			{
				storedData["circleX"] = "0";
				storedData["circleY"] = "0";
			}
			
			_circle.x = storedData["circleX"];
			_circle.y = storedData["circleY"];
			
			_circle.addEventListener(MouseEvent.MOUSE_DOWN, function() { _circle.startDrag(); });
			_circle.addEventListener(MouseEvent.MOUSE_UP, function() { _circle.stopDrag(); storedData["circleX"] = _circle.x; storedData["circleY"] = _circle.y; });
		
			// event listeners for reactions to window events
			// NOTE: these events get called OFTEN so keep their handlers light.
			//		 this level of update detail will provide content the ability to seem well tied to resize 
			//		 events and their 'tweening' if animation is enabled.
			addEventListener(WTWindowContentEvent.WINDOW_WIDTH_CHANGED, widthResizeHandler);
			addEventListener(WTWindowContentEvent.WINDOW_HEIGHT_CHANGED, heightResizeHandler);
			
			// general mouse events to show off the ability to show / hide window decorations dynamically.
			addEventListener(WTWindowContentEvent.WINDOW_MOUSE_OVER, rollOverhandler);
			addEventListener(WTWindowContentEvent.WINDOW_MOUSE_OUT, rollOuthandler);
			
			reDraw();
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
		
		private function rollOverhandler(event:WTWindowContentEvent):void
		{
			showWindowDecorations();
		}
		
		private function rollOuthandler(event:WTWindowContentEvent):void
		{
			hideWindowDecorations();
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
			
			_bg.x = 0;
			_bg.y = 0;
			_bg.width = myWidth;
			_bg.height = myHeight;
		}
	}
}