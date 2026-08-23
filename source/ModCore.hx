#if FEATURE_MODCORE
import polymod.backends.OpenFLBackend;
import polymod.backends.PolymodAssets.PolymodAssetType;
import polymod.format.ParseRules.LinesParseFormat;
import polymod.format.ParseRules.TextFileFormat;
import polymod.Polymod;
import polymod.Polymod.PolymodError;
import polymod.Polymod.ModMetadata;
#end

#if mobile
import mobile.backend.StorageUtil;
#end

class ModCore
{
	static final API_VERSION = "0.1.0";

	static final MOD_DIRECTORY_NAME = "mods";

	static var initialized:Bool = false;

	#if FEATURE_MODCORE
	static var loadedModMetadata:Array<ModMetadata> = [];
	#end

	public static var modRoot(get, never):String;

	static function get_modRoot():String
	{
		#if mobile
		return StorageUtil.resolvePath(MOD_DIRECTORY_NAME);
		#else
		return MOD_DIRECTORY_NAME;
		#end
	}

	public static function initialize()
	{
		#if FEATURE_MODCORE
		if (initialized)
		{
			Debug.logWarn("ModCore already initialized, ignoring duplicate call.");
			return;
		}

		#if mobile
		StorageUtil.createDirectory(MOD_DIRECTORY_NAME);
		#end

		Debug.logInfo("Initializing ModCore...");
		loadModsById(getModIds());
		initialized = true;
		#else
		Debug.logInfo("ModCore not initialized; not supported on this platform.");
		#end
	}

	#if FEATURE_MODCORE
	public static function loadModsById(ids:Array<String>)
	{
		Debug.logInfo('Attempting to load ${ids.length} mods...');

		var loadedModList = Polymod.init({
			modRoot: modRoot,
			dirs: ids,
			framework: CUSTOM,
			apiVersion: API_VERSION,
			errorCallback: onPolymodError,
			frameworkParams: buildFrameworkParams(),
			customBackend: ModCoreBackend,
			ignoredFiles: Polymod.getDefaultIgnoreList(),
			parseRules: buildParseRules(),
		});

		if (loadedModList == null)
		{
			Debug.logError("Polymod failed to initialize; mods will not be active.");
			loadedModMetadata = [];
			return;
		}

		loadedModMetadata = loadedModList;

		Debug.logInfo('Mod loading complete. We loaded ${loadedModList.length} / ${ids.length} mods.');

		for (mod in loadedModList)
			Debug.logInfo('  * ${mod.title} v${mod.modVersion} [${mod.id}]');

		logReplacedAssets("IMAGE");
		logReplacedAssets("TEXT");
		logReplacedAssets("MUSIC");
		logReplacedAssets("SOUND");
	}

	static function logReplacedAssets(type:String):Void
	{
		var fileList = Polymod.listModFiles(type);
		Debug.logInfo('Installed mods have replaced ${fileList.length} $type files.');
	}

	public static function reload():Void
	{
		Debug.logInfo("Reloading mods...");
		unload();
		loadModsById(getModIds());
	}

	public static function unload():Void
	{
		if (!initialized)
			return;

		Polymod.clearCache();
		loadedModMetadata = [];
		Debug.logInfo("Mods unloaded.");
	}

	public static function getLoadedMods():Array<ModMetadata>
	{
		return loadedModMetadata;
	}

	public static function getAvailableMods():Array<ModMetadata>
	{
		return Polymod.scan(modRoot);
	}

	static function getModIds():Array<String>
	{
		Debug.logInfo('Scanning the mods folder at $modRoot...');
		var modMetadata = Polymod.scan(modRoot);
		Debug.logInfo('Found ${modMetadata.length} mods when scanning.');
		return [for (i in modMetadata) i.id];
	}

	static function buildParseRules():polymod.format.ParseRules
	{
		var output = polymod.format.ParseRules.getDefault();
		output.addType("txt", TextFileFormat.LINES);
		return output;
	}

	static inline function buildFrameworkParams():polymod.FrameworkParams
	{
		return {
			assetLibraryPaths: [
				"default" => "./preload",
				"sm" => "./sm",
				"songs" => "./songs",
				"shared" => "./",
				"tutorial" => "./tutorial",
				"week1" => "./week1",
				"week2" => "./week2",
				"week3" => "./week3",
				"week4" => "./week4",
				"week5" => "./week5",
				"week6" => "./week6"
			]
		}
	}

	static function onPolymodError(error:PolymodError):Void
	{
		switch (error.code)
		{
			case "missing_mod":
				Debug.logWarn('A mod folder listed for loading was not found: ${error.message}');
			case "missing_meta":
				Debug.logWarn('A mod is missing its _polymod_meta.json file: ${error.message}');
			case "missing_icon":
				Debug.logWarn('A mod is missing its icon file: ${error.message}');
			case "version_conflict_mod", "version_conflict_api":
				Debug.logError('Mod/API version mismatch: ${error.message}');
			case "framework_init", "failed_create_backend", "undefined_custom_backend":
				Debug.logError('Polymod failed to initialize the asset backend: ${error.message}');
			case "merge_error", "append_error":
				Debug.logWarn('Failed to merge a mod data file: ${error.message}');
			default:
				switch (error.severity)
				{
					case NOTICE:
						Debug.logInfo(error.message);
					case WARNING:
						Debug.logWarn(error.message);
					case ERROR:
						Debug.logError(error.message);
				}
		}
	}
	#end
}

#if FEATURE_MODCORE
class ModCoreBackend extends OpenFLBackend
{
	public function new()
	{
		super();
	}

	public override function clearCache()
	{
		super.clearCache();
	}

	public override function exists(id:String):Bool
	{
		return super.exists(id);
	}

	public override function getBytes(id:String):lime.utils.Bytes
	{
		return super.getBytes(id);
	}

	public override function getText(id:String):String
	{
		return super.getText(id);
	}

	public override function list(type:PolymodAssetType = null):Array<String>
	{
		return super.list(type);
	}
}
#end
