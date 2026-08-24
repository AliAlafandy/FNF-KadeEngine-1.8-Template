package mobile.util;

import flixel.FlxG;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxPoint;

class TouchUtil
{
	public static var swipeThreshold:Float = 50.0;
	public static var tapThreshold:Float = 10.0;

	public static function getActiveTouch():FlxTouch
	{
		#if mobile
		var touches:Array<FlxTouch> = FlxG.touches.list;
		if (touches != null && touches.length > 0)
		{
			for (touch in touches)
			{
				if (touch != null && touch.active)
					return touch;
			}
		}
		#end
		return null;
	}

	public static function isTouching():Bool
	{
		#if mobile
		return getActiveTouch() != null;
		#else
		return FlxG.mouse.pressed;
		#end
	}

	public static function justPressed():Bool
	{
		#if mobile
		var touches:Array<FlxTouch> = FlxG.touches.list;
		if (touches != null && touches.length > 0)
		{
			for (touch in touches)
			{
				if (touch != null && touch.justPressed)
					return true;
			}
		}
		return false;
		#else
		return FlxG.mouse.justPressed;
		#end
	}

	public static function justReleased():Bool
	{
		#if mobile
		var touches:Array<FlxTouch> = FlxG.touches.list;
		if (touches != null && touches.length > 0)
		{
			for (touch in touches)
			{
				if (touch != null && touch.justReleased)
					return true;
			}
		}
		return false;
		#else
		return FlxG.mouse.justReleased;
		#end
	}

	public static function getTouchPosition(?point:FlxPoint):FlxPoint
	{
		if (point == null)
			point = FlxPoint.get();

		#if mobile
		var touch:FlxTouch = getActiveTouch();
		if (touch != null)
		{
			point.set(touch.x, touch.y);
			return point;
		}
		#end

		point.set(FlxG.mouse.x, FlxG.mouse.y);
		return point;
	}

	public static function isTouchOver(x:Float, y:Float, width:Float, height:Float):Bool
	{
		#if mobile
		var touches:Array<FlxTouch> = FlxG.touches.list;
		if (touches != null && touches.length > 0)
		{
			for (touch in touches)
			{
				if (touch != null && touch.active)
				{
					if (touch.x >= x && touch.x <= x + width && touch.y >= y && touch.y <= y + height)
						return true;
				}
			}
		}
		return false;
		#else
		var mx:Float = FlxG.mouse.x;
		var my:Float = FlxG.mouse.y;
		return (mx >= x && mx <= x + width && my >= y && my <= y + height);
		#end
	}

	public static function getSwipeDirection():SwipeDirection
	{
		#if mobile
		var touch:FlxTouch = getActiveTouch();
		if (touch != null && touch.justReleased)
		{
			var deltaX:Float = touch.x - touch.justPressedPosition.x;
			var deltaY:Float = touch.y - touch.justPressedPosition.y;

			if (Math.abs(deltaX) > swipeThreshold || Math.abs(deltaY) > swipeThreshold)
			{
				if (Math.abs(deltaX) > Math.abs(deltaY))
					return deltaX > 0 ? RIGHT : LEFT;
				else
					return deltaY > 0 ? DOWN : UP;
			}
		}
		#end

		return NONE;
	}
}

enum SwipeDirection
{
	NONE;
	UP;
	DOWN;
	LEFT;
	RIGHT;
}
