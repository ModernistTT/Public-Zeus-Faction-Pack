# PZFP Copilot Instructions

This is a single-file Arma 3 addon script (`PZFP.sqf`) providing Zeus (curator) modules for spawning factions, vehicles, units, and loadouts in Arma 3 missions.# PZFP Copilot Instructions
s

The script is not run using traditional methods (adding to mission scripts folder as .sqf file, using execvm in editor, etc.). Instead, it is designed to be copied and pasted into the INIT BOX of an object, saved as a custom composition and placed down in the Zeus editor.

**Formatting Rules**
1. Do not use the "//" method of creating comments. Use the 'comment "";' feature instead.
2. Indent only using single spaces, not tab indents. For every place to use a regular tab, use a single space instead.
3. Prefix all functions with the "PZFP_fnc" identifier, with the exception being the names of categories, subcategories, and modules.

**Zeus Integration**
The script uses displayCtrl and tooltips to create trees within Zeus interface, as well as their categories, subcategories, and modules. These are added to the existing displayCtrl's within the Zeus interface.

Functions to be run upon module placement are ordered by ID, and the function ID's are stored in the tooltip for each module. These are then run by an eventHandler that runs each time a module is placed in the Zeus editor, if the tooltip matches a known PZFP script.

**Faction Creation**

The standard format for creating an infantry unit in the script consists of two scripts. An AddLoadoutXXXX function, and a CreateXXXX function.

For the AddLoadoutXXXX functions:

~~~
 PZFP_fnc_blufor_FACTTIONABBREV_CATEGORY_AddLoadoutUNITNAME = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  comment "Add equipment here using addWeapon, addPrimaryWeaponItem, forceAddUniform, addBackpack, linkItem, etc.";
 };
~~~

For the CreateXXXX functions:
~~~
 PZFP_fnc_blufor_FACTIONABBREV_CATEGORY_CreateUNITNAME = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["A3UNITCLASSNAME", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_FACTIONABBREV_CATEGORY_AddLoadoutUNITNAME;
   [_unit] call PZFP_fnc_blufor_FACTIONIDENTITY_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };
~~~

Where FACTIONABBREV is the name or abbreviation for the faction (USA for United States Army, LDFAF for Livonian Defense Force Air Force, RUS for Russian Spetznaz, etc.); CATEGORY is the category of the unit (Men, Pilots, MenSOF, MaintenanceCrew, for example); UNITNAME is the unit's name/type (Rifleman, PlatoonLeader, JTAC, for example); A3UNITCLASSNAME is the object's classname in ArmA 3's CfgVehicles directory ("B_Soldier_F", for example); and FACTIONIDENTITY is just the prefix for the nationality of the unit (US for US Army/Air Force units, POL for Polish-speaking Livonian troops, IR for Iranian CSAT troops, etc).

The standard format for creating a vehicle in the script is:

~~~
 PZFP_fnc_blufor_FACTIONABBREV_CATEGORY_CreateVEHICLENAME = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["A3VEHICLECLASSNAME",_position,[],0,"NONE"];
  [
   _vehicle,
   ["A3VEHICLECOLOR",1],
   [A3VEHICLEPARAMS]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_FACTIONABBREV_Men_CreateCREWUNIT;
  _driver moveInDriver _vehicle;
  private _gunnerIFAPPLICABLE = [] call PZFP_fnc_blufor_FACTIONABBREV_Men_CreateCREWUNIT;
  _gunner moveInGunner _vehicle;
  private _commanderIFAPPLICABLE = [] call PZFP_fnc_blufor_FACTIONABBREV_Men_CreateCREWUNIT;
  _gunner moveInGunner _vehicle;

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };
~~~

