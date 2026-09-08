class_name PureDoomDemo
extends Control
## Runs the PureDoom GDExtension full screen with the controls card down each side and, when Godot MIDI
## Player is in the project, DOOM's music through the bundled SoundFont. Where the library is not built for
## the platform the screen says so instead.

const MIDI_PLAYER_SCENE: String = "res://addons/midi/MidiPlayer.tscn" ## Optional: no music without it.
const SOUNDFONT: String = "res://addons/pure_doom/assets/gzdoom.sf2"

var engine: Control ## The PureDoom node, null where the library is missing.
var midi_player: Node ## Synthesises the engine's music, null without Godot MIDI Player.

@onready var screen: Container = $Screen
@onready var missing: Label = $Missing
@onready var overlay: PureDoomControlsOverlay = $PureDoomControlsOverlay


func _ready() -> void:
	if not ClassDB.class_exists(&"PureDoom"):
		missing.show()
		return
	engine = ClassDB.instantiate(&"PureDoom") as Control
	engine.name = "PureDoom"
	engine.connect(&"exited", _on_engine_exited)
	screen.add_child(engine)
	_start_music()
	overlay.show()
	engine.call(&"start")


## Wires DOOM's 140 Hz MIDI stream into Godot MIDI Player when that addon is present.
func _start_music() -> void:
	if not ResourceLoader.exists(MIDI_PLAYER_SCENE):
		return
	midi_player = (load(MIDI_PLAYER_SCENE) as PackedScene).instantiate()
	midi_player.set(&"soundfont", SOUNDFONT)
	add_child(midi_player)
	engine.connect(&"midi_message", Callable(midi_player, &"receive_raw_midi_message"))


## DOOM quit itself (its menu's Quit Game, or an error), so say so and stop the music.
func _on_engine_exited(code: int) -> void:
	if is_instance_valid(midi_player):
		midi_player.call(&"stop")
	if is_instance_valid(engine):
		engine.hide()
	missing.text = "DOOM exited with code %d." % code
	missing.show()
	overlay.hide()
