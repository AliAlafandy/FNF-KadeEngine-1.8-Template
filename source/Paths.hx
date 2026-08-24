package;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Json;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

#if ASTC_TEXTURES
import mobile.backend.ASTCLoader;
#end

using StringTools;

class Paths
{
	inline public static var SOUND_EXT:String = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT:String = "webm";

	static var currentLevel:String;

	static var graphicCache:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();
	static var soundCache:Map<String, Sound> = new Map<String, Sound>();

	public static function setCurrentLevel(name:String):Void
	{
		currentLevel = (name != null) ? name.toLowerCase() : null;
	}

	public static function getPath(file:String, type:AssetType, ?library:String):String
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = getLibraryPathForce(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	public static function loadImage(key:String, ?library:String):FlxGraphic
	{
		var path:String = image(key, library);

		if (graphicCache.exists(path))
		{
			var cached:FlxGraphic = graphicCache.get(path);
			if (cached != null && cached.bitmap != null)
				return cached;

			graphicCache.remove(path);
		}

		#if FEATURE_FILESYSTEM
		if (Caching.bitmapData != null && Caching.bitmapData.exists(key))
		{
			var cached:FlxGraphic = Caching.bitmapData.get(key);
			if (cached != null)
			{
				graphicCache.set(path, cached);
				return cached;
			}
		}
		#end

		#if ASTC_TEXTURES
		var astcGraphic:FlxGraphic = tryLoadASTC(path, key);
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

		var bitmap:BitmapData = OpenFlAssets.getBitmapData(path);
		if (bitmap == null)
			return null;

		var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
		if (graphic != null)
		{
			graphic.persist = true;
			graphicCache.set(path, graphic);
		}

		return graphic;
	}

	#if ASTC_TEXTURES
	static function tryLoadASTC(path:String, key:String):FlxGraphic
	{
		var astcPath:String = toASTCPath(path);

		if (!OpenFlAssets.exists(astcPath, BINARY))
			return null;

		var bytes = OpenFlAssets.getBytes(astcPath);
		if (bytes == null)
			return null;

		if (!ASTCLoader.isSupported())
			return null;

		var texture = ASTCLoader.uploadCompressedTexture(bytes);
		if (texture == null)
			return null;

		return null;
	}

	inline static function toASTCPath(path:String):String
	{
		var dotIndex:Int = path.lastIndexOf('.');
		if (dotIndex == -1)
			return path + '.astc';

		return path.substr(0, dotIndex) + '.astc';
	}
	#end

	public static function loadJSON(key:String, ?library:String):Dynamic
	{
		var jsonPath:String = json(key, library);

		if (!doesTextAssetExist(jsonPath))
		{
			Debug.logWarn('JSON file not found at: $jsonPath');
			return null;
		}

		var rawJson:String = OpenFlAssets.getText(jsonPath);
		if (rawJson == null)
			return null;

		rawJson = rawJson.trim();

		while (rawJson.length > 0 && !rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
		}

		if (rawJson.length == 0)
			return null;

		try
		{
			return Json.parse(rawJson);
		}
		catch (e:Dynamic)
		{
			Debug.logError('Failed to parse JSON file at $jsonPath: ' + e);
			return null;
		}
	}

	public static function loadSound(key:String, ?library:String):Sound
	{
		var path:String = sound(key, library);

		if (soundCache.exists(path))
			return soundCache.get(path);

		if (!OpenFlAssets.exists(path, SOUND))
		{
			Debug.logWarn('Could not find sound at path $path');
			return null;
		}

		var loadedSound:Sound = OpenFlAssets.getSound(path);
		if (loadedSound != null)
			soundCache.set(path, loadedSound);

		return loadedSound;
	}

	public static function loadMusic(key:String, ?library:String):Sound
	{
		var path:String = music(key, library);

		if (soundCache.exists(path))
			return soundCache.get(path);

		if (!OpenFlAssets.exists(path, MUSIC))
		{
			Debug.logWarn('Could not find music at path $path');
			return null;
		}

		var loadedSound:Sound = OpenFlAssets.getSound(path);
		if (loadedSound != null)
			soundCache.set(path, loadedSound);

		return loadedSound;
	}

	public static function getLibraryPath(file:String, library:String = "preload"):String
	{
		return (library == "preload" || library == "default") ? getPreloadPath(file) : getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String):String
	{
		return '$library:assets/$library/$file';
	}

	inline static function getPreloadPath(file:String):String
	{
		return 'assets/$file';
	}

	inline public static function file(file:String, ?library:String, type:AssetType = TEXT):String
	{
		return getPath(file, type, library);
	}

	inline public static function lua(key:String, ?library:String):String
	{
		return Main.path + getPath('data/$key.lua', TEXT, library);
	}

	inline public static function luaAsset(key:String, ?library:String):String
	{
		return getPath('data/$key.lua', TEXT, library);
	}

	inline public static function luaImage(key:String, ?library:String):String
	{
		return Main.path + getPath('data/$key.png', IMAGE, library);
	}

	inline public static function txt(key:String, ?library:String):String
	{
		return getPath('$key.txt', TEXT, library);
	}

	inline public static function xml(key:String, ?library:String):String
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline public static function json(key:String, ?library:String):String
	{
		return getPath('data/$key.json', TEXT, library);
	}

	public static function sound(key:String, ?library:String):String
	{
		return getPath('sounds/$key.$SOUND_EXT', SOUND, library);
	}

	inline public static function soundRandom(key:String, min:Int, max:Int, ?library:String):String
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline public static function music(key:String, ?library:String):String
	{
		return getPath('music/$key.$SOUND_EXT', MUSIC, library);
	}

	inline public static function video(key:String, ?library:String):String
	{
		return getPath('videos/$key.$VIDEO_EXT', BINARY, library);
	}

	public static function formatSongName(song:String):String
	{
		if (song == null)
			return "";

		var formatted:String = song.replace(" ", "-").toLowerCase();
		return switch (formatted)
		{
			case 'dad-battle': 'dadbattle';
			case 'philly-nice': 'philly';
			case 'm.i.l.f': 'milf';
			default: formatted;
		};
	}

	inline public static function voices(song:String):String
	{
		var songFormatted:String = formatSongName(song);
		var result:String = 'songs:assets/songs/${songFormatted}/Voices.$SOUND_EXT';
		return doesSoundAssetExist(result) ? result : null;
	}

	inline public static function inst(song:String):String
	{
		var songFormatted:String = formatSongName(song);
		return 'songs:assets/songs/${songFormatted}/Inst.$SOUND_EXT';
	}

	public static function listSongsToCache():Array<String>
	{
		var soundAssets:Array<String> = OpenFlAssets.list(AssetType.MUSIC).concat(OpenFlAssets.list(AssetType.SOUND));
		var songNames:Array<String> = [];

		for (soundPath in soundAssets)
		{
			var parts:Array<String> = soundPath.split('/');
			parts.reverse();

			if (parts.length < 3 || parts[2] != 'songs')
				continue;

			var songName:String = parts[1];
			if (songNames.indexOf(songName) == -1)
				songNames.push(songName);
		}

		return songNames;
	}

	public static function doesSoundAssetExist(path:String):Bool
	{
		if (path == null || path == "")
			return false;
		return OpenFlAssets.exists(path, SOUND) || OpenFlAssets.exists(path, MUSIC);
	}

	inline public static function doesTextAssetExist(path:String):Bool
	{
		return path != null && path != "" && OpenFlAssets.exists(path, TEXT);
	}

	inline public static function doesImageAssetExist(path:String):Bool
	{
		return path != null && path != "" && OpenFlAssets.exists(path, IMAGE);
	}

	inline public static function image(key:String, ?library:String):String
	{
		return getPath('images/$key.png', IMAGE, library);
	}

	inline public static function font(key:String):String
	{
		return 'assets/fonts/$key';
	}

	public static function getSparrowAtlas(key:String, ?library:String, isCharacter:Bool = false):FlxAtlasFrames
	{
		var imagePath:String = isCharacter ? 'characters/$key' : key;
		var xmlPath:String = isCharacter ? 'images/characters/$key.xml' : 'images/$key.xml';

		var img:FlxGraphic = loadImage(imagePath, library);
		var xmlData:String = file(xmlPath, library);

		if (img == null || xmlData == null)
			return null;

		return FlxAtlasFrames.fromSparrow(img, xmlData);
	}

	public static function getPackerAtlas(key:String, ?library:String, isCharacter:Bool = false):FlxAtlasFrames
	{
		var imagePath:String = isCharacter ? 'characters/$key' : key;
		var txtPath:String = isCharacter ? 'images/characters/$key.txt' : 'images/$key.txt';

		var img:FlxGraphic = loadImage(imagePath, library);
		var txtData:String = file(txtPath, library);

		if (img == null || txtData == null)
			return null;

		return FlxAtlasFrames.fromSpriteSheetPacker(img, txtData);
	}

	public static function clearStoredMemory(?excludeKeyList:Array<String>):Void
	{
		if (excludeKeyList == null)
			excludeKeyList = [];

		for (path in graphicCache.keys())
		{
			if (excludeKeyList.indexOf(path) != -1)
				continue;

			var graphic:FlxGraphic = graphicCache.get(path);
			if (graphic != null)
			{
				FlxG.bitmap.remove(graphic);
				graphic.destroy();
			}

			graphicCache.remove(path);
		}

		for (path in soundCache.keys())
		{
			if (excludeKeyList.indexOf(path) != -1)
				continue;

			soundCache.remove(path);
		}
	}

	public static function clearUnusedGraphics():Void
	{
		for (path in graphicCache.keys())
		{
			var graphic:FlxGraphic = graphicCache.get(path);

			if (graphic == null || graphic.useCount <= 0)
			{
				if (graphic != null)
				{
					FlxG.bitmap.remove(graphic);
					graphic.destroy();
				}

				graphicCache.remove(path);
			}
		}
	}
}
