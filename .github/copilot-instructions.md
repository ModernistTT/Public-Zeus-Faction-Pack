This repository is a single-file Arma 3 addon script (SQF) named `PZFP.sqf` which provides curator (Zeus) modules for spawning vehicles, units, and loadouts.

Guiding principles for attending to this codebase
- Keep edits localized and minimal: the codebase is one long SQF script with many function literals. Prefer small, incremental changes (add or refactor individual functions) rather than wholesale reorganizations.
- Preserve function naming conventions: top-level functions use the `PZFP_fnc_` prefix and descriptive names (e.g. `PZFP_fnc_blufor_USAF_Men_AddLoadoutFighterPilot`). Follow the same prefix when adding new functions so runtime lookups (by string name) remain predictable.
- Do not change public IDs or hard-coded tooltip "Function ID:XXXX" lines unless you update the registration flow (`PZFP_fnc_registerModuleFunction`) consistently — modules are registered at runtime by adding entries to `missionNamespace` arrays.

Key files and patterns to reference
- `PZFP.sqf` — the single source of truth. It contains:
  - Initialization and curator event handlers (`PZFP_fnc_initialize`, `PZFP_fnc_executeModule`)
  - Tree menu helpers (tvAdd/tvSetData/tvSetTooltip usage)
  - Module registration mechanism (`PZFP_fnc_registerModuleFunction`, `PZFP_moduleScripts` in `missionNamespace`)
  - Many factory functions for creating vehicles/units and setting loadouts
  - Utility helpers like `PZFP_fnc_findCursorPosition`, `PZFP_fnc_vehicleCleanup`

Project-specific workflows and developer notes
- Runtime testing: This script runs inside Arma 3 as a Zeus module. There is no local build/test harness. To test changes:
  1. Place the updated `PZFP.sqf` into your mission folder (or mod) where the mission runtime will load it.
  2. Launch Arma 3, open the mission in editor, enter Zeus, and initialize the script (use existing in-mission init hooks or call `[] execVM "PZFP.sqf"` depending on how it's loaded).
- Debugging tips: the script uses `systemChat` for runtime logs. Add `systemChat format ["[PZFP DEBUG] %1", _var];` at strategic points. Avoid flooding with frequent logs inside loops.
- Data passing conventions: functions are registered and invoked via `missionNamespace` by string name, and some modules expect parameters from the cursor context (e.g., `curatorMouseOver`, `getMousePosition`) — preserve parameter order and usage when changing function signatures.

Common code conventions and gotchas
- Use `params [...]` at the top of function literals to declare expected args. Many factory functions assume a `params` array with either `_unit`, `_vehicle`, or none.
- Side effects are common: functions often create groups, call `getAssignedCuratorLogic player addCuratorEditableObjects`, attach event handlers, or use `remoteExec`. Ensure side-effects remain intentional and documented when modifying.
- Avoid renaming functions used via string lookups: the code stores function names in missionNamespace arrays and retrieves them by string at runtime. Renaming without updating registration will break module execution.
- When creating new modules, register them by calling `PZFP_fnc_registerModuleFunction` and ensure you call `tvSetTooltip` including `Function ID:` so `PZFP_fnc_runModuleFromTree` can parse it.

Small examples from the codebase
- Registering a module (pattern):
  - call `PZFP_fnc_addModule` which ends up calling `PZFP_fnc_registerModuleFunction` and sets a tooltip that includes `Function ID:<number>`.
- Parsing function IDs (pattern):
  - `PZFP_fnc_runModuleFromTree` reads `tvTooltip`, splits lines, and parses the last line `Function ID:NNNN` to look up the function name in `missionNamespace`.
- Cursor-to-world conversion:
  - `PZFP_fnc_findCursorPosition` chooses `ctrlMapScreenToWorld` when the map is visible, otherwise `screenToWorld`.

What to avoid
- Avoid reorganizing the file into multiple files unless you also adjust the mission loading and registration order — this repo relies on the single-file layout and runtime execution ordering.
- Avoid changing `displayCtrl` indices (e.g., 270–280) or tree structure semantics unless you update every tree helper; these are tied to the Zeus UI internals.

If you add features
- Add a brief comment above new function literals describing: purpose, expected params, side-effects, and whether they must be registered for Zeus.
- Register new modules with `PZFP_fnc_registerModuleFunction` and add a tooltip with `Function ID` so the menu system can call them.

If anything here is unclear or you'd like me to expand examples or add a short checklist for reviewers, tell me which areas to expand.