# PZFP Copilot Instructions

This is a single-file Arma 3 addon script (`PZFP.sqf`) providing Zeus (curator) modules for spawning factions, vehicles, units, and loadouts in Arma 3 missions.

## Architecture & Big Picture

**Single-File Script Model**: The entire project is one 14,800+ line SQF file with nested function literals. All functions are defined in the global `missionNamespace` with a `PZFP_fnc_` prefix.

**Zeus Integration**: The script integrates with Arma 3's Zeus interface (display 312). Four tree controls (displayCtrl 270–273) represent four factions (BLUFOR, OPFOR, INDEP, CIVILIAN). Placing virtual units via Zeus cursor triggers module execution via an event handler.

**Module Registration & Invocation**:
1. Modules are registered via `PZFP_fnc_addModule`, which stores function names in `missionNamespace` array `PZFP_moduleScripts` with numeric IDs (9000+).
2. Tree tooltips include `Function ID:NNNN` lines parsed by `PZFP_fnc_runModuleFromTree`.
3. When a Zeus user selects a module from the tree, `PZFP_fnc_executeModule` (hooked to `CuratorObjectPlaced` event) reads the tooltip, looks up the function name, and executes it with cursor position and object context.

## Critical Naming & Registration

- **Function Prefix**: Always use `PZFP_fnc_` for top-level functions (e.g., `PZFP_fnc_blufor_USA_Men_AddLoadoutRifleman`).
- **Function ID Immutability**: Function IDs (9000+) in tooltips are hard-coded links to module execution. Never change them without updating the registration flow.
- **String-Based Lookup**: Functions are retrieved from `missionNamespace` by string name at runtime. Renaming a function breaks its module unless you update the registration.

## Code Style Constraints

- **Comments**: Only use `comment "";` syntax. Do NOT use `//` or `/* */` comments—they break the SQF init box parser.
- **Indentation**: Use single spaces only, never tabs.
- **Large Changes**: Avoid large refactors or reorganizations except when:
  - Explicitly asked to by the user
  - Creating a new faction/faction system (e.g., new country's units, vehicles, identity functions)
  - Adding substantial features like new vehicle categories or utility systems

## Key Patterns to Follow

**Vehicle Creation Pattern** (e.g., `PZFP_fnc_blufor_USA_APC_CreateMarshall`):
```sqf
PZFP_fnc_blufor_USA_APC_CreateMarshall = {
  private _position = [getMousePosition] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_APC_Wheeled_01_cannon_F", _position, [], 0, "NONE"];
  [_vehicle, ["Sand", 1], [...options...]] call BIS_fnc_initVehicle;
  
  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  
  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  
  [_vehicle] call PZFP_fnc_vehicleCleanup;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
};
```

**Cursor Position Resolution**: `PZFP_fnc_findCursorPosition` chooses `ctrlMapScreenToWorld` when map is visible, else `screenToWorld`. Always use this utility to resolve cursor clicks to world coordinates.

**Identity Assignment** (voices & faces): Faction-specific functions (e.g., `PZFP_fnc_blufor_USA_AddIdentity`) randomize speaker and face from faction-specific arrays. Replicate this pattern for new factions.

## Testing & Debugging

**No Local Test Harness**: Script runs only inside Arma 3 at runtime.
1. Copy updated `PZFP.sqf` to mission folder.
2. Launch Arma 3, open mission in editor, enter Zeus.
3. Execute script via in-mission init or `[] execVM "PZFP.sqf"`.

**Logging**: Use `systemChat format ["[PZFP DEBUG] %1", _var];` for debug output. Avoid logs in tight loops.

## Common Gotchas

- **`params` Declarations**: Every function literal should declare `params [...]` at the start to validate arguments.
- **Side Effects Are Pervasive**: Functions create groups, call `addCuratorEditableObjects`, set event handlers, and use `remoteExec`. Document these when modifying.
- **displayCtrl Indices**: Tree controls are hardcoded (270–273 for factions, 50 for map). Changing these breaks Zeus UI integration.
- **Closure Over Outer Scope**: Functions can access `_maindisplay`, `_curator`, etc. from the initialization scope.

## Adding New Features

**Principle: Keep changes localized and minimal.**

1. **New Module Function**: Write function with `PZFP_fnc_` prefix. Use `params` to declare args. Document side-effects.
2. **Register**: Call `PZFP_fnc_addModule [_tree, _category, _subcategory, "Label", "PZFP_fnc_yourFunction", _color];`
3. **Tree Tooltip**: Tooltip with `Function ID:NNNN` is auto-added by `PZFP_fnc_addModule`.

**Exception**: New factions and large feature additions (vehicles, categories, systems) may require edits across multiple sections. Always validate no duplicate code or registration conflicts arise.

## Supporting Files

- `Loadouts.txt`: Vehicle initialization examples (reference only).
- `utils/ObjectFinder.sqf`: Helper script to export nearby objects' relative positions and rotations.
- `README.md`: Faction tree structure and vehicle inventory (useful reference).
