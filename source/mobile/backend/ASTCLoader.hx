package mobile.backend;

import haxe.io.Bytes;

#if lime_opengl
import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLTexture;
#end

typedef ASTCHeader =
{
	blockWidth:Int,
	blockHeight:Int,
	blockDepth:Int,
	width:Int,
	height:Int,
	depth:Int,
	dataOffset:Int
}

class ASTCLoader
{
	inline static var MAGIC:Int = 0x5CA1AB13;

	inline static var HEADER_SIZE:Int = 16;

	static var FORMAT_TABLE:Map<String, Int> = [
		'4x4' => 0x93B0,
		'5x4' => 0x93B1,
		'5x5' => 0x93B2,
		'6x5' => 0x93B3,
		'6x6' => 0x93B4,
		'8x5' => 0x93B5,
		'8x6' => 0x93B6,
		'8x8' => 0x93B7,
		'10x5' => 0x93B8,
		'10x6' => 0x93B9,
		'10x8' => 0x93BA,
		'10x10' => 0x93BB,
		'12x10' => 0x93BC,
		'12x12' => 0x93BD
	];

	public static function parseHeader(bytes:Bytes):ASTCHeader
	{
		if (bytes == null || bytes.length < HEADER_SIZE)
			return null;

		var magic:Int = bytes.get(0) | (bytes.get(1) << 8) | (bytes.get(2) << 16) | (bytes.get(3) << 24);

		if (magic != MAGIC)
			return null;

		var blockWidth:Int = bytes.get(4);
		var blockHeight:Int = bytes.get(5);
		var blockDepth:Int = bytes.get(6);

		var width:Int = bytes.get(7) | (bytes.get(8) << 8) | (bytes.get(9) << 16);
		var height:Int = bytes.get(10) | (bytes.get(11) << 8) | (bytes.get(12) << 16);
		var depth:Int = bytes.get(13) | (bytes.get(14) << 8) | (bytes.get(15) << 16);

		return {
			blockWidth: blockWidth,
			blockHeight: blockHeight,
			blockDepth: blockDepth,
			width: width,
			height: height,
			depth: depth,
			dataOffset: HEADER_SIZE
		};
	}

	inline static function formatKey(blockWidth:Int, blockHeight:Int):String
	{
		return '${blockWidth}x${blockHeight}';
	}

	public static function isSupported():Bool
	{
		#if lime_opengl
		if (GL.context == null)
			return false;

		var extensions:String = GL.getParameterString(GL.EXTENSIONS);

		return extensions != null && extensions.indexOf('texture_compression_astc') != -1;
		#else
		return false;
		#end
	}

	public static function uploadCompressedTexture(bytes:Bytes):GLTexture
	{
		#if lime_opengl
		var header = parseHeader(bytes);

		if (header == null)
		{
			Debug.logWarn('Invalid ASTC file: missing or incorrect magic number');
			return null;
		}

		if (header.blockDepth != 1 || header.depth != 1)
		{
			Debug.logWarn('3D ASTC textures are not supported');
			return null;
		}

		var key = formatKey(header.blockWidth, header.blockHeight);

		if (!FORMAT_TABLE.exists(key))
		{
			Debug.logWarn('Unsupported ASTC block size: $key');
			return null;
		}

		if (!isSupported())
		{
			Debug.logWarn('GPU/driver does not report ASTC texture compression support');
			return null;
		}

		var glFormat:Int = FORMAT_TABLE.get(key);

		var pixelData = bytes.sub(header.dataOffset, bytes.length - header.dataOffset);

		var texture:GLTexture = GL.createTexture();

		GL.bindTexture(GL.TEXTURE_2D, texture);
		GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
		GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
		GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
		GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);

		GL.compressedTexImage2D(GL.TEXTURE_2D, 0, glFormat, header.width, header.height, 0, pixelData);

		GL.bindTexture(GL.TEXTURE_2D, null);

		return texture;
		#else
		Debug.logWarn('ASTCLoader requires the lime_opengl target');
		return null;
		#end
	}

	public static function decode(bytes:Bytes):Dynamic
	{
		Debug.logWarn('ASTCLoader.decode is not implemented, use uploadCompressedTexture instead');
		return null;
	}
}
