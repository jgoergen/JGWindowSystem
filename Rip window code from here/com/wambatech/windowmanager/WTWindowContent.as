///////////////////////////////////////////////////////////////////////////////////////
//
// WAMBATECH WINDOW CONTENT
//
// NOTE: ACTUAL WINDOW CONTENT SHOULD EXTEND THIS CLASS, SHOULD NEVER BE USED DIRECTLY.
//
// FACILITATES COMMUNICATION WITH PARENT WINDOW
//
// TODO:
//
///////////////////////////////////////////////////////////////////////////////////////

package com.wambatech.windowmanager
{
	import flash.display.MovieClip;
	import flash.events.Event;
					
	public class WTWindowContent extends MovieClip
	{			
		public var storedData:Object;
		
		private var dataReady:Boolean = false;
		private var dataProvided:Boolean = false;
		private var parentWindow:WTWindow;
		
		// Constructor
		public function WTWindowContent()
		{			
			storedData = new Object();
			addEventListener(Event.ENTER_FRAME, activate);
		}
		
		private function activate(event:Event):void
		{
			if (dataReady == true)
			{
				removeEventListener(Event.ENTER_FRAME, activate);
				
				parentWindow.addContent(this);
				
				if (dataProvided == true)
				{
					initialize(false);
				} else {
					initialize(true);
				}
				
				parentWindow._windowWidth += 1;
				parentWindow._windowHeight += 1;
				
				parentWindow._windowWidth -= 1;
				parentWindow._windowHeight -= 1;
			}
		}
		
		// ensure flash is actually ready to go before kicking manager into gear.
		public virtual function initialize(firstRun:Boolean):void { }
		
		public function loadSetupData(theParentWindow:WTWindow, setupData:Object):void
		{
			parentWindow = theParentWindow;
			
			if (setupData != null)
			{
				storedData = setupData;
				dataProvided = true;
			}
				
			dataReady = true;
		}
		
		public function serialize(defaultContent:String, parentID:int):String
		{			
			var tmpXML:String = "";
			var props:String = "";			
			
			for (var prop in storedData) { props += prop + "='" + storedData[prop] + "' "; }			
			
			tmpXML = "<WTWindowContent defaultContent='" + defaultContent + "' parentID='" + parentID + "' " + props + "></WTWindowContent>\n";
			return tmpXML;
		}
		
		public function hideWindowDecorations():void { parentWindow.hideWindowDecorations(); }		
		public function showWindowDecorations():void { parentWindow.showWindowDecorations(); }
	}
}