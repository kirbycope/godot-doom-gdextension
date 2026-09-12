class_name PureDoomControls
extends Controls
## The controls HUD for the DOOM demo: the [Controls] addon
## ([url]https://github.com/kirbycope/godot-controls[/url]) with DOOM's own actions on its slots.
##
## The slots are not set here. They are set in [code]scenes/pure_doom_controls.tscn[/code], an inherited
## scene, and picked from the list the engine publishes in
## [code]resources/pure_doom_inputs.tres[/code], so which action sits on which button and what each one is
## called are inspector fields. The scene is the mapping rather than a picture of one.
##
## Three things live here, all of them things the addon leaves to the game. The keyboard key behind each
## action, so the HUD's keyboard art names the key [PureDoom] itself answers to and the button lights up when
## that key is pressed. Turning a tap on one of the HUD's own buttons back into the joypad event the engine
## already understands, because [PureDoom] has a full pad mapping in C++ and a virtual pad therefore needs no
## new engine code. And weapon cycling, which is the one control DOOM has no key for.

## What each slot's action answers to besides the button it is drawn on, taken from the key table in
## [code]src/pure_doom.cpp[/code]. The addon registers these, so binding something here really does bind it.
##
## Only the face buttons and the d-pad are named. The addon already gives the sticks W/A/S/D and the arrow
## keys and the Start button Escape, which is what DOOM wants anyway.
##
## The d-pad is the automap, the menu and the weapons while playing. The weapon arms get the bracket keys,
## the ones an FPS has cycled weapons on since Quake. DOOM itself does not read them - it has no
## previous-or-next weapon key at all, only the seven numbers - so those two are this node's own, and what
## they do is walk to a slot and press its number.
const BINDINGS: Dictionary = {
	"button_0": {"keys": [KEY_SPACE]},
	"button_1": {"keys": [KEY_ENTER]},
	"button_2": {"keys": [KEY_CTRL]},
	"button_3": {"keys": [KEY_SHIFT]},
	"button_11": {"keys": [KEY_TAB]},
	# DOOM's own menu is on backquote, not Escape, so that a host scene can keep Escape for itself.
	"button_12": {"keys": [KEY_QUOTELEFT]},
	"button_13": {"keys": [KEY_BRACKETLEFT]},
	"button_14": {"keys": [KEY_BRACKETRIGHT]},
}

## How long the weapon number is held down. DOOM reads its input once per tic at 35 Hz, so a press and a
## release inside one frame can fall between two of them and never be seen at all.
const WEAPON_KEY_HELD: float = 0.08

## The highest weapon slot, and so how many steps a full circuit of them takes. 1 fist or chainsaw, 2 pistol,
## 3 shotgun, 4 chaingun, 5 rockets, 6 plasma, 7 BFG.
const WEAPON_SLOTS: int = 7

## The joypad event each slot stands for, so a tap on the HUD reaches the engine as the press it would have
## made on a real pad. A slot missing from here sends nothing: the shoulders and the triggers, which DOOM
## does not use, and the share button, which is the addon's own screenshot rather than a DOOM control.
const TOUCH_EVENTS: Dictionary = {
	"button_0": {"button": JOY_BUTTON_A},
	"button_1": {"button": JOY_BUTTON_B},
	"button_2": {"button": JOY_BUTTON_X},
	"button_3": {"button": JOY_BUTTON_Y},
	"button_11": {"button": JOY_BUTTON_DPAD_UP},
	"button_12": {"button": JOY_BUTTON_DPAD_DOWN},
	# The weapon arms are not here. DOOM has no previous-or-next weapon key for them to press, so they are
	# handled by walking the slots and pressing a number instead - see _cycle_weapons.
	"move_up": {"axis": JOY_AXIS_LEFT_Y, "value": -1.0},
	"move_down": {"axis": JOY_AXIS_LEFT_Y, "value": 1.0},
	"move_left": {"axis": JOY_AXIS_LEFT_X, "value": -1.0},
	"move_right": {"axis": JOY_AXIS_LEFT_X, "value": 1.0},
	"look_left": {"axis": JOY_AXIS_RIGHT_X, "value": -1.0},
	"look_right": {"axis": JOY_AXIS_RIGHT_X, "value": 1.0},
	# DOOM has no free look, so the engine ignores this axis. The slots are filled anyway: the addon hides a
	# stick whose vertical pair is blank, and the right stick is how the player turns.
	"look_up": {"axis": JOY_AXIS_RIGHT_Y, "value": -1.0},
	"look_down": {"axis": JOY_AXIS_RIGHT_Y, "value": 1.0},
}

## The joypad axes [constant TOUCH_EVENTS] fills, so [method _process] asks about no others.
const AXES: Array[int] = [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]

var _sent: Dictionary[int, float] = {} ## The last value handed to the engine per axis, so it hears only changes.

## The game to cycle weapons on, which is the one thing here that needs to know about [PureDoom] at all.
## Left null the HUD is only a HUD, and the weapon arms do nothing rather than erroring.
var game: Node:
	set(value):
		game = value
		_pressing = 0
		_release_in = 0.0

var _pressing: int = 0 ## The number key being held down for a weapon change, or 0.
var _release_in: float = 0.0 ## Seconds left to hold it.


