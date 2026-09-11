class_name PureDoomControls
extends Controls
## The controls HUD for the DOOM demo: the [Controls] addon
## ([url]https://github.com/kirbycope/godot-controls[/url]) with DOOM's own actions on its slots.
##
## Everything this adds is the two things the addon leaves to the game. It gives each action the
## keyboard key or mouse button DOOM already answers to, so the HUD's keyboard art names something
## that really works. And it turns a tap on the on-screen pad back into the joypad event [PureDoom]
## reads, because a [TouchScreenButton] sends an [InputEventAction] and the engine's mapping is in
## C++, over real joypad events.
##
## The slots themselves are not set here. They are set in
## [code]scenes/pure_doom_controls.tscn[/code], an inherited scene, so which action sits on which
## button and what each one is called are inspector fields rather than lines of code.

## The keyboard key or mouse button behind each slot's action, so the HUD's own art names what DOOM
## takes. The engine reads the keyboard and mouse itself, so these bindings are for the HUD.
const BINDINGS: Dictionary = {
	"button_0": {"keys": [KEY_SPACE]},
	"button_1": {"keys": [KEY_ENTER]},
	"button_2": {"keys": [KEY_CTRL], "mouse": [MOUSE_BUTTON_LEFT]},
	"button_3": {"keys": [KEY_SHIFT]},
	"button_4": {"keys": [KEY_QUOTELEFT]},
	"button_6": {"keys": [KEY_ESCAPE]},
	"button_11": {"keys": [KEY_TAB]},
	"button_12": {"keys": [KEY_QUOTELEFT]},
	# The d-pad's left and right cycle weapons, which DOOM itself does on the number row rather than
	# through a previous and next key, so those two slots get the button and no key behind it.
	"axis_5_plus": {"mouse": [MOUSE_BUTTON_LEFT]},
	"move_up": {"keys": [KEY_W]},
	"move_down": {"keys": [KEY_S]},
	"move_left": {"keys": [KEY_A]},
	"move_right": {"keys": [KEY_D]},
	"look_left": {"keys": [KEY_LEFT]},
	"look_right": {"keys": [KEY_RIGHT]},
}

## The joypad event each slot's action stands for, so a tap on the on-screen pad reaches [PureDoom].
## A slot missing from here is one the pad does not send: the share button is the addon's own
## screenshot and never the game's.
const JOYPAD: Dictionary = {
	"button_0": JOY_BUTTON_A,
	"button_1": JOY_BUTTON_B,
	"button_2": JOY_BUTTON_X,
	"button_3": JOY_BUTTON_Y,
	"button_4": JOY_BUTTON_BACK,
	"button_11": JOY_BUTTON_DPAD_UP,
	"button_12": JOY_BUTTON_DPAD_DOWN,
	"button_13": JOY_BUTTON_DPAD_LEFT,
	"button_14": JOY_BUTTON_DPAD_RIGHT,
}

## The sticks and the trigger, which send axis events rather than buttons: the slot, its axis and
## which way it pushes.
const AXES: Dictionary = {
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"look_left": [JOY_AXIS_RIGHT_X, -1.0],
	"look_right": [JOY_AXIS_RIGHT_X, 1.0],
	# DOOM has no free look, so the engine ignores this axis. The slots are filled anyway: the addon
	# hides a stick whose vertical pair is blank, and the right stick is how the player turns.
	"look_up": [JOY_AXIS_RIGHT_Y, -1.0],
	"look_down": [JOY_AXIS_RIGHT_Y, 1.0],
	"axis_5_plus": [JOY_AXIS_TRIGGER_RIGHT, 1.0],
}

var _sent: Dictionary[int, float] = {} ## The last value sent per axis, so the engine hears only changes.


func _ready() -> void:
	# The addon registers extra_actions before it fills in the gaps itself, and a subclass sets them
	# here rather than from a parent, because a child is ready before whatever owns it.
	for slot: String in BINDINGS:
		var action: StringName = get(&"action_" + slot)
		if action != &"":
			extra_actions[String(action)] = BINDINGS[slot]
	super()
	set_process(visible and current_input_type == InputType.TOUCH)
	input_type_changed.connect(_on_input_type_changed)


func _on_input_type_changed(_input_type: InputType) -> void:
	set_process(visible and current_input_type == InputType.TOUCH)


## A [TouchScreenButton] sends an [InputEventAction] and nothing else does, so a real key or pad
## reaches [PureDoom] on its own and is never sent twice.
func _input(event: InputEvent) -> void:
	# The addon works out which device is in hand in its own _input, and everything it draws hangs
	# off that, so an override that forgets this leaves the HUD stuck on the art it started with.
	super(event)
	var action_event: InputEventAction = event as InputEventAction
	if action_event == null:
		return
	for slot: String in JOYPAD:
		if get(&"action_" + slot) != action_event.action:
			continue
		var button_event: InputEventJoypadButton = InputEventJoypadButton.new()
		button_event.button_index = JOYPAD[slot]
		button_event.pressed = action_event.pressed
		Input.parse_input_event(button_event)
		return


## The sticks and the trigger. Godot's [VirtualJoystick] presses its actions straight into the input
## state rather than sending an event, so they are the one thing here that has to be read rather than
## listened for. Reading only happens while the pad is on screen, which is only on touch, so a
## keyboard's W is never counted on top of the key press [PureDoom] already had.
func _process(_delta: float) -> void:
	for axis: int in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y,
			JOY_AXIS_TRIGGER_RIGHT]:
		var value: float = axis_value(axis)
		if is_equal_approx(value, _sent.get(axis, 0.0)):
			continue
		_sent[axis] = value
		var motion_event: InputEventJoypadMotion = InputEventJoypadMotion.new()
		motion_event.axis = axis
		motion_event.axis_value = value
		Input.parse_input_event(motion_event)


## How far an axis is pushed, from both of its directions at once, so letting go of one while the
## other is held leaves the stick pushed the other way rather than centred.
func axis_value(axis: int) -> float:
	var value: float = 0.0
	for slot: String in AXES:
		if AXES[slot][0] != axis:
			continue
		var action: StringName = get(&"action_" + slot)
		if action != &"" and InputMap.has_action(action):
			value += AXES[slot][1] * Input.get_action_strength(action)
	return clampf(value, -1.0, 1.0)
