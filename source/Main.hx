package;

import openfl.display.Bitmap;
import lime.app.Application;
#if FEATURE_DISCORD
import Discord.DiscordClient;
#end
import openfl.display.BlendMode;
import openfl.text.TextFormat;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import lime.system.System;
import mobile.backend.StorageUtil;
import mobile.ui.Fullscreen;

class Main extends Sprite
{
	var gameWidth:Int = 1280;
	var gameHeight:Int = 720;
	var initialState:Class<FlxState> = TitleState;
	var zoom:Float = -1;
	var framerate:Int = 60;
	var skipSplash:Bool = true;
	var startFullscreen:Bool = false;

	public static var bitmapFPS:Bitmap;

	public static var instance:Main;

	public static var path:String = StorageUtil.baseDirectory;

	public static var watermarks = true;

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		instance = this;

		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	public static var webmHandler:WebmHandler;

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		#if mobile
		gameWidth = 1280;
		gameHeight = 720;
		zoom = 1;

		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;

		setupMobileBackHandling();
		setupMobileLifecycle();
		#end

		#if !cpp
		framerate = 60;
		#end

		Debug.onInitProgram();

		ModCore.initialize();

		fpsCounter = new KadeEngineFPS(10, 3, 0xFFFFFF);
		bitmapFPS = ImageOutline.renderImage(fpsCounter, 1, 0x000000, true);
		bitmapFPS.smoothing = true;

		game = new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen);
		addChild(game);

		addChild(fpsCounter);
		toggleFPS(FlxG.save.data.fps);

		#if mobile
		Fullscreen.init(gameWidth, gameHeight);
		#end

		Debug.onGameStart();
	}

	#if mobile
	private function setupMobileBackHandling():Void
	{
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onMobileKeyDown);
	}

	private function onMobileKeyDown(e:KeyboardEvent):Void
	{
		if (e.keyCode == 27)
		{
			e.preventDefault();

			if (Std.isOfType(FlxG.state, PauseSubState) || Reflect.hasField(FlxG.state, 'onMobileBack'))
			{
				Reflect.callMethod(FlxG.state, Reflect.field(FlxG.state, 'onMobileBack'), []);
			}
		}
	}

	private function setupMobileLifecycle():Void
	{
		Application.current.window.onFocusOut.add(onMobileFocusOut);
		Application.current.window.onFocusIn.add(onMobileFocusIn);
	}

	private function onMobileFocusOut():Void
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.pause();

		for (sound in FlxG.sound.list.members)
		{
			if (sound != null && sound.playing)
				sound.pause();
		}
	}

	private function onMobileFocusIn():Void
	{
		if (FlxG.sound.music != null && !FlxG.sound.music.playing)
			FlxG.sound.music.resume();
	}
	#end

	var game:FlxGame;

	var fpsCounter:KadeEngineFPS;

	public static function dumpCache()
	{
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null)
			{
				Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}
		Assets.cache.clear("songs");
	}

	public function toggleFPS(fpsEnabled:Bool):Void
	{
		fpsCounter.visible = fpsEnabled;
		bitmapFPS.visible = fpsEnabled;
	}

	public function changeFPSColor(color:FlxColor)
	{
		fpsCounter.textColor = color;
	}

	public function setFPSCap(cap:Float)
	{
		openfl.Lib.current.stage.frameRate = cap;
	}

	public function getFPSCap():Float
	{
		return openfl.Lib.current.stage.frameRate;
	}

	public function getFPS():Float
	{
		return fpsCounter.currentFPS;
	}
}
