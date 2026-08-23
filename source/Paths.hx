package;

import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.media.Sound;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import haxe.Json;

#if ASTC_TEXTURES
import mobile.backend.ASTCLoader;
#end

using StringTools;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;

	inline public static var VIDEO_EXT = "webm";

	static var currentLevel:String;

	static var graphicCache:Map<String, FlxGraphic> = new Map();

	static var soundCache:Map<String, Sound> = new Map();

	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	static function getPath(file:String, type:AssetType, library:Null<String>)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath = getLibraryPathForce(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function loadImage(key:String, ?library:String):FlxGraphic
	{
		var path = image(key, library);

		if (graphicCache.exists(path))
		{
			var cached = graphicCache.get(path);

			if (cached != null && cached.bitmap != null)
				return cached;

			graphicCache.remove(path);
		}

		#if FEATURE_FILESYSTEM
		if (Caching.bitmapData != null && Caching.bitmapData.exists(key))
		{
			var cached = Caching.bitmapData.get(key);
			graphicCache.set(path, cached);
			return cached;
		}
		#end

		#if ASTC_TEXTURES
		var astcGraphic = tryLoadASTC(path, key);
		if (astcGraphic != null)
		{
			graphicCache.set(path, astcGraphic);
			return astcGraphic;
		}
		#end

		if (!OpenFlAssets.exists(path, IMAGE))
		{
			Debug.logWarn('Could not find image at path $path');
			return null;
		}

		var bitmap = OpenFlAssets.getBitmapData(path);
		var graphic = FlxGraphic.fromBitmapData(bitmap, false, key);

		graphicCache.set(path, graphic);

		return graphic;
	}

	#if ASTC_TEXTURES
	static function tryLoadASTC(path:String, key:String):FlxGraphic
	{
		var astcPath = toASTCPath(path);

		if (!OpenFlAssets.exists(astcPath, BINARY))
			return null;

		var bytes = OpenFlAssets.getBytes(astcPath);

		if (bytes == null)
			return null;

		if (!ASTCLoader.isSupported())
			return null;

		return null;
	}

	inline static function toASTCPath(path:String):String
	{
		var dotIndex = path.lastIndexOf('.');

		if (dotIndex == -1)
			return path + '.astc';

		return path.substr(0, dotIndex) + '.astc';
	}
	#end

	static public function loadJSON(key:String, ?library:String):Dynamic
	{
		var rawJson = OpenFlAssets.getText(Paths.json(key, library)).trim();

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
		}

		try
		{
			return Json.parse(rawJson);
		}
		catch (e)
		{
			Debug.logError("AN ERROR OCCURRED parsing a JSON file.");
			Debug.logError(e.message);

			return null;
		}
	}

	static public function loadSound(key:String, ?library:String):Sound
	{
		var path = sound(key, library);

		if (soundCache.exists(path))
			return soundCache.get(path);

		if (!OpenFlAssets.exists(path, SOUND))
		{
			Debug.logWarn('Could not find sound at path $path');
			return null;
		}

		var loadedSound = OpenFlAssets.getSound(path);
		soundCache.set(path, loadedSound);

		return loadedSound;
	}

	static public function loadMusic(key:String, ?library:String):Sound
	{
		var path = music(key, library);

		if (soundCache.exists(path))
			return soundCache.get(path);

		if (!OpenFlAssets.exists(path, MUSIC))
		{
			Debug.logWarn('Could not find music at path $path');
			return null;
		}

		var loadedSound = OpenFlAssets.getSound(path);
		soundCache.set(path, loadedSound);

		return loadedSound;
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library:assets/$library/$file';
	}

	inline static function getPreloadPath(file:String)
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, ?library:String, type:AssetType = TEXT)
	{
		return getPath(file, type, library);
	}

	inline static public function lua(key:String, ?library:String)
	{
		return Main.path + getPath('data/$key.lua', TEXT, library);
	}

	inline static public function luaAsset(key:String, ?library:String)
	{
		return getPath('data/$key.lua', TEXT, library);
	}

	inline static public function luaImage(key:String, ?library:String)
	{
		return Main.path + getPath('data/$key.png', IMAGE, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	static public function sound(key:String, ?library:String)
	{
		return getPath('sounds/$key.$SOUND_EXT', SOUND, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String)
	{
		return getPath('music/$key.$SOUND_EXT', MUSIC, library);
	}

	inline static public function video(key:String, ?library:String)
	{
		return getPath('videos/$key.$VIDEO_EXT', BINARY, library);
	}

	inline static public function voices(song:String)
	{
		var songLowercase = StringTools.replace(song, " ", "-").toLowerCase();
		switch (songLowercase)
		{
			case 'dad-battle':
				songLowercase = 'dadbattle';
			case 'philly-nice':
				songLowercase = 'philly';
			case 'm.i.l.f':
				songLowercase = 'milf';
		}
		var result = 'songs:assets/songs/${songLowercase}/Voices.$SOUND_EXT';
		return doesSoundAssetExist(result) ? result : null;
	}

	inline static public function inst(song:String)
	{
		var songLowercase = StringTools.replace(song, " ", "-").toLowerCase();
		switch (songLowercase)
		{
			case 'dad-battle':
				songLowercase = 'dadbattle';
			case 'philly-nice':
				songLowercase = 'philly';
			case 'm.i.l.f':
				songLowercase = 'milf';
		}
		return 'songs:assets/songs/${songLowercase}/Inst.$SOUND_EXT';
	}

	static public function listSongsToCache()
	{
		var soundAssets = OpenFlAssets.list(AssetType.MUSIC).concat(OpenFlAssets.list(AssetType.SOUND));

		var songNames = [];

		for (sound in soundAssets)
		{
			var path = sound.split('/');
			path.reverse();

			var fileName = path[0];
			var songName = path[1];

			if (path[2] != 'songs')
				continue;

			if (songNames.indexOf(songName) != -1)
				continue;

			songNames.push(songName);
		}

		return songNames;
	}

	static public function doesSoundAssetExist(path:String)
	{
		if (path == null || path == "")
			return false;
		return OpenFlAssets.exists(path, AssetType.SOUND) || OpenFlAssets.exists(path, AssetType.MUSIC);
	}

	inline static public function doesTextAssetExist(path:String)
	{
		return OpenFlAssets.exists(path, AssetType.TEXT);
	}

	inline static public function doesImageAssetExist(path:String)
	{
		return OpenFlAssets.exists(path, AssetType.IMAGE);
	}

	inline static public function image(key:String, ?library:String)
	{
		return getPath('images/$key.png', IMAGE, library);
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	static public function getSparrowAtlas(key:String, ?library:String, ?isCharacter:Bool = false)
	{
		if (isCharacter)
		{
			return FlxAtlasFrames.fromSparrow(loadImage('characters/$key', library), file('images/characters/$key.xml', library));
		}
		return FlxAtlasFrames.fromSparrow(loadImage(key, library), file('images/$key.xml', library));
	}

	inline static public function getPackerAtlas(key:String, ?library:String, ?isCharacter:Bool = false)
	{
		if (isCharacter)
		{
			return FlxAtlasFrames.fromSpriteSheetPacker(loadImage('characters/$key', library), file('images/characters/$key.txt', library));
		}
		return FlxAtlasFrames.fromSpriteSheetPacker(loadImage(key, library), file('images/$key.txt', library));
	}

	static public function clearStoredMemory(?excludeKeyList:Array<String>):Void
	{
		if (excludeKeyList == null)
			excludeKeyList = [];

		for (path in graphicCache.keys())
		{
			if (excludeKeyList.indexOf(path) != -1)
				continue;

			var graphic = graphicCache.get(path);

			if (graphic != null)
				graphic.destroy();

			graphicCache.remove(path);
		}

		for (path in soundCache.keys())
		{
			if (excludeKeyList.indexOf(path) != -1)
				continue;

			soundCache.remove(path);
		}
	}

	static public function clearUnusedGraphics():Void
	{
		for (path in graphicCache.keys())
		{
			var graphic = graphicCache.get(path);

			if (graphic == null || graphic.useCount <= 0)
			{
				if (graphic != null)
					graphic.destroy();

				graphicCache.remove(path);
			}
		}
	}
}
