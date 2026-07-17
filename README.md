# Union 1.0m Linux patch kit

Drop this directory anywhere, then apply it from the root of an old Union 1.0m
plugin repository:

```fish
fish /path/to/union-1.0m-linux-kit/install.fish
```

Or point it at another repository and an exact project:

```fish
fish /path/to/union-1.0m-linux-kit/install.fish \
  --project PluginDirectory/PluginName.vcxproj \
  /path/to/repository
```

## Required Union SDK

This kit expects the Union 1.0m SDK at `~/my_msvc/opt/Union/1.0m`. A
ready-to-use SDK archive with the required Linux compatibility corrections
already applied will be available from this repository's GitHub Releases page.
Extract it so that the directory above exists; no manual SDK patching is
required.

The installer expects exactly one Union 1.0m `.vcxproj` unless `--project` is
provided. It refuses to overwrite existing integration files. Use `--force`
only after reviewing those files.

It performs four jobs:

1. applies the idempotent Linux portability corrections described in
   `patches/README.md` directly to the bundled project `UnionAfx.h` and ZenGin
   template files;
2. installs a generic CMake build that reads real `.cpp` and `.rc` inputs from
   the `.vcxproj`, filters ZenGin generated sources to the engines selected by
   the preset, and matches the Visual Studio release/LTCG settings;
3. reads source fragments from `Sources.h` and gives each a standalone
   IntelliSense compile command without compiling it into the DLL twice, with
   its engine context derived from the configured preset;
4. installs all msvc-wine, CMake preset, clangd, and VS Code configuration and
   makes clangd's ignored root `compile_commands.json` and cpptools' ignored
   active-engine header follow whichever real preset was configured most
   recently.

After applying:

```fish
cmake --preset MP-x4-MT-Release-msvc-wine
cmake --build --preset MP-x4-MT-Release-msvc-wine
```

Read the generated `UNION_1.0M_LINUX.md` inside the plugin repository for the
full build, IntelliSense, custom-library, and source-control notes.

The installed Union headers below `~/my_msvc/opt/Union/1.0m` are referenced
directly and never copied or modified. The project-local template corrections
are intentional source changes.
