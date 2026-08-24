package;

import flixel.FlxG;
import flixel.input.FlxInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionInputDigital;
import flixel.input.actions.FlxActionManager;
import flixel.input.actions.FlxActionSet;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.ui.FlxButton;

#if mobile
import mobile.util.TouchUtil;
import ui.FlxVirtualPad;
import ui.Hitbox;
#end

#if (haxe >= "4.0.0")
enum abstract Action(String) to String from String
{
	var UP = "up";
	var LEFT = "left";
	var RIGHT = "right";
	var DOWN = "down";
	var UP_P = "up-press";
	var LEFT_P = "left-press";
	var RIGHT_P = "right-press";
	var DOWN_P = "down-press";
	var UP_R = "up-release";
	var LEFT_R = "left-release";
	var RIGHT_R = "right-release";
	var DOWN_R = "down-release";
	var ACCEPT = "accept";
	var BACK = "back";
	var PAUSE = "pause";
	var RESET = "reset";
	var CHEAT = "cheat";
	var SIX = "six";
	var ONE = "one";
	var SEVEN = "seven";
}
#else
@:enum
abstract Action(String) to String from String
{
	var UP = "up";
	var LEFT = "left";
	var RIGHT = "right";
	var DOWN = "down";
	var UP_P = "up-press";
	var LEFT_P = "left-press";
	var RIGHT_P = "right-press";
	var DOWN_P = "down-press";
	var UP_R = "up-release";
	var LEFT_R = "left-release";
	var RIGHT_R = "right-release";
	var DOWN_R = "down-release";
	var ACCEPT = "accept";
	var BACK = "back";
	var PAUSE = "pause";
	var RESET = "reset";
	var CHEAT = "cheat";
	var SIX = "six";
	var ONE = "one";
	var SEVEN = "seven";
}
#end

enum Device
{
	Keys;
	Gamepad(id:Int);
	Touch;
}

enum Control
{
	UP;
	LEFT;
	RIGHT;
	DOWN;
	RESET;
	ACCEPT;
	BACK;
	PAUSE;
	CHEAT;
	SIX;
	ONE;
	SEVEN;
}

enum KeyboardScheme
{
	Solo;
	Duo(first:Bool);
	None;
	Custom;
}

class Controls extends FlxActionSet
{
	var _up = new FlxActionDigital(Action.UP);
	var _left = new FlxActionDigital(Action.LEFT);
	var _right = new FlxActionDigital(Action.RIGHT);
	var _down = new FlxActionDigital(Action.DOWN);
	var _upP = new FlxActionDigital(Action.UP_P);
	var _leftP = new FlxActionDigital(Action.LEFT_P);
	var _rightP = new FlxActionDigital(Action.RIGHT_P);
	var _downP = new FlxActionDigital(Action.DOWN_P);
	var _upR = new FlxActionDigital(Action.UP_R);
	var _leftR = new FlxActionDigital(Action.LEFT_R);
	var _rightR = new FlxActionDigital(Action.RIGHT_R);
	var _downR = new FlxActionDigital(Action.DOWN_R);
	var _accept = new FlxActionDigital(Action.ACCEPT);
	var _back = new FlxActionDigital(Action.BACK);
	var _pause = new FlxActionDigital(Action.PAUSE);
	var _reset = new FlxActionDigital(Action.RESET);
	var _cheat = new FlxActionDigital(Action.CHEAT);
	var _six = new FlxActionDigital(Action.SIX);
	var _one = new FlxActionDigital(Action.ONE);
	var _seven = new FlxActionDigital(Action.SEVEN);

	public var byName:Map<String, FlxActionDigital> = [];
	public var gamepadsAdded:Array<Int> = [];
	public var keyboardScheme = KeyboardScheme.None;
	public var trackedinputs:Array<FlxActionInput> = [];

	public var UP(get, never):Bool; inline function get_UP() return _up.check();
	public var LEFT(get, never):Bool; inline function get_LEFT() return _left.check();
	public var RIGHT(get, never):Bool; inline function get_RIGHT() return _right.check();
	public var DOWN(get, never):Bool; inline function get_DOWN() return _down.check();

	public var UP_P(get, never):Bool; inline function get_UP_P() return _upP.check();
	public var LEFT_P(get, never):Bool; inline function get_LEFT_P() return _leftP.check();
	public var RIGHT_P(get, never):Bool; inline function get_RIGHT_P() return _rightP.check();
	public var DOWN_P(get, never):Bool; inline function get_DOWN_P() return _downP.check();

