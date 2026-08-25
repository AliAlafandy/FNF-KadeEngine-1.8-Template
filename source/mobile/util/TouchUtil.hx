package mobile.util;

import flixel.FlxG;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

enum SwipeDirection
{
	NONE;
	UP;
	DOWN;
	LEFT;
	RIGHT;
	UP_LEFT;
	UP_RIGHT;
	DOWN_LEFT;
	DOWN_RIGHT;
}

enum TouchZone
{
	NONE;
	TOP_LEFT;
	TOP_RIGHT;
	BOTTOM_LEFT;
	BOTTOM_RIGHT;
	CENTER;
	CUSTOM(rect:FlxRect);
}

class TouchUtil
{
	public static var minSwipeDistance:Float = 50.0;
	public static var maxTapDuration:Float = 0.25;

	public static function isPressed():Bool
	{
		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.pressed)
				return true;
		}
		#elseif FLX_MOUSE
		return FlxG.mouse.pressed;
		#end
		return false;
	}

	public static function isJustPressed():Bool
	{
		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
				return true;
		}
		#elseif FLX_MOUSE
		return FlxG.mouse.justPressed;
		#end
		return false;
	}

	public static function isJustReleased():Bool
	{
		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justReleased)
				return true;
		}
		#elseif FLX_MOUSE
		return FlxG.mouse.justReleased;
		#end
		return false;
	}

	public static function getActiveTouchCount():Int
	{
		#if mobile
		var count:Int = 0;
		for (touch in FlxG.touches.list)
		{
			if (touch.pressed)
				count++;
		}
		return count;
		#elseif FLX_MOUSE
		return FlxG.mouse.pressed ? 1 : 0;
		#else
		return 0;
		#end
	}

	public static function getTouchPosition(touchID:Int = 0):FlxPoint
	{
		var point:FlxPoint = FlxPoint.get(0, 0);
		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.touchPointID == touchID)
			{
				point.set(touch.screenX, touch.screenY);
				break;
			}
		}
		#elseif FLX_MOUSE
		point.set(FlxG.mouse.screenX, FlxG.mouse.screenY);
		#end
		return point;
	}

	public static function getSwipeDirection():SwipeDirection
	{
		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justReleased)
			{
				var startX:Float = touch.justPressedPosition.x;
				var startY:Float = touch.justPressedPosition.y;
				var deltaX:Float = touch.screenX - startX;
				var deltaY:Float = touch.screenY - startY;
				var distance:Float = Math.sqrt(deltaX * deltaX + deltaY * deltaY);

				if (distance >= minSwipeDistance)
				{
					var angle:Float = Math.atan2(deltaY, deltaX) * (180 / Math.PI);
					if (angle < 0) angle += 360;

					if (angle >= 337.5 || angle < 22.5) return RIGHT;
					if (angle >= 22.5 && angle < 67.5) return DOWN_RIGHT;
					if (angle >= 67.5 && angle < 112.5) return DOWN;
					if (angle >= 112.5 && angle < 157.5) return DOWN_LEFT;
					if (angle >= 157.5 && angle < 202.5) return LEFT;
					if (angle >= 202.5 && angle < 247.5) return UP_LEFT;
					if (angle >= 247.5 && angle < 292.5) return UP;
					if (angle >= 292.5 && angle < 337.5) return UP_RIGHT;
				}
			}
		}
		#end
		return NONE;
	}

	public static function isTapInZone(zone:TouchZone):Bool
	{
		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justReleased)
			{
				if (checkPointInZone(touch.screenX, touch.screenY, zone))
					return true;
			}
		}
		#elseif FLX_MOUSE
		if (FlxG.mouse.justReleased)
		{
			return checkPointInZone(FlxG.mouse.screenX, FlxG.mouse.screenY, zone);
		}
		#end
		return false;
	}

	public static function isPressedInZone(zone:TouchZone):Bool
	{
		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.pressed)
			{
				if (checkPointInZone(touch.screenX, touch.screenY, zone))
					return true;
			}
		}
		#elseif FLX_MOUSE
		if (FlxG.mouse.pressed)
		{
			return checkPointInZone(FlxG.mouse.screenX, FlxG.mouse.screenY, zone);
		}
		#end
		return false;
	}

	private static function checkPointInZone(x:Float, y:Float, zone:TouchZone):Bool
	{
		var w:Float = FlxG.width;
		var h:Float = FlxG.height;

		return switch (zone)
		{
			case TOP_LEFT: (x >= 0 && x < w * 0.5 && y >= 0 && y < h * 0.5);
			case TOP_RIGHT: (x >= w * 0.5 && x <= w && y >= 0 && y < h * 0.5);
			case BOTTOM_LEFT: (x >= 0 && x < w * 0.5 && y >= h * 0.5 && y <= h);
			case BOTTOM_RIGHT: (x >= w * 0.5 && x <= w && y >= h * 0.5 && y <= h);
			case CENTER: (x >= w * 0.25 && x <= w * 0.75 && y >= h * 0.25 && y <= h * 0.75);
			case CUSTOM(rect): (x >= rect.x && x <= rect.x + rect.width && y >= rect.y && y <= rect.y + rect.height);
			case NONE: false;
		}
	}

	public static function getPinchScale():Float
	{
		#if mobile
		var activeTouches:Array<FlxTouch> = [];
		for (touch in FlxG.touches.list)
		{
			if (touch.pressed)
				activeTouches.push(touch);
		}

		if (activeTouches.length >= 2)
		{
			var t1:FlxTouch = activeTouches[0];
			var t2:FlxTouch = activeTouches[1];

			var curDist:Float = FlxMath.distanceBetween(t1, t2);
			var prevDist:Float = Math.sqrt(
				Math.pow((t1.screenX - t1.deltaX) - (t2.screenX - t2.deltaX), 2) +
				Math.pow((t1.screenY - t1.deltaY) - (t2.screenY - t2.deltaY), 2)
			);

			if (prevDist > 0)
				return curDist / prevDist;
		}
		#end
		return 1.0;
	}
}
