package;

import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.display.BitmapData;
import haxe.Json;
import mobile.backend.StorageUtil;

#if ASTC_TEXTURES
import mobile.backend.ASTCLoader;
#end

using StringTools;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;

	#if ASTC_TEXTURES
	inline public static var IMAGE_EXT = "astc";
	#else
	inline public static var IMAGE_EXT = "png";
	#end

	static var currentLevel:String;

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

	static function externalModsPath(relativePath:String, ?library:String):String
	{
		#if mobile
		var candidate = 'mods/$relativePath';
		if (StorageUtil.exists(candidate))
			return candidate;

		if (library != null)
		{
			candidate = 'mods/$library/$relativePath';
			if (StorageUtil.exists(candidate))
				return candidate;
		}
		#end

		return null;
	}

	static public function loadImage(key:String, ?library:String):FlxGraphic
	{
		#if mobile
		var externalRelative = externalModsPath('images/$key.png', library);
		if (externalRelative != null)
		{
			var externalGraphic = loadExternalImage(externalRelative, key);
			if (externalGraphic != null)
				return externalGraphic;
		}
		#end

		var path = image(key, library);

		#if FEATURE_FILESYSTEM
		if (Caching.bitmapData != null)
		{
			if (Caching.bitmapData.exists(key))
			{
				Debug.logTrace('Loading image from bitmap cache: $key');
				return Caching.bitmapData.get(key);
			}
		}
		#end

		#if ASTC_TEXTURES
		var astcGraphic = loadASTCImage(path, key);
		if (astcGraphic != null)
			return astcGraphic;
		#end

		if (OpenFlAssets.exists(path, IMAGE))
		{
			var bitmap = OpenFlAssets.getBitmapData(path);
			return FlxGraphic.fromBitmapData(bitmap);
		}
		else
		{
			Debug.logWarn('Could not find image at path $path');
			return null;
		}
	}

	#if mobile
	static function loadExternalImage(relativePath:String, key:String):FlxGraphic
	{
		var bytes = StorageUtil.readBytes(relativePath);

		if (bytes == null)
			return null;

		try
		{
			var limeImage = lime.graphics.Image.fromBytes(bytes);
			var bitmap = BitmapData.fromImage(limeImage);
			return FlxGraphic.fromBitmapData(bitmap, false, key);
		}
		catch (e:Dynamic)
		{
			Debug.logWarn('Failed decoding external image: $relativePath');
			return null;
		}
	}
	#end

	#if ASTC_TEXTURES
	static function loadASTCImage(path:String, key:String):FlxGraphic
	{
		var astcPath = toASTCPath(path);

		if (!OpenFlAssets.exists(astcPath, BINARY))
			return null;

		var bytes = OpenFlAssets.getBytes(astcPath);

		if (bytes == null)
			return null;

		var bitmap = ASTCLoader.decode(bytes);

		if (bitmap == null)
			return null;

		return FlxGraphic.fromBitmapData(bitmap, false, key);
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
		var rawJson:String = null;

		#if mobile
		var externalRelative = externalModsPath('data/$key.json', library);
		if (externalRelative != null)
			rawJson = StorageUtil.readString(externalRelative);
		#end

		if (rawJson == null)
			rawJson = OpenFlAssets.getText(Paths.json(key, library));

		rawJson = rawJson.trim();

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
}
