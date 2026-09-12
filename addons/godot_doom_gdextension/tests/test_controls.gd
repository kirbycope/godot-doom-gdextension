extends GutTest

## Purpose: The DOOM HUD is the controls addon with DOOM's own actions on its slots. Its scene is the
## mapping, its labels name what each button does on every device alike, and the only code in it is the two
## things the addon leaves to a game: the keys PureDoom answers to, and turning a tap back into a pad press.

const CONTROLS_SCENE = preload("res://addons/godot_doom_gdextension/scenes/pure_doom_controls.tscn")

var controls: PureDoomControls


func before_each() -> void:
	controls = CONTROLS_SCENE.instantiate() as PureDoomControls
	add_child_autofree(controls)


func after_each() -> void:
	for action: StringName in [&"doom_move_up", &"doom_move_down", &"doom_move_left", &"doom_move_right"]:
		if InputMap.has_action(action):
			Input.action_release(action)


## The slots are inspector fields, not a table in a script, so the scene can be opened and read as the mapping.
func test_every_slot_names_an_action_the_engine_publishes() -> void:
	var catalog: ControlsInputCatalog = controls.input_catalog
	assert_not_null(catalog, "The HUD should offer the engine's own action list as its picker")
	for slot: String in controls.get_slot_actions():
		# The share button is the addon's own screenshot rather than a DOOM control, so it is the one slot
		# whose action the engine has never heard of.
		if slot == "button_15":
			continue
		var action: StringName = controls.get_slot_actions()[slot]
		assert_true(catalog.has_action(action), "%s names %s, which the catalog should know" % [slot, action])
	assert_eq(controls.action_button_2, &"doom_fire", "Fire is the left face button, as pure_doom.cpp has it")
	assert_eq(controls.action_button_11, &"doom_dpad_up", "and the automap is the d-pad's up arm")


## A label says what the button does. It is the art that changes per vendor, never the words, so the same
## label has to be right for a keyboard and for every pad.
func test_the_labels_name_the_function_and_not_the_device() -> void:
	var expected: Dictionary = {
		"joypad_button_0_label": "Use",
		"joypad_button_1_label": "Pick",
		"joypad_button_2_label": "Fire",
		"joypad_button_3_label": "Run",
		"joypad_button_11_label": "Automap",
		"joypad_button_12_label": "Menu",
		"joypad_button_6_label": "Leave",
	}
	for property: String in expected:
		assert_eq((controls.get(property) as Label).text, expected[property], property)
	assert_eq(controls.joypad_button_13_label.text, controls.joypad_button_14_label.text,
		"Both weapon arms do one thing, so they carry one word")


## The keys are registered on the actions, so the HUD's keyboard art tells the truth and a button lights up
## when its key is pressed rather than only when its pad button is.
func test_the_keys_doom_answers_to_are_bound_to_the_slots() -> void:
	var expected: Dictionary = {
		&"doom_fire": KEY_CTRL,
		&"doom_use": KEY_SPACE,
		&"doom_run": KEY_SHIFT,
		&"doom_confirm": KEY_ENTER,
		&"doom_dpad_up": KEY_TAB,
		&"doom_dpad_down": KEY_QUOTELEFT, # DOOM's menu is on backquote so a host can keep Escape
	}
	for action: StringName in expected:
		assert_true(InputMap.has_action(action), "%s should be registered" % action)
		var keys: Array = []
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				keys.append((event as InputEventKey).physical_keycode)
		assert_has(keys, expected[action], "%s should answer to its DOOM key" % action)


## A VirtualJoystick presses its action into the input state without sending an event, so the stick is read
## rather than listened for, and both of its directions are counted at once.
func test_the_stick_reads_as_one_axis_from_both_of_its_halves() -> void:
	Input.action_press(&"doom_move_up", 1.0)
	assert_almost_eq(controls.axis_value(JOY_AXIS_LEFT_Y), -1.0, 0.01, "Pushing up is the axis at -1")
	Input.action_press(&"doom_move_down", 1.0)
	assert_almost_eq(controls.axis_value(JOY_AXIS_LEFT_Y), 0.0, 0.01, "Both at once cancel out")
	Input.action_release(&"doom_move_up")
	assert_almost_eq(controls.axis_value(JOY_AXIS_LEFT_Y), 1.0, 0.01, "Letting go of one leaves the other")


## The keys in BINDINGS are on the same actions the sticks read, so counting them would hand DOOM a W it
## already had from the keyboard. Only a touchscreen has no other way in.
func test_only_a_touchscreen_is_turned_into_pad_events() -> void:
	controls.current_input_type = Controls.InputType.KEYBOARD_MOUSE
	Input.action_press(&"doom_move_up", 1.0)
	controls._process(0.016)
	assert_eq(controls._sent.size(), 0, "A keyboard reaches PureDoom on its own")

	controls.current_input_type = Controls.InputType.TOUCH
	controls._process(0.016)
	assert_almost_eq(controls._sent.get(JOY_AXIS_LEFT_Y, 0.0), -1.0, 0.01, "A thumb on the stick does not")


## Every button the engine reads has a pad event to send; the ones it does not read are left out rather than
## sending something DOOM would ignore.
func test_the_touch_table_covers_what_the_engine_reads() -> void:
	for slot: String in ["button_0", "button_1", "button_2", "button_3",
			"button_11", "button_12", "button_13", "button_14"]:
		assert_true(PureDoomControls.TOUCH_EVENTS.has(slot), "%s should send a pad button" % slot)
	for slot: String in ["button_9", "button_10", "axis_4_plus", "axis_5_plus", "button_15"]:
		assert_false(PureDoomControls.TOUCH_EVENTS.has(slot), "%s is not a DOOM control" % slot)
