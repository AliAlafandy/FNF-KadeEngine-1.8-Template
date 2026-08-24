import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.events.Event;
import openfl.events.TouchEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;

#if gl_stats
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end

#if mobile
import mobile.ui.FullScreen;
#end

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class KadeEngineFPS extends TextField
{
	public var currentFPS(default, null):Int;
	public var bitmap:Bitmap;

	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var currentTime:Float;
	@:noCompletion private var times:Array<Float>;

	#if mobile
	static inline var MOBILE_UPDATE_INTERVAL:Float = 250;

	var timeSinceUpdate:Float = 0;
	var tapZoneSize:Float = 96;
	var baseX:Float;
	var baseY:Float;
	#end

	var array:Array<FlxColor> = [
		FlxColor.fromRGB(148, 0, 211),
		FlxColor.fromRGB(75, 0, 130),
		FlxColor.fromRGB(0, 0, 255),
		FlxColor.fromRGB(0, 255, 0),
		FlxColor.fromRGB(255, 255, 0),
		FlxColor.fromRGB(255, 127, 0),
		FlxColor.fromRGB(255, 0, 0)
	];

	var skippedFrames:Int = 0;
	public static var currentColor:Int = 0;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		#if mobile
		baseX = x;
		baseY = y;

		var scale:Float = getMobileScale();
		var safeBounds = FullScreen.getSafeBounds();
		this.x = safeBounds.x + (x * scale);
		this.y = safeBounds.y + (y * scale);
		#else
		this.x = x;
		this.y = y;
		#end

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;

		var fontSize:Int = 14;

		#if mobile
		fontSize = Math.round(fontSize * getMobileScale());
		#end

		var font = openfl.utils.Assets.getFont("assets/fonts/vcr.ttf");
		var fontName:String = font != null ? font.fontName : "_sans";

		defaultTextFormat = new TextFormat(fontName, fontSize, color);
		text = "FPS: ";
		width += 200;

		cacheCount = 0;
		currentTime = 0;
		times = [];

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			var time = Lib.getTimer();
			__enterFrame(time - currentTime);
		});
		#end

		bitmap = ImageOutline.renderImage(this, 1, 0x000000, 1, true);
		if (Main.instance != null)
			Main.instance.addChild(bitmap);

		#if mobile
		setupMobileToggle();
		if (Lib.current != null && Lib.current.stage != null)
			Lib.current.stage.addEventListener(Event.RESIZE, onMobileResize);
		#end
	}

	#if mobile
	function getMobileScale():Float
	{
		var baseHeight:Float = 720;
		var actualHeight:Float = (Lib.current != null && Lib.current.stage != null) ? Lib.current.stage.stageHeight : 0;

		if (actualHeight <= 0)
			return 1;

		var scale:Float = actualHeight / baseHeight;
		return scale < 1 ? 1 : scale;
	}

	function onMobileResize(e:Event):Void
	{
		var scale:Float = getMobileScale();
		var safeBounds = FullScreen.getSafeBounds();

		this.x = safeBounds.x + (baseX * scale);
		this.y = safeBounds.y + (baseY * scale);
	}

	function setupMobileToggle():Void
	{
		if (Lib.current != null && Lib.current.stage != null)
			Lib.current.stage.addEventListener(TouchEvent.TOUCH_TAP, onMobileTap);
	}

	function onMobileTap(e:TouchEvent):Void
	{
		var safeBounds = FullScreen.getSafeBounds();

		if (e.stageX <= safeBounds.x + tapZoneSize && e.stageY <= safeBounds.y + tapZoneSize)
		{
			if (FlxG.save != null && FlxG.save.data != null)
			{
				FlxG.save.data.fps = !FlxG.save.data.fps;
				FlxG.save.flush();
			}
		}
	}
	#end

	@:noCompletion
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void
	{
		#if mobile
		timeSinceUpdate += deltaTime;

		if (timeSinceUpdate < MOBILE_UPDATE_INTERVAL)
			return;

		timeSinceUpdate = 0;
		#end

		if (MusicBeatState.initSave && FlxG.save != null && FlxG.save.data != null && FlxG.save.data.fpsRain)
		{
			if (currentColor >= array.length)
				currentColor = 0;

			var fpsCap:Float = FlxG.save.data.fpsCap != null ? FlxG.save.data.fpsCap : 60;
			var capDiv:Float = fpsCap / 3;
			if (capDiv <= 0)
				capDiv = 20;

			currentColor = Math.round(FlxMath.lerp(0, array.length - 1, skippedFrames / capDiv));
			
			if (Main.instance != null)
				Main.instance.changeFPSColor(array[currentColor]);

			currentColor++;
			skippedFrames++;
			if (skippedFrames > capDiv)
				skippedFrames = 0;
		}

		currentTime += deltaTime;
		times.push(currentTime);

		while (times.length > 0 && times[0] < currentTime - 1000)
		{
			times.shift();
		}

		var currentCount:Int = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);

		var isFpsEnabled:Bool = (FlxG.save != null && FlxG.save.data != null && FlxG.save.data.fps != null) ? FlxG.save.data.fps : true;

		if (currentCount != cacheCount)
		{
			text = isFpsEnabled ? "FPS: " + currentFPS : "";

			if (Main.watermarks)
			{
				if (text.length > 0)
					text += "\n";
				text += "KE v" + MainMenuState.kadeEngineVer;
			}

			#if (gl_stats && !disable_cffi && (!html5 || !canvas))
			text += "\ntotalDC: " + Context3DStats.totalDrawCalls();
			text += "\nstageDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE);
			text += "\nstage3DDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D);
			#end

			visible = true;

			if (Main.instance != null && bitmap != null)
			{
				if (Main.instance.contains(bitmap))
					Main.instance.removeChild(bitmap);

				bitmap = ImageOutline.renderImage(this, 2, 0x000000, 1);
				Main.instance.addChild(bitmap);
			}

			visible = false;
		}

		cacheCount = currentCount;
	}
}
