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
## What is left here is the two things the addon leaves to the game. The keyboard key behind each action,
## so the HUD's keyboard art names the key [PureDoom] itself answers to and the button lights up when that
## key is pressed. And the one thing a touchscreen needs: turning a tap on one of the HUD's own buttons
## back into the joypad event the engine already understands, because [PureDoom] has a full pad mapping in
## C++ and a virtual pad therefore needs no new engine code.

## What each slot's action answers to besides the button it is drawn on, taken from the key table in
## [code]src/pure_doom.cpp[/code]. The addon registers these, so binding something here really does bind it.
##
## Only the face buttons and the d-pad are named. The addon already gives the sticks W/A/S/D and the arrow
## keys and the Start button Escape, which is what DOOM wants anyway.
##
## The d-pad is the automap, the menu and the weapons while playing. Its left and right arms cycle weapons,
## which on a keyboard is the number row instead, so those two carry [kbd]1[/kbd] and [kbd]7[/kbd]: the ends
## of the range, read across the pair as the "1 to 7" the manual gives.
const BINDINGS: Dictionary = {
	"button_0": {"keys": [KEY_SPACE]},
	"button_1": {"keys": [KEY_ENTER]},
	"button_2": {"keys": [KEY_CTRL]},
	"button_3": {"keys": [KEY_SHIFT]},
	"button_11": {"keys": [KEY_TAB]},
	# DOOM's own menu is on backquote, not Escape, so that a host scene can keep Escape for itself.
	"button_12": {"keys": [KEY_QUOTELEFT]},
	"button_13": {"keys": [KEY_1]},
	"button_14": {"keys": [KEY_7]},
}

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
	"button_13": {"button": JOY_BUTTON_DPAD_LEFT},
	"button_14": {"button": JOY_BUTTON_DPAD_RIGHT},
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
