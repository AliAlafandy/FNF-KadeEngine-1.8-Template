package mobile.backend;

import lime.system.System;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class StorageUtil
{
	public static var baseDirectory(get, never):String;

	static function get_baseDirectory():String
	{
		var dir:String = System.applicationStorageDirectory;

		if (dir == null || dir.length == 0)
			dir = './';

		if (!dir.endsWith('/') && !dir.endsWith('\\'))
			dir += '/';

		return dir;
	}

	public static function resolvePath(relativePath:String):String
	{
		if (relativePath == null)
			relativePath = '';

		if (relativePath.length > 0 && (relativePath.charAt(0) == '/' || relativePath.charAt(0) == '\\'))
			relativePath = relativePath.substr(1);

		return baseDirectory + relativePath;
	}

	public static function exists(relativePath:String):Bool
	{
		#if sys
		return FileSystem.exists(resolvePath(relativePath));
		#else
		return false;
		#end
	}

	public static function isDirectory(relativePath:String):Bool
	{
		#if sys
		var path:String = resolvePath(relativePath);
		return FileSystem.exists(path) && FileSystem.isDirectory(path);
		#else
		return false;
		#end
	}

	public static function createDirectory(relativePath:String):Bool
	{
		#if sys
		var path:String = resolvePath(relativePath);

		if (FileSystem.exists(path))
			return FileSystem.isDirectory(path);

		try
		{
			FileSystem.createDirectory(path);
			return true;
		}
		catch (e:Dynamic)
		{
			return false;
		}
		#else
		return false;
		#end
	}

	public static function ensureDirectoryFor(relativeFilePath:String):Bool
	{
		var slashIndex:Int = relativeFilePath.lastIndexOf('/');
		var backslashIndex:Int = relativeFilePath.lastIndexOf('\\');
		var cutIndex:Int = slashIndex > backslashIndex ? slashIndex : backslashIndex;

		if (cutIndex <= 0)
			return true;

		return createDirectory(relativeFilePath.substr(0, cutIndex));
	}

	public static function readString(relativePath:String, defaultValue:String = null):String
	{
		#if sys
		var path:String = resolvePath(relativePath);

		if (!FileSystem.exists(path) || FileSystem.isDirectory(path))
			return defaultValue;

		try
		{
			return File.getContent(path);
		}
		catch (e:Dynamic)
		{
			return defaultValue;
		}
		#else
		return defaultValue;
		#end
	}

	public static function writeString(relativePath:String, content:String):Bool
	{
		#if sys
		ensureDirectoryFor(relativePath);

		var path:String = resolvePath(relativePath);

		try
		{
			File.saveContent(path, content);
			return true;
		}
		catch (e:Dynamic)
		{
			return false;
		}
		#else
		return false;
		#end
	}

	public static function readBytes(relativePath:String):haxe.io.Bytes
	{
		#if sys
		var path:String = resolvePath(relativePath);

		if (!FileSystem.exists(path) || FileSystem.isDirectory(path))
			return null;

		try
		{
			return File.getBytes(path);
		}
		catch (e:Dynamic)
		{
			return null;
		}
		#else
		return null;
		#end
	}

	public static function writeBytes(relativePath:String, bytes:haxe.io.Bytes):Bool
	{
		#if sys
		if (bytes == null)
			return false;

		ensureDirectoryFor(relativePath);

		var path:String = resolvePath(relativePath);

		try
		{
			File.saveBytes(path, bytes);
			return true;
		}
		catch (e:Dynamic)
		{
			return false;
		}
		#else
		return false;
		#end
	}

	public static function deleteFile(relativePath:String):Bool
	{
		#if sys
		var path:String = resolvePath(relativePath);

		if (!FileSystem.exists(path) || FileSystem.isDirectory(path))
			return false;

		try
		{
			FileSystem.deleteFile(path);
			return true;
		}
		catch (e:Dynamic)
		{
			return false;
		}
		#else
		return false;
		#end
	}

	public static function deleteDirectory(relativePath:String, recursive:Bool = true):Bool
	{
		#if sys
		var path:String = resolvePath(relativePath);

		if (!FileSystem.exists(path) || !FileSystem.isDirectory(path))
			return false;

		try
		{
			if (recursive)
			{
				for (entry in FileSystem.readDirectory(path))
				{
					var entryRelative:String = relativePath + '/' + entry;

					if (FileSystem.isDirectory(path + '/' + entry))
						deleteDirectory(entryRelative, true);
					else
						deleteFile(entryRelative);
				}
			}

			FileSystem.deleteDirectory(path);
			return true;
		}
		catch (e:Dynamic)
		{
			return false;
		}
		#else
		return false;
		#end
	}

	public static function listFiles(relativePath:String):Array<String>
	{
		#if sys
		var path:String = resolvePath(relativePath);

		if (!FileSystem.exists(path) || !FileSystem.isDirectory(path))
			return [];

		try
		{
			return FileSystem.readDirectory(path);
		}
		catch (e:Dynamic)
		{
			return [];
		}
		#else
		return [];
		#end
	}
}
