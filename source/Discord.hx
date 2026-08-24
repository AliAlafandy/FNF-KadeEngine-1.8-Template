package;

#if FEATURE_DISCORD
import Sys.sleep;
import discord_rpc.DiscordRpc;
import sys.thread.Thread;

using StringTools;

class DiscordClient
{
	public static var clientID:String = "557069829501091850";
	private static var isInitialized:Bool = false;

	public function new()
	{
		DiscordRpc.start({
			clientID: clientID,
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected
		});

		while (true)
		{
			DiscordRpc.process();
			sleep(2);
		}

		DiscordRpc.shutdown();
	}

	public static function initialize()
	{
		if (isInitialized) return;

		isInitialized = true;
		Thread.create(() ->
		{
			new DiscordClient();
		});
	}

	public static function shutdown()
	{
		if (!isInitialized) return;

		DiscordRpc.shutdown();
		isInitialized = false;
	}

	static function onReady()
	{
		DiscordRpc.presence({
			details: "In the Menus",
			state: null,
			largeImageKey: 'icon',
			largeImageText: "Friday Night Funkin'"
		});
	}

	static function onError(_code:Int, _message:String) {}

	static function onDisconnected(_code:Int, _message:String) {}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float)
	{
		var startTimestamp:Float = hasStartTimestamp ? Date.now().getTime() : 0;

		if (endTimestamp != null && endTimestamp > 0)
		{
			endTimestamp = startTimestamp + endTimestamp;
		}

		DiscordRpc.presence({
			details: details,
			state: state,
			largeImageKey: 'icon',
			largeImageText: "Friday Night Funkin'",
			smallImageKey: smallImageKey,
			startTimestamp: startTimestamp > 0 ? Std.int(startTimestamp / 1000) : null,
			endTimestamp: (endTimestamp != null && endTimestamp > 0) ? Std.int(endTimestamp / 1000) : null
		});
	}
}
#end
