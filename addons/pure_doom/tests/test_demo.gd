extends GutTest

## Purpose: The demo scene boots the engine full screen with the controls card, wires the music up when Godot
## MIDI Player is present, and says so instead of failing where the library is not built.

const DEMO_SCENE = preload("res://addons/pure_doom/scenes/demo/demo.tscn")

var demo: PureDoomDemo


func before_each() -> void:
	demo = DEMO_SCENE.instantiate() as PureDoomDemo
	add_child_autofree(demo)


func test_engine_fills_the_screen_and_the_card_shows() -> void:
	if not ClassDB.class_exists(&"PureDoom"):
		assert_true(demo.missing.visible, "Without the library the demo should say so")
		assert_null(demo.engine)
		pass_test("PureDoom is not built for this platform")
		return
	assert_not_null(demo.engine, "The demo should instantiate the PureDoom node")
	assert_eq(demo.engine.get_parent(), demo.screen, "It belongs in the aspect ratio container")
	assert_true(demo.engine.call(&"is_running"), "The demo boots straight into E1M1")
	assert_false(demo.missing.visible)
	assert_true(demo.overlay.visible, "The controls card shows beside the screen")
	assert_true("Fire" in demo.overlay.actions.text)


func test_music_is_wired_to_the_midi_player_when_it_is_installed() -> void:
	if not ClassDB.class_exists(&"PureDoom"):
		pass_test("PureDoom is not built for this platform")
		return
	if not ResourceLoader.exists(PureDoomDemo.MIDI_PLAYER_SCENE):
		assert_null(demo.midi_player, "Without Godot MIDI Player the demo runs silent")
		pass_test("Godot MIDI Player is not installed")
		return
	assert_not_null(demo.midi_player, "The SoundFont should bring up the MIDI player")
	assert_true(demo.engine.is_connected(&"midi_message", Callable(demo.midi_player, &"receive_raw_midi_message")))
	await wait_seconds(1.5)
	assert_gt(demo.midi_player.get_now_playing_polyphony(), 0, "E1M1's music should be sounding")


func test_the_engine_quitting_stops_the_music_and_reports_the_code() -> void:
	if not ClassDB.class_exists(&"PureDoom"):
		pass_test("PureDoom is not built for this platform")
		return
	demo._on_engine_exited(0)
	assert_true(demo.missing.visible)
	assert_true("code 0" in demo.missing.text, "The exit code should be reported on screen")
	assert_false(demo.engine.visible)
	assert_false(demo.overlay.visible)