func _ready() -> void:
	# The addon registers extra_actions before it fills in the gaps itself, and a subclass sets them here
	# rather than from a parent, because a child is ready before whatever owns it.
	for slot: String in BINDINGS:
		var action: StringName = get(&"action_" + slot)
		if action == &"":
			continue
		var key: String = String(action)
		extra_actions[key] = merge_bindings(extra_actions.get(key, {}), BINDINGS[slot])
	super()


## The HUD's own buttons. A [TouchScreenButton] sends an [InputEventAction], and nothing else does: a real
## key or pad reaches [PureDoom] on its own and must not be sent twice.
func _input(event: InputEvent) -> void:
	# The weapon numbers this node presses itself come back through here on their way to the engine. Nobody
	# reached for the keyboard, so they must not take a pad player's HUD away, and DEVICE_ID_EMULATION is how
	# Godot already marks an event no device made. Returning early only skips the HUD's own reading of it;
	# the event carries on to [PureDoom] regardless, which is the whole point of sending it.
	if event is InputEventKey and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	super(event)
	var action_event: InputEventAction = event as InputEventAction
	if action_event == null:
		return
	for slot: String in TOUCH_EVENTS:
		var binding: Dictionary = TOUCH_EVENTS[slot]
		if not binding.has("button") or get(&"action_" + slot) != action_event.action:
			continue
		var button_event: InputEventJoypadButton = InputEventJoypadButton.new()
		button_event.button_index = binding["button"]
		button_event.pressed = action_event.pressed
		Input.parse_input_event(button_event)
		return


## The sticks. Godot's [VirtualJoystick] presses its actions straight into the input state rather than
## sending an event, so these are the one thing here that has to be read rather than listened for.
##
## Only a touchscreen is read. A key or a real pad already reaches [PureDoom] on its own, and the keys in
## [constant BINDINGS] are bound to these same actions, so counting them here would send W twice.
func _process(delta: float) -> void:
	super(delta)
	_cycle_weapons(delta)
	if current_input_type != InputType.TOUCH:
		return
	for axis: int in AXES:
		var value: float = axis_value(axis)
		if is_equal_approx(value, _sent.get(axis, 0.0)):
			continue
		_sent[axis] = value
		var motion_event: InputEventJoypadMotion = InputEventJoypadMotion.new()
		motion_event.axis = axis
		motion_event.axis_value = value
		Input.parse_input_event(motion_event)


## How far an axis is pushed, from both of its directions at once, so letting go of one while the other is
## held leaves the stick pushed the other way rather than centred.
func axis_value(axis: int) -> float:
	var value: float = 0.0
	for slot: String in TOUCH_EVENTS:
		var binding: Dictionary = TOUCH_EVENTS[slot]
		if binding.get("axis", -1) != axis:
			continue
		var action: StringName = get(&"action_" + slot)
		if action == &"" or not InputMap.has_action(action):
			continue
		value += binding["value"] * Input.get_action_strength(action)
	return clampf(value, -1.0, 1.0)


## Changes weapon when the d-pad's left or right arm is pressed. DOOM has no previous-or-next weapon key of
## its own - only the seven numbers, and pressing the number of a weapon you are not carrying does nothing -
## so the stepping is done here: ask the engine what is in hand, walk to the next slot it says is owned, and
## press that number.
##
## The arms are polled rather than listened for because they have to work the same for a thumb, a key and a
## pad, and a [TouchScreenButton] presses its action into the input state without always sending an event.
func _cycle_weapons(delta: float) -> void:
	if _pressing != 0:
		_release_in -= delta
		if _release_in <= 0.0:
			_press_weapon_key(_pressing, false)
			_pressing = 0
		return
	if not is_instance_valid(game) or not game.has_method(&"is_weapon_owned"):
		return
	# With DOOM's menu up the numbers are the menu's, not the player's weapons, so the arms stay out of it.
	if game.has_method(&"is_menu_open") and game.call(&"is_menu_open"):
		return
	var direction: int = 0
	if _arm_just_pressed(action_button_13):
		direction = -1
	elif _arm_just_pressed(action_button_14):
		direction = 1
	if direction == 0:
		return
	var slot: int = next_weapon_slot(direction)
	if slot == 0:
		return
	_pressing = slot
	_release_in = WEAPON_KEY_HELD
	_press_weapon_key(slot, true)


## The slot of the next weapon in [param direction] the player is actually carrying, or 0 when they are
## carrying only the one already in hand and there is nothing to change to.
func next_weapon_slot(direction: int) -> int:
	var slot: int = game.call(&"get_weapon_slot")
	if slot < 1:
		return 0
	for _step: int in WEAPON_SLOTS - 1:
		slot = posmod(slot - 1 + direction, WEAPON_SLOTS) + 1
		if game.call(&"is_weapon_owned", slot):
			return slot
	return 0


func _arm_just_pressed(action: StringName) -> bool:
	return action != &"" and InputMap.has_action(action) and Input.is_action_just_pressed(action)


## Presses or lets go of a weapon slot's number key. It is a real key press because that is what the engine
## reads - the same event a player typing 4 would make - rather than anything private to this node.
func _press_weapon_key(slot: int, pressed: bool) -> void:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_1 + slot - 1
	key.physical_keycode = key.keycode
	key.pressed = pressed
	key.device = InputEvent.DEVICE_ID_EMULATION
	Input.parse_input_event(key)
