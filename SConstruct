#!/usr/bin/env python
# Builds the PureDoom GDExtension. From this folder:
#   scons platform=windows target=template_debug
#   scons platform=windows target=template_release
#   scons platform=web threads=no target=template_release   (needs the Emscripten SDK on PATH)
#
# godot-cpp master ships extension_api files only up to 4.7, so against a 4.8 build pass the API dumped
# from the engine you actually run:
#   godot --headless --dump-extension-api
#   scons platform=windows target=template_debug custom_api_file=extension_api.json
import os

env = SConscript("godot-cpp/SConstruct")

env.Append(CPPPATH=["src/", "addons/godot_doom_gdextension/thirdparty/"])
# The engine itself is C (pure_doom_impl.c); the node is C++.
sources = Glob("src/*.cpp") + Glob("src/*.c")

if env["platform"] == "macos":
    library = env.SharedLibrary(
        "addons/godot_doom_gdextension/bin/libpure_doom.{}.{}.framework/libpure_doom.{}.{}".format(
            env["platform"], env["target"], env["platform"], env["target"]
        ),
        source=sources,
    )
else:
    library = env.SharedLibrary(
        "addons/godot_doom_gdextension/bin/libpure_doom{}{}".format(env["suffix"], env["SHLIBSUFFIX"]),
        source=sources,
    )

Default(library)
