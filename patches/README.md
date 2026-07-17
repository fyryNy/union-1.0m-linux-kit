# Portability patch

`apply-portability.cmake` is the patch payload used by the installer. It is
idempotent and intentionally uses semantic string replacements instead of a
fixed-context unified diff, because Union 1.0m template copies differ slightly
between projects.

At install time it modifies the project's bundled template files directly:

- converts every backslash in project-template `#include` paths to `/`;
- fixes known case-only ZenGin include mismatches;
- renames the G2A `zAIPlayer.h` file to `zAiPlayer.h` when required;
- fixes the invalid qualified nested-type declaration in `oNpc.h` files.

These corrections are intentional repository changes. The patch never writes
to the installed SDK below `~/my_msvc/opt/Union/1.0m`.
