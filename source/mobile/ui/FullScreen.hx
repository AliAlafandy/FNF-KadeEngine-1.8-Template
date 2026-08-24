package mobile.ui;

import flixel.FlxG;
import openfl.Lib;
import openfl.events.Event;

class FullScreen
{
	public static var active:Bool = true;

	static var baseWidth:Int = 1280;
	static var baseHeight:Int = 720;
	static var initialized:Bool = false;

	public static function init(gameWidth:Int, gameHeight:Int):Void
	{
		baseWidth = gameWidth;
		baseHeight = gameHeight;

		if (!initialized)
		{
			Lib.current.stage.addEventListener(Event.RESIZE, onResize);
			initialized = true;
		}

		apply();
	}

	static function onResize(e:Event):Void
	{
		apply();
	}

	public static function apply():Void
	{
		if (!active || baseWidth <= 0 || baseHeight <= 0)
			return;

		var stage = Lib.current.stage;
		if (stage == null)
			return;

		var stageWidth:Int = stage.stageWidth;
		var stageHeight:Int = stage.stageHeight;

		if (stageWidth <= 0 || stageHeight <= 0)
			return;

		var screenRatio:Float = stageWidth / stageHeight;
		var baseRatio:Float = baseWidth / baseHeight;

		var newWidth:Int = baseWidth;
		var newHeight:Int = baseHeight;

		if (screenRatio > baseRatio)
		{
			newWidth = Math.ceil(baseHeight * screenRatio);
		}
		else if (screenRatio < baseRatio)
		{
			newHeight = Math.ceil(baseWidth / screenRatio);
		}

		if (FlxG.width != newWidth || FlxG.height != newHeight)
		{
			FlxG.resizeGame(newWidth, newHeight);
			recenterCameras(newWidth, newHeight);
		}
	}

	static function recenterCameras(width:Int, height:Int):Void
	{
		if (FlxG.cameras == null || FlxG.cameras.list == null)
			return;

		for (camera in FlxG.cameras.list)
		{
			if (camera == null)
				continue;

			camera.setSize(width, height);
			camera.setPosition(0, 0);
		}
	}

	public static function getSafeBounds():{x:Float, y:Float, width:Float, height:Float}
	{
		var offsetX:Float = (FlxG.width - baseWidth) / 2;
		var offsetY:Float = (FlxG.height - baseHeight) / 2;

		return {
			x: offsetX,
			y: offsetY,
			width: baseWidth,
			height: baseHeight
		};
	}

	public static function toggle(enable:Bool):Void
	{
		active = enable;

		if (active)
			apply();
		else if (baseWidth > 0 && baseHeight > 0)
			FlxG.resizeGame(baseWidth, baseHeight);
	}
}