	public var UP_R(get, never):Bool; inline function get_UP_R() return _upR.check();
	public var LEFT_R(get, never):Bool; inline function get_LEFT_R() return _leftR.check();
	public var RIGHT_R(get, never):Bool; inline function get_RIGHT_R() return _rightR.check();
	public var DOWN_R(get, never):Bool; inline function get_DOWN_R() return _downR.check();

	public var ACCEPT(get, never):Bool; inline function get_ACCEPT() return _accept.check();
	public var BACK(get, never):Bool; inline function get_BACK() return _back.check();
	public var PAUSE(get, never):Bool; inline function get_PAUSE() return _pause.check();
	public var RESET(get, never):Bool; inline function get_RESET() return _reset.check();
	public var CHEAT(get, never):Bool; inline function get_CHEAT() return _cheat.check();
	public var SIX(get, never):Bool; inline function get_SIX() return _six.check();
	public var ONE(get, never):Bool; inline function get_ONE() return _one.check();
	public var SEVEN(get, never):Bool; inline function get_SEVEN() return _seven.check();

	public function new(name, scheme = None)
	{
		super(name);

		var actions:Array<FlxActionDigital> = [
			_up, _left, _right, _down,
			_upP, _leftP, _rightP, _downP,
			_upR, _leftR, _rightR, _downR,
			_accept, _back, _pause, _reset, _cheat,
			_six, _one, _seven
		];

		for (action in actions)
		{
			add(action);
			byName[action.name] = action;
		}

		setKeyboardScheme(scheme, false);
	}

	override function update():Void
	{
		super.update();

		#if mobile
		updateTouchSwipes();
		#end
	}

	public function addbutton(action:FlxActionDigital, button:FlxButton, state:FlxInputState)
	{
		if (button == null) return;
		var input = new FlxActionInputDigitalIFlxInput(button, state);
		trackedinputs.push(input);
		action.add(input);
	}

	#if mobile
	public function setHitBox(hitbox:Hitbox)
	{
		if (hitbox == null) return;
		removeTouchInputs();

		inline forEachBound(Control.UP, (action, state) -> addbutton(action, hitbox.buttonUp, state));
		inline forEachBound(Control.DOWN, (action, state) -> addbutton(action, hitbox.buttonDown, state));
		inline forEachBound(Control.LEFT, (action, state) -> addbutton(action, hitbox.buttonLeft, state));
		inline forEachBound(Control.RIGHT, (action, state) -> addbutton(action, hitbox.buttonRight, state));
	}

	public function setVirtualPad(virtualPad:FlxVirtualPad, ?DPad:FlxDPadMode, ?Action:FlxActionMode)
	{
		if (virtualPad == null) return;
		removeTouchInputs();

		if (DPad == null) DPad = NONE;
		if (Action == null) Action = NONE;

		switch (DPad)
		{
			case UP_DOWN:
				inline forEachBound(Control.UP, (action, state) -> addbutton(action, virtualPad.buttonUp, state));
				inline forEachBound(Control.DOWN, (action, state) -> addbutton(action, virtualPad.buttonDown, state));
			case LEFT_RIGHT:
				inline forEachBound(Control.LEFT, (action, state) -> addbutton(action, virtualPad.buttonLeft, state));
				inline forEachBound(Control.RIGHT, (action, state) -> addbutton(action, virtualPad.buttonRight, state));
			case UP_LEFT_RIGHT:
				inline forEachBound(Control.UP, (action, state) -> addbutton(action, virtualPad.buttonUp, state));
				inline forEachBound(Control.LEFT, (action, state) -> addbutton(action, virtualPad.buttonLeft, state));
				inline forEachBound(Control.RIGHT, (action, state) -> addbutton(action, virtualPad.buttonRight, state));
			case FULL | RIGHT_FULL:
				inline forEachBound(Control.UP, (action, state) -> addbutton(action, virtualPad.buttonUp, state));
				inline forEachBound(Control.DOWN, (action, state) -> addbutton(action, virtualPad.buttonDown, state));
				inline forEachBound(Control.LEFT, (action, state) -> addbutton(action, virtualPad.buttonLeft, state));
				inline forEachBound(Control.RIGHT, (action, state) -> addbutton(action, virtualPad.buttonRight, state));
			case ANIMATION | NONE:
		}

		switch (Action)
		{
			case A:
				inline forEachBound(Control.ACCEPT, (action, state) -> addbutton(action, virtualPad.buttonA, state));
			case A_B:
				inline forEachBound(Control.ACCEPT, (action, state) -> addbutton(action, virtualPad.buttonA, state));
				inline forEachBound(Control.BACK, (action, state) -> addbutton(action, virtualPad.buttonB, state));
			case A_B_6:
				inline forEachBound(Control.ACCEPT, (action, state) -> addbutton(action, virtualPad.buttonA, state));
				inline forEachBound(Control.BACK, (action, state) -> addbutton(action, virtualPad.buttonB, state));
				inline forEachBound(Control.SIX, (action, state) -> addbutton(action, virtualPad.button6, state));
			case A_B_6_1:
				inline forEachBound(Control.ACCEPT, (action, state) -> addbutton(action, virtualPad.buttonA, state));
				inline forEachBound(Control.BACK, (action, state) -> addbutton(action, virtualPad.buttonB, state));
				inline forEachBound(Control.SIX, (action, state) -> addbutton(action, virtualPad.button6, state));
				inline forEachBound(Control.ONE, (action, state) -> addbutton(action, virtualPad.button1, state));
			case A_B_6_1_7:
				inline forEachBound(Control.ACCEPT, (action, state) -> addbutton(action, virtualPad.buttonA, state));
				inline forEachBound(Control.BACK, (action, state) -> addbutton(action, virtualPad.buttonB, state));
				inline forEachBound(Control.SIX, (action, state) -> addbutton(action, virtualPad.button6, state));
				inline forEachBound(Control.ONE, (action, state) -> addbutton(action, virtualPad.button1, state));
				inline forEachBound(Control.SEVEN, (action, state) -> addbutton(action, virtualPad.button7, state));
			case A_B_C:
				inline forEachBound(Control.ACCEPT, (action, state) -> addbutton(action, virtualPad.buttonA, state));
				inline forEachBound(Control.BACK, (action, state) -> addbutton(action, virtualPad.buttonB, state));
			case A_B_X_Y:
				inline forEachBound(Control.ACCEPT, (action, state) -> addbutton(action, virtualPad.buttonA, state));
				inline forEachBound(Control.BACK, (action, state) -> addbutton(action, virtualPad.buttonB, state));
			case STAGE | SONGD | ANIMATION | NONE:
		}
	}