Where FACTIONABBREV is the name or abbreviation for the faction (USA for United States Army, LDFAF for Livonian Defense Force Air Force, RUS for Russian Spetznaz, etc.); CATEGORY is the category of the unit (Cars, Drones, AntiAir, Turrets, for example); VEHICLENAME is the vehicle's nickname (Slammer instead of M2A4 Slammer, for example); A3VEHICLECLASSNAME is the object's classname in ArmA 3's CfgVehicles directory; A3VEHICLECOLOR is the camouflage/color of the vehicle, which can be randomized if need be; A3VEHICLEPARAMS are the vehicle's appearance settings; and CREWUNIT is simply Rifleman for light vehicles, Crewman for armored vehicles, HelicopterPilot/Crew for helicopters, FighterPilot/TransportPilot for aircraft, etc.

Finally, each unit or vehicle is registered in the Zeus interface in the following format:
~~~
 PZFP_blufor/opfor/indep/civ_FACTIONABBREV = [_FACTIONSIDE, "Full faction name to display in the Zeus interface goes here", [1,1,1,1]] call PZFP_fnc_addCategory;

 PZFP_blufor/opfor/indep/civ_FACTIONABBREV_CATEGORY = [_FACTIONSIDE, PZFP_blufor/opfor/indep/civ_FACTIONABBREV, "Full category name to display in the Zeus interface goes here", [1,1,1,1]] call PZFP_fnc_addSubCategory;
 PZFP_blufor/opfor/indep/civ_FACTIONABBREV_CATEGORY_VEHICLE/UNITNAME = [_FACTIONSIDE, PZFP_blufor/opfor/indep/civ_FACTIONABBREV, PZFP_blufor/opfor/indep/civ_FACTIONABBREV_CATEGORY, "Full unit or vehicle name to display in the Zeus interface goes here", "PZFP_fnc_blufor/opfor/indep/civ_FACTIONABBREV_CATEGORY_CreateUNIT/VEHICLENAME", [1,1,1,1]] call PZFP_fnc_addModule;
~~~

Where FACTIONABBREV and CATEGORY are the same as above; _FACTIONSIDE is either _blufor, _opfor, _indep, or _civ depending on the side of the faction; and UNIT/VEHICLENAME is the same name of the vehicle or unit from the CreateXXXX function.

**Unit/Vehicle Creation Procedure:**
1. Get the full name of the faction, and possibly the full names of the units/categories from the README.md file in the repo.
2. Analyze the file for any existing code that involves creating the same type of unit/vehicle
3. Gather the classnames of the specified unit/vehicles/equipment/objects from the ArmA 3 documentation
4. Create the skeleton creation classes (AddLoadoutXXXX, CreateXXXX, addModules, etc.)
5. Fill in the required object classnames, unit/vehicle configuration data (equipment, color/camo patterns, identity data, etc.), and faction abbreviations/names as specified
  5a. For AddLoadout functions in particular, if provided one, use the example/base loadout given to build the rest of the loadouts from, adding/removing/replacing weapons and equipment as needed to fit the unit type (if the base is a rifleman, replace the rifle with a machine gun for an autorifleman, or add a backpack and first aid kits/medikit for a medic, etc.)
6. Leave comments for unknown areas to be fixed later.

NOTE: Some units (RadioOperator, or Marshal for example) have classnames in ArmA 3 for blufor but not opfor versions. In that case, use the classname for whatever side has the type of unit we need, and then use joinSilent to make it join the needed faction. If I wanted to make a radio operator for opfor, recognizing that unit type only has a classname for blufor (B_W_RadioOperator_F), I would put that as the unit's classname, and then use [_unit] joinSilent createGroup [east, etc....]; to get it on the opfor side.

**Module Registration & Invocation**:
1. Modules are registered via `PZFP_fnc_addModule`, which stores function names in `missionNamespace` array `PZFP_moduleScripts` with numeric IDs (9000+).
2. Tree tooltips include `Function ID:NNNN` lines parsed by `PZFP_fnc_runModuleFromTree`.
3. When a Zeus user selects a module from the tree, `PZFP_fnc_executeModule` (hooked to `CuratorObjectPlaced` event) reads the tooltip, looks up the function name, and executes it with cursor position and object context.