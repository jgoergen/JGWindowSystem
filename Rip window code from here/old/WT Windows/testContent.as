package
{
	import flash.events.MouseEvent;
		
	public class testContent extends WTWindowContent
	{		
		public override function initialize(firstRun:Boolean):void
		{
			stop();
				
			if (firstRun)
			{
				storedData["circleX"] = "0";
				storedData["circleY"] = "0";
			}
			
			circle_mc.x = storedData["circleX"];
			circle_mc.y = storedData["circleY"];
			
			circle_mc.addEventListener(MouseEvent.MOUSE_DOWN, function() { circle_mc.startDrag(); });
			circle_mc.addEventListener(MouseEvent.MOUSE_UP, function() { circle_mc.stopDrag(); storedData["circleX"] = circle_mc.x; storedData["circleY"] = circle_mc.y; });
		}
	}
}