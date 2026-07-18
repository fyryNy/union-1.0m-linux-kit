# Union 1.0m Linux patch kit

This kit adds a CMake, msvc-wine, and IntelliSense setup to an old Visual
Studio-based Union 1.0m plugin project. The original Visual Studio project
remains usable.

## Prerequisites

- CMake 3.25 or newer, Ninja, Fish, Wine, and `clang-cl`;
- the VS Code Microsoft C/C++ extension and/or clangd for IntelliSense;
- [mstorsjo/msvc-wine](https://github.com/mstorsjo/msvc-wine), installed
  before using this kit.

Follow the upstream msvc-wine installation instructions and install its
generated toolchain at `~/my_msvc/opt/msvc`. The installer checks that exact
location for the MSVC compiler and Windows SDK. Add the toolchain's x86 binary
directory to `PATH` before using the kit:

```fish
fish_add_path ~/my_msvc/opt/msvc/bin/x86
```

`fish_add_path` persists the directory in Fish's universal variables, so new
shells will also inherit it. To change `PATH` only in the current shell instead,
run:

```fish
set -gx PATH ~/my_msvc/opt/msvc/bin/x86 $PATH
```

## Required Union SDK

This kit expects the Union 1.0m SDK at `~/my_msvc/opt/Union/1.0m`. A
ready-to-use SDK archive with the required Linux compatibility corrections
already applied will be available from this repository's GitHub Releases page.
Extract it so that the directory above exists; no manual SDK patching is
required.

## Usage

### 1. Download this kit

Download or clone this repository and keep it anywhere outside the plugin
repository. You do not need to copy the kit into every plugin.

For example, the kit could be located at:

```text
/home/you/tools/union-1.0m-linux-kit
```

### 2. Enter the plugin repository

Open a terminal and change to the root of the old plugin repository, not to the
Union SDK directory and not to this kit's directory:

```fish
cd /path/to/MyPluginRepository
find . -name '*.vcxproj'
```

The second command shows the Visual Studio projects below that directory.

### 3. Apply the kit

If the repository contains exactly one Union 1.0m plugin project, run:

```fish
fish /home/you/tools/union-1.0m-linux-kit/install.fish
```

The installer uses the current directory as the plugin repository root. If it
finds more than one matching `.vcxproj`, specify the correct one relative to
that root:

```fish
fish /home/you/tools/union-1.0m-linux-kit/install.fish \
  --project PluginDirectory/PluginName.vcxproj
```

You can also run it from anywhere by passing both the project and repository:

```fish
fish /home/you/tools/union-1.0m-linux-kit/install.fish \
  --project PluginDirectory/PluginName.vcxproj \
  /path/to/MyPluginRepository
```

The installer refuses to overwrite existing integration files. Use `--force`
only when updating a previous installation and only after reviewing your local
changes.

### 4. Review the installed changes

From the plugin repository root, inspect what was added or corrected:

```fish
git status --short
git diff
```

The CMake, VS Code, and clangd files are intentional additions. The installer
also applies required case and path-separator corrections directly to the
project's `UnionAfx.h` and ZenGin files.

### 5. Select a game preset and build

List all available presets:

```fish
cmake --list-presets
```

Then configure and build the preset for the required engine and runtime. For
example:

```fish
cmake --preset G2A-MT-Release-msvc-wine
cmake --build --preset G2A-MT-Release-msvc-wine
```

Use the same preset name in both commands. Configuring a preset also updates
IntelliSense for that engine; no hard-coded editor preset needs to be changed.
The resulting DLL is below `out/build/<preset>/bin/`.

### 6. Open the repository in VS Code

Open the plugin repository root as the workspace after configuring the desired
preset. The installed `.vscode` and `.clangd` files provide the MSVC, Windows
SDK, Union SDK, ZenGin, and active-engine context automatically.

If VS Code asks for a Microsoft C/C++ configuration, select
`Union 1.0m msvc-wine x86`. After changing presets, reset the C/C++ IntelliSense
database or reload the VS Code window so the language server rereads the active
configuration.

## What the installer does

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

Read the generated `UNION_1.0M_LINUX.md` inside the plugin repository for the
full build, IntelliSense, custom-library, and source-control notes.

The installed Union headers below `~/my_msvc/opt/Union/1.0m` are referenced
directly and never copied or modified. The project-local template corrections
are intentional source changes.
