package
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;	
	import fl.transitions.easing.*; 
	
	public class WTContentMask extends MovieClip
	{
		private const MINIMUM_MASK_HEIGHT:Number = 0.01;
		private const MAXIUMUM_MASK_HEIGHT:Number = 266.15;
		
		private var state:int = 0;
		private var _squareObject:Object;
		private var heightTween:Tween;
		
		public function WTContentMask()
		{
			addEventListener(Event.ENTER_FRAME, initialize);
		}
		
		public function initialize(event:Event):void
		{
			stop();
			removeEventListener(Event.ENTER_FRAME, initialize);
			
			_squareObject = getChildAt(0);
			
			_squareObject.height = MINIMUM_MASK_HEIGHT;
		}
		
		public function showMask():void
		{
			if (state != 1)
			{
				runTween(MAXIUMUM_MASK_HEIGHT);
				state = 1;
			}
		}
		
		public function hideMask():void
		{
			if (state != 0)
			{
				runTween(MINIMUM_MASK_HEIGHT);
				state = 0;
			}
		}
		
		private function runTween(newHeight:Number):void
		{
			if (heightTween != null)
				heightTween.stop();
				
			heightTween = new Tween(_squareObject, "height", Strong.easeOut, _squareObject.height, newHeight, WTLinkPanel.ANIMATION_SPEED, true);
			// ADD ON COMPLETE EVENT HERE TO CALL PARENTS killContent() FUNCTION
		}
	}
}