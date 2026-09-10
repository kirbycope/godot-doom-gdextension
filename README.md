![Preview](addons/godot_doom_gdextension/assets/godot-doom-gdextension.png)

# Godot Doom GDExtension

PureDOOM, the single-header port of the 1993 engine, as a GDExtension you can drop on any surface.

**[Read the full documentation](addons/godot_doom_gdextension/README.md)**, which ships with the addon so it is
there however you installed it.

## This repository

It uses the layout the [Godot Asset Library](https://docs.godotengine.org/en/stable/community/asset_library/submitting_to_assetlib.html) expects, so it is both the addon and a
project you can open and edit it in:

```
project.godot        the demo project, which is this repository
addons/godot_doom_gdextension/the addon itself
addons/gut/          the test runner
```

Clone it, open `project.godot` in Godot, and run the demo scene. The addon is mounted at
`res://addons/godot_doom_gdextension/` exactly as it is in a game, so it is edited in place with nothing
copied anywhere first. Installing through the Asset Library takes `addons/` and skips the root
`project.godot` as a conflict, which is why that file can live here harmlessly.

## Installing it in a game

Copy `addons/godot_doom_gdextension/` into your project's `addons/`. See the
[addon's README](addons/godot_doom_gdextension/README.md) for what it needs and how to use it.
