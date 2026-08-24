package mobile.backend;

import lime.system.System;

#if sys
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
#end

using StringTools;

class StorageUtil
{
	public static var baseDirectory(get, never):String;

	static function get_baseDirectory():String
	{
		var dir:String = System.applicationStorageDirectory;

		if (dir == null || dir.length == 0)
			dir = './';

		return Path.addTrailingSlash(dir);
	}

	public static function resolvePath(relativePath:String):String
	{
		if (relativePath == null)
			relativePath = '';

		while (relativePath.startsWith('/') || relativePath.startsWith('\\'))
			relativePath = relativePath.substr(1);

		return Path.normalize(baseDirectory + relativePath);
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
		var directoryPath:String = Path.directory(relativeFilePath);

		if (directoryPath == null || directoryPath.length == 0 || directoryPath == '.')
			return true;

		return createDirectory(directoryPath);
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
		if (content == null)
			return false;

		if (!ensureDirectoryFor(relativePath))
			return false;

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

		if (!ensureDirectoryFor(relativePath))
			return false;

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
				var entries:Array<String> = FileSystem.readDirectory(path);
				for (entry in entries)
				{
					var entryRelative:String = Path.join([relativePath, entry]);
					var fullEntryPath:String = resolvePath(entryRelative);

					if (FileSystem.isDirectory(fullEntryPath))
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