	private function updateTouchSwipes():Void
	{
		var dir:SwipeDirection = TouchUtil.getSwipeDirection();
		if (dir == NONE) return;

		switch (dir)
		{
			case UP: _upP.trigger();
			case DOWN: _downP.trigger();
			case LEFT: _leftP.trigger();
			case RIGHT: _rightP.trigger();
			case NONE:
		}
	}
	#end

	public function removeTouchInputs():Void
	{
		for (input in trackedinputs)
		{
			for (action in digitalActions)
				action.remove(input);
		}
		trackedinputs = [];
	}

	public function loadKeyBinds()
	{
		removeKeyboard();
		if (gamepadsAdded.length != 0)
			removeGamepad();

		KeyBinds.keyCheck();

		if (KeyBinds.gamepad)
		{
			var buttons = new Map<Control, Array<FlxGamepadInputID>>();
			buttons.set(Control.UP, [FlxGamepadInputID.fromString(FlxG.save.data.upBind)]);
			buttons.set(Control.LEFT, [FlxGamepadInputID.fromString(FlxG.save.data.leftBind)]);
			buttons.set(Control.DOWN, [FlxGamepadInputID.fromString(FlxG.save.data.downBind)]);
			buttons.set(Control.RIGHT, [FlxGamepadInputID.fromString(FlxG.save.data.rightBind)]);
			buttons.set(Control.ACCEPT, [FlxGamepadInputID.A]);
			buttons.set(Control.BACK, [FlxGamepadInputID.B]);
			buttons.set(Control.PAUSE, [FlxGamepadInputID.fromString(FlxG.save.data.pauseBind)]);

			addGamepad(0, buttons);
		}

		inline bindKeys(Control.UP, [FlxKey.fromString(FlxG.save.data.upBind), FlxKey.UP]);
		inline bindKeys(Control.DOWN, [FlxKey.fromString(FlxG.save.data.downBind), FlxKey.DOWN]);
		inline bindKeys(Control.LEFT, [FlxKey.fromString(FlxG.save.data.leftBind), FlxKey.LEFT]);
		inline bindKeys(Control.RIGHT, [FlxKey.fromString(FlxG.save.data.rightBind), FlxKey.RIGHT]);
		inline bindKeys(Control.ACCEPT, [Z, SPACE, ENTER]);
		inline bindKeys(Control.BACK, [BACKSPACE, ESCAPE]);
		inline bindKeys(Control.PAUSE, [FlxKey.fromString(FlxG.save.data.pauseBind)]);
		inline bindKeys(Control.RESET, [FlxKey.fromString(FlxG.save.data.resetBind)]);

		FlxG.sound.muteKeys = [FlxKey.fromString(FlxG.save.data.muteBind)];
		FlxG.sound.volumeDownKeys = [FlxKey.fromString(FlxG.save.data.volDownBind)];
		FlxG.sound.volumeUpKeys = [FlxKey.fromString(FlxG.save.data.volUpBind)];
	}

