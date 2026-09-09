![Preview](./addons/godot_doom_gdextension/assets/godot-doom-gdextension.png)

# Godot Doom GDExtension

The real DOOM engine running inside Godot 4.8 as a GDExtension node. This repository is the Godot project
that builds, demos and tests the addon; the addon itself is `addons/godot_doom_gdextension/`, and that is the only folder
you copy into a game.

The engine is [PureDOOM](https://github.com/Daivuk/PureDOOM), Daivuk's single-header C port of the 1993 id
Software source with no OS layer of its own. The extension supplies its time, file, print and environment
callbacks, copies its 320x200 frame into an `ImageTexture` every tick, feeds its 11025 Hz sound into an
`AudioStreamGenerator`, sequences its music out as `InputEventMIDI`, and turns Godot input events into DOOM
key, button and mouse events. Everything runs in-process, so the same source builds for Windows, macOS and
the browser as a WebAssembly side module.

## Demo scene

`res://addons/godot_doom_gdextension/scenes/demo/demo.tscn` is the project's main scene. Run the project and DOOM boots
straight into E1M1 filling the window, with the controls card printed down each side and the music playing
through the bundled `gzdoom.sf2` SoundFont. Where the library is not built for your platform the screen says
so instead of failing.

WASD walks and strafes, the mouse turns, left click and Ctrl fire, Space uses, Shift runs, Tab is the
automap, 1 to 7 pick weapons and backquote (`) opens DOOM's menu. Pads are supported too; the full mapping
is in `addons/godot_doom_gdextension/README.md`.

DOOM turns on relative mouse motion, so the demo captures the cursor as it boots. Escape hands it back and
clicking in the window takes it again. On a web export the browser only grants pointer lock from inside a
user gesture, so the demo starts behind a "Click to start" screen and captures on that click; the
interstitial does not appear anywhere else.

## Installing into your own project

Copy `addons/godot_doom_gdextension/` into your project's `addons/` folder. Nothing needs enabling in Project Settings:
the `.gdextension` file registers the `PureDoom` node itself, and the GDScript uses `class_name`. Then:

```gdscript
var doom: Control = ClassDB.instantiate(&"PureDoom")
add_child(doom)
doom.call(&"start")
```

`ClassDB.class_exists(&"PureDoom")` tells you whether the library is built for the running platform, so a
scene can fall back to something else where it is not.

Music is optional. `addons/midi/` here is [Godot MIDI Player](https://bitbucket.org/arlez80/godot-midi-player-g4)
(MIT), bundled so the demo has sound; copy it across as well if you want DOOM's music, then connect the
node's `midi_message` signal to the player's `receive_raw_midi_message`. The addon works without it. On web,
also put the synthesiser's voices on `AudioServer.PLAYBACK_TYPE_STREAM`, or the browser's default sample
playback skips the bus chain the synthesiser mixes through and the music comes out silent; this project sets
`audio/general/default_playback_type.web` to `Stream` as well.

See `addons/godot_doom_gdextension/README.md` for the node's properties, signals, methods and the controls card.

## Building

Prebuilt Windows, macOS and web libraries are committed in `addons/godot_doom_gdextension/bin/`, so the demo runs from a
fresh clone. Rebuilding needs `godot-cpp` (git-ignored) and an `extension_api.json` dumped from the Godot
build you run, so the bindings match it:

```powershell
git clone --depth 1 https://github.com/godotengine/godot-cpp.git addons/godot_doom_gdextension/godot-cpp
& 'C:\Godot\godot.exe' --headless --dump-extension-api
cd addons/godot_doom_gdextension
scons platform=windows target=template_debug custom_api_file=..\..\extension_api.json
scons platform=windows target=template_release custom_api_file=..\..\extension_api.json
```

Windows needs Visual Studio 2022 with the C++ workload, Python and SCons; macOS needs `brew install scons`
and the Xcode Command Line Tools; the web build needs the Emscripten SDK on `PATH`. The macOS and web
command lines are in `addons/godot_doom_gdextension/README.md`.

## Tests

GUT covers the node and the controls card. Engine tests skip themselves where the library is not built.

```powershell
& 'C:\Godot\godot.exe' --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit
```

## Licensing

The wrapper in `addons/godot_doom_gdextension/src/`, the GDScript, scenes, resources and tests are MIT (`LICENSE`).

The bundled engine is not. `addons/godot_doom_gdextension/thirdparty/PureDOOM.h` is GPL 2.0, so the libraries in
`addons/godot_doom_gdextension/bin/` and anything you ship that links them are bound by that licence; its terms are in
`addons/godot_doom_gdextension/thirdparty/LICENSE`. `addons/godot_doom_gdextension/assets/doom1.wad` is id Software's freely
redistributable shareware IWAD. The full credits table is in `addons/godot_doom_gdextension/README.md`.
