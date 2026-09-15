![Preview](addons/godot_doom_gdextension/assets/godot-doom-gdextension.png)

# Godot Doom GDExtension

PureDOOM, the single-header port of the 1993 engine, as a GDExtension you can drop on any surface.

**[Read the full documentation](addons/godot_doom_gdextension/README.md)**, which ships with the addon so it is
there however you installed it.

## This repository

It uses the layout the [Godot Asset Library](https://docs.godotengine.org/en/stable/community/asset_library/submitting_to_assetlib.html) expects, so it is both the addon and a
project you can open and edit it in:

```
project.godot                   the demo project, which is this repository
addons/godot_doom_gdextension/  the addon itself
addons/controls/                the on-screen input hints
addons/midi/                    the SoundFont synthesiser for the music
addons/gut/                     the test runner
```

Clone it, open `project.godot` in Godot, and run the demo scene. The addon is mounted at
`res://addons/godot_doom_gdextension/` exactly as it is in a game, so it is edited in place with nothing copied
anywhere first. Installing through the Asset Library takes `addons/` and skips the root
`project.godot` as a conflict, which is why that file can live here harmlessly.

## Textures import Lossless

Every texture here imports with `compress/mode=0` (Lossless) and `detect_3d/compress_to=1`, so the
editor promotes one to VRAM Compressed the first time it sees it used in 3D. That is Godot's own
default.

This repository used to force `compress/mode=1` (Lossy) with promotion disabled, project wide. That
re-encoded every image through WebP at quality 0.7 before Godot saw it, and still uploaded
uncompressed to VRAM, so it lost real data and bought nothing at run time. It existed only to
squeeze a built `.pck` under GitHub's 100 MB limit, and nothing built is committed any more.

`python ../godot-3d-player-controller-v3/tools/texture_import_policy.py --root .` puts the
repository back on that policy, and `--check` reports without writing.

## Installing it in a game

Copy `addons/godot_doom_gdextension/` into your project's `addons/`. See the
[addon's README](addons/godot_doom_gdextension/README.md) for what it needs and how to use it.