	public function setKeyboardScheme(scheme:KeyboardScheme, reset = true)
	{
		loadKeyBinds();
	}

	function forEachBound(control:Control, func:FlxActionDigital->FlxInputState->Void)
	{
		switch (control)
		{
			case UP:
				func(_up, PRESSED); func(_upP, JUST_PRESSED); func(_upR, JUST_RELEASED);
			case LEFT:
				func(_left, PRESSED); func(_leftP, JUST_PRESSED); func(_leftR, JUST_RELEASED);
			case RIGHT:
				func(_right, PRESSED); func(_rightP, JUST_PRESSED); func(_rightR, JUST_RELEASED);
			case DOWN:
				func(_down, PRESSED); func(_downP, JUST_PRESSED); func(_downR, JUST_RELEASED);
			case ACCEPT: func(_accept, JUST_PRESSED);
			case BACK: func(_back, JUST_PRESSED);
			case PAUSE: func(_pause, JUST_PRESSED);
			case RESET: func(_reset, JUST_PRESSED);
			case CHEAT: func(_cheat, JUST_PRESSED);
			case SIX: func(_six, JUST_PRESSED);
			case ONE: func(_one, JUST_PRESSED);
			case SEVEN: func(_seven, JUST_PRESSED);
		}
	}

	public function bindKeys(control:Control, keys:Array<FlxKey>)
	{
		inline forEachBound(control, (action, state) -> addKeys(action, keys, state));
	}

	public function unbindKeys(control:Control, keys:Array<FlxKey>)
	{
		inline forEachBound(control, (action, _) -> removeKeys(action, keys));
	}

	inline static function addKeys(action:FlxActionDigital, keys:Array<FlxKey>, state:FlxInputState)
	{
		for (key in keys)
			action.addKey(key, state);
	}

	static function removeKeys(action:FlxActionDigital, keys:Array<FlxKey>)
	{
		var i = action.inputs.length;
		while (i-- > 0)
		{
			var input = action.inputs[i];
			if (input.device == KEYBOARD && keys.indexOf(cast input.inputID) != -1)
				action.remove(input);
		}
	}

	function removeKeyboard()
	{
		for (action in this.digitalActions)
		{
			var i = action.inputs.length;
			while (i-- > 0)
			{
				var input = action.inputs[i];
				if (input.device == KEYBOARD)
					action.remove(input);
			}
		}
	}

	public function addGamepad(id:Int, ?buttonMap:Map<Control, Array<FlxGamepadInputID>>):Void
	{
		if (gamepadsAdded.contains(id))
			gamepadsAdded.remove(id);

		gamepadsAdded.push(id);

		if (buttonMap != null)
		{
			for (control => buttons in buttonMap)
				inline bindButtons(control, id, buttons);
		}
	}

	public function removeGamepad(deviceID:Int = FlxInputDeviceID.ALL):Void
	{
		for (action in this.digitalActions)
		{
			var i = action.inputs.length;
			while (i-- > 0)
			{
				var input = action.inputs[i];
				if (input.device == GAMEPAD && (deviceID == FlxInputDeviceID.ALL || input.deviceID == deviceID))
					action.remove(input);
			}
		}

		gamepadsAdded.remove(deviceID);
	}

	public function bindButtons(control:Control, id:Int, buttons:Array<FlxGamepadInputID>)
	{
		inline forEachBound(control, (action, state) -> addButtons(action, buttons, state, id));
	}

	public function unbindButtons(control:Control, gamepadID:Int, buttons:Array<FlxGamepadInputID>)
	{
		inline forEachBound(control, (action, _) -> removeButtons(action, gamepadID, buttons));
	}

	inline static function addButtons(action:FlxActionDigital, buttons:Array<FlxGamepadInputID>, state:FlxInputState, id:Int)
	{
		for (button in buttons)
			action.addGamepad(button, state, id);
	}

	static function removeButtons(action:FlxActionDigital, gamepadID:Int, buttons:Array<FlxGamepadInputID>)
	{
		var i = action.inputs.length;
		while (i-- > 0)
		{
			var input = action.inputs[i];
			if (isGamepad(input, gamepadID) && buttons.indexOf(cast input.inputID) != -1)
				action.remove(input);
		}
	}

	inline static function isGamepad(input:FlxActionInput, deviceID:Int)
	{
		return input.device == GAMEPAD && (deviceID == FlxInputDeviceID.ALL || input.deviceID == deviceID);
	}

	static function init():Void
	{
		var actions = new FlxActionManager();
		FlxG.inputs.add(actions);
	}
}
