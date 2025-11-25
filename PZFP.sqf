comment "PZFP - By Modernist";
comment "To run, Ctrl+C the code into the init box of an 'Invisible Helipad' in 3DEN, save the composition, and place the object in 
         the Zeus editor. Ensure edits are made with init rules (i.e. no comments using //, use 'comment' instead. No tabs, just 
         single spaces)";

PZFP_fnc_initialize = {
 if (isNull findDisplay 312) exitWith {
  systemChat "[PZFP] - For PZFP to function properly, you must place it from the Zeus interface!";
 };

 if ( missionNamespace getVariable ["PZFP_initialized", false] ) exitWith {
  systemChat "[PZFP] – PZFP is already initialized!";
 };

 systemChat "[PZFP] - Loading...";

 private _curator = getAssignedCuratorLogic player;
 private _maindisplay = findDisplay 312;
 private _control = _maindisplay displayCtrl 280;
 private _blufor  = _maindisplay displayCtrl 270;
 private _opfor   = _maindisplay displayCtrl 271;
 private _indep   = _maindisplay displayCtrl 272;
 private _civ     = _maindisplay displayCtrl 273;

 missionNamespace setVariable ["PZFP_AIStopEnabled", false];

 _curator addEventHandler ["CuratorObjectPlaced", {
  _this call PZFP_fnc_executeModule;
 }];

 PZFP_fnc_addTreeEventhandler =
 {
  {
   _x ctrlAddEventhandler ["TreeSelChanged", {
	params ["_control", "_path"];
	with uiNamespace do {
	 if (_path isEqualTo []) exitWith {};
	 PZFP_SelectionPath = _path;
	};
   }];
  } forEach [_blufor, _opfor, _indep, _civ];
 };

 PZFP_fnc_addCategory = {
  params ["_parentMenu", "_categoryName", "_textColor"];
  private _i = _parentMenu tvAdd [[], _categoryName];
  _parentMenu tvSetColor [[_i], _textColor];
  _i;
 };

 PZFP_fnc_addSubCategory = {
  params ["_parentMenu", "_parentCategory", "_categoryName", "_textColor"];
  private _pi = _parentMenu tvAdd [[_parentCategory], _categoryName];
  _parentMenu tvSetColor [[_pi], _textColor];
  _pi;
 };

 PZFP_fnc_addModule = {
  params ["_parentMenu", "_parentCategory", "_parentSubCategory", "_moduleText", "_moduleScript", "_textColor"];
  private _cindex = _parentMenu tvAdd [[_parentCategory, _parentSubCategory], _moduleText];
  private _path = [_parentCategory, _parentSubCategory, _cindex];
  private _vrType = switch _parentMenu do {
   case _blufor: {"B_Soldier_VR_F"};
   case _opfor: {"O_Soldier_VR_F"};
   case _indep: {"I_Soldier_VR_F"};
   case _civ: {"C_Soldier_VR_F"};
   default {"B_Soldier_VR_F"};
  };
  _parentMenu tvSetData [_path, _vrType];
  _parentMenu ctrlCommit 0;

  private _functionArray = missionNamespace getVariable ["PZFP_moduleScripts", []];
  private _functionArraySize = count _functionArray;
  private _functionIndex = 9000 + _functionArraySize;

  systemChat format ["[PZFP] - Adding module '%1' with script '%2'", _moduleText, _moduleScript];
  [_maindisplay, _parentMenu, _moduleText, _moduleScript, _functionIndex] call PZFP_fnc_registerModuleFunction;

  private _nl = toString[10];
  private _tooltip = format ["%1%2%2Function ID:%2%3", _moduleText, _nl, _functionIndex];
  _parentMenu tvSetTooltip [_path, _tooltip];

  _cindex
 };

 PZFP_fnc_registerModuleFunction = {
  params ["_display", "_treeControl", "_moduleName", "_functionName", "_functionIndex"];

  systemChat format ["[PZFP] - Registering function: %1 with ID: %2", _functionName, _functionIndex];

  _functionArray pushBack [_functionIndex, _functionName];
  missionNamespace setVariable ["PZFP_moduleScripts", _functionArray];

  private _test = missionNamespace getVariable "PZFP_moduleScripts";
  systemChat format ["[PZFP] - Current moduleScripts array: %1", str _test];
 };

 PZFP_fnc_executeModule = {
  params ["_curator","_entity"];

  private _etype = typeOf _entity;
  if (!(_etype in ["B_Soldier_VR_F","O_Soldier_VR_F","I_Soldier_VR_F","C_Soldier_VR_F","ModuleEmpty_F"])) exitWith {};

  _entity spawn {
   waitUntil { (findDisplay -1) isEqualTo displayNull };
   deleteVehicle _this;
  };

  private _path = uiNamespace getVariable ["PZFP_SelectionPath",[]];
  if (_path isEqualTo []) exitWith {};

  private _disp = findDisplay 312;
  private _tree = switch (_etype) do {
   case "B_Soldier_VR_F": { _disp displayCtrl 270 };
   case "O_Soldier_VR_F": { _disp displayCtrl 271 };
   case "I_Soldier_VR_F": { _disp displayCtrl 272 };
   case "C_Soldier_VR_F": { _disp displayCtrl 273 };
   default                { _disp displayCtrl 280 };
  };

  private _tip = _tree tvTooltip _path;
  if ((_tip find "Function ID:") == -1) exitWith {};

  [_tree,_path] call PZFP_fnc_runModuleFromTree;
 };

 PZFP_fnc_runModuleFromTree = {
  params ["_tree", "_path"];
  private _tooltip = _tree tvTooltip _path;
  private _tooltipArray = _tooltip splitString "\n";
  private _indexLine = _tooltipArray select (count _tooltipArray - 1);
  private _functionID = parseNumber (_indexLine splitString ":" select 1);

  if (_functionID in [-1,0]) exitWith { systemChat "[PZFP] - Invalid function ID resolved. Exiting." };

  private _functionName = "";
  {
   _x params ["_id", "_fn"];
   if (_id == _functionID) exitWith { _functionName = _fn };
  } forEach (missionNamespace getVariable ["PZFP_moduleScripts", []]);

  if (_functionName == "") exitWith {
   systemChat format ["[PZFP] - Unknown module function ID: %1", _functionID];
  };

  private _cursorObjArray = curatorMouseOver;
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;

  if (_cursorObjArray isEqualTo [] || (_cursorObjArray # 0) isEqualTo "") then {
   [objNull, _position] call (missionNamespace getVariable _functionName);
  } else {
   [_cursorObjArray # 1, _position] call (missionNamespace getVariable _functionName);
  };
 };

 PZFP_fnc_findCursorPosition = {
  params ["_cursorPos"];
  private _position = if (visibleMap) then {
   private _displayMap = findDisplay 312 displayCtrl 50;
   _displayMap ctrlMapScreenToWorld _cursorPos;
  } else {
   screenToWorld _cursorPos;
  };
  _position;
 };

 PZFP_fnc_declutterTrees = {
  {
   for '_n' from 0 to ((_maindisplay displayCtrl _x) tvCount []) do {
	(_maindisplay displayCtrl _x) tvCollapse [_n];
   };
  } forEach [270,271,272,273,274,275,276,277,278,280];
 };

  PZFP_fnc_vehicleCleanup = {
  params ["_vehicle"];
  _vehicle addEventhandler ["Killed", {
   params ["_vehicle"];
   {
    if (_x isKindOf "AllVehicles") then {
     {
      deleteVehicle _x;
     } forEach (crew _x);
    };
    deleteVehicle _x;
   } forEach (attachedObjects _vehicle);
  }];
  _vehicle addEventhandler ["Deleted", {
   params ["_vehicle"];
   {
    if (_x isKindOf "AllVehicles") then {
     {
      deleteVehicle _x;
     } forEach (crew _x);
    };
    deleteVehicle _x;
   } forEach (attachedObjects _vehicle);
  }];
 };


 PZFP_fnc_blufor_USA_AddIdentity = {
  params ["_unit"];
  private _voices = ["Male01ENG", "Male02ENG", "Male03ENG", "Male04ENG", "Male05ENG", "Male06ENG", "Male07ENG", "Male08ENG", "Male09ENG", "Male10ENG", "Male11ENG", "Male12ENG"];
  private _faces = [
   "WhiteHead_01","WhiteHead_02","WhiteHead_03","WhiteHead_04","WhiteHead_05",
   "WhiteHead_06","WhiteHead_07","WhiteHead_08","WhiteHead_09","WhiteHead_10",
   "WhiteHead_11","WhiteHead_12","WhiteHead_13","WhiteHead_14","WhiteHead_15",
   "WhiteHead_16","WhiteHead_17","WhiteHead_18","WhiteHead_19","WhiteHead_20",
   "WhiteHead_21","AfricanHead_01","AfricanHead_02","AfricanHead_03",
   "AsianHead_A3_01","AsianHead_A3_02","AsianHead_A3_03"
  ];

  _unit setSpeaker (selectRandom _voices);
  _unit setFace (selectRandom _faces);
 };

 PZFP_fnc_blufor_UK_AddIdentity = {
  params ["_unit"];
  private _voices = ["Male01ENGB", "Male02ENGB", "Male03ENGB", "Male04ENGB", "Male05ENGB"];
  private _faces = [
   "WhiteHead_01","WhiteHead_02","WhiteHead_03","WhiteHead_04","WhiteHead_05",
   "WhiteHead_06","WhiteHead_07","WhiteHead_08","WhiteHead_09","WhiteHead_10",
   "WhiteHead_11","WhiteHead_12","WhiteHead_13","WhiteHead_14","WhiteHead_15",
   "WhiteHead_16","WhiteHead_17","WhiteHead_18","WhiteHead_19","WhiteHead_20",
   "WhiteHead_21","AfricanHead_01","AfricanHead_02","AfricanHead_03",
   "AsianHead_A3_01","AsianHead_A3_02","AsianHead_A3_03"
  ];

  _unit setSpeaker (selectRandom _voices);
  _unit setFace (selectRandom _faces);
 };

 PZFP_fnc_blufor_GR_AddIdentity = {
  params ["_unit"];
  private _voices = ["Male01GRE","Male02GRE","Male03GRE","Male04GRE","Male05GRE","Male06GRE"];
  private _faces = [
   "GreekHead_A3_01","GreekHead_A3_02","GreekHead_A3_03","GreekHead_A3_04",
   "GreekHead_A3_05","GreekHead_A3_06","GreekHead_A3_07","GreekHead_A3_08",
   "GreekHead_A3_09","GreekHead_A3_10_sa"
  ];

  _unit setSpeaker (selectRandom _voices);
  _unit setFace (selectRandom _faces);
 };
 
 PZFP_fnc_blufor_PL_AddIdentity = {
  params ["_unit"];
  private _voices = ["Male01POL","Male02POL","Male03POL"];
  private _faces = ["LivonianHead_1","LivonianHead_2","LivonianHead_3","LivonianHead_4",
   "LivonianHead_5","LivonianHead_6","LivonianHead_7","LivonianHead_8","LivonianHead_9",
   "LivonianHead_10"
  ];

  _unit setSpeaker (selectRandom _voices);
  _unit setFace (selectRandom _faces);
 };

 PZFP_fnc_opfor_IR_AddIdentity = {
  params ["_unit"];
  private _voices = ["Male01PER","Male02PER","Male03PER"];
  private _faces = ["PersianHead_A3_01", "PersianHead_A3_02", "PersianHead_A3_03"];

  _unit setSpeaker (selectRandom _voices);
  _unit setFace (selectRandom _faces);
 };




 comment "------------------------------------------BLUFOR-----------------------------------------------";





 PZFP_fnc_blufor_USAF_Drones_CreateGreyhawk = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_UAV_02_dynamicLoadout_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew  _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USAF_Pilots_AddLoadoutFighterPilot = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_PilotCoveralls";

  _unit addItemToUniform "FirstAidKit";
  for "_i" from 1 to 3 do {_unit addItemToUniform "16Rnd_9x21_Mag";};
  _unit addItemToUniform "SmokeShellOrange";
  for "_i" from 1 to 2 do {_unit addItemToUniform "Chemlight_blue";};
  _unit addItemToUniform "B_IR_Grenade";
  _unit addItemToUniform "SmokeShell";
  _unit addItemToUniform "SmokeShellBlue";
  _unit addHeadgear "H_PilotHelmetFighter_B";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
 };

 PZFP_fnc_blufor_USAF_Pilots_AddLoadoutTransportPilot = {
  params ["_unit"];
  removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit;
  removeUniform _unit; removeVest _unit; removeBackpack _unit;
  removeHeadgear _unit; removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "optic_Holosight";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_TacVest_oli";
  _unit addHeadgear "H_PilotHelmetHeli_B";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";

  for "_i" from 1 to 4 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "B_IR_Grenade";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellOrange";
  _unit addItemToVest "SmokeShellYellow";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USAF_Pilots_CreateFighterPilot = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Fighter_Pilot_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USAF_Pilots_AddLoadoutFighterPilot;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USAF_Planes_CreateWipeout = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Plane_CAS_01_dynamicLoadout_F",_position,[],0,"NONE"];

  private _pilot = [] call PZFP_fnc_blufor_USAF_Pilots_CreateFighterPilot;
  _pilot moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_pilot] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USAF_Planes_CreateVTOL = {
  _vehicle = createVehicle ["B_T_VTOL_01_infantry_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Olive",1],
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_USAF_Pilots_CreateTransportPilot;
  _pilot moveInDriver _vehicle;
  private _copilot1 = [] call PZFP_fnc_blufor_USAF_Pilots_CreateTransportPilot;
  _copilot1 moveInTurret [_vehicle, [0]];
  private _copilot2 = [] call PZFP_fnc_blufor_USAF_Pilots_CreateTransportPilot;
  _copilot2 moveInTurret [_vehicle, [1]];
  private _copilot3 = [] call PZFP_fnc_blufor_USAF_Pilots_CreateTransportPilot;
  _copilot3 moveInTurret [_vehicle, [2]];

  private _group = createGroup [west, true];
  [_pilot,_copilot1,_copilot2,_copilot3] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USAF_Planes_CreateVTOLArmed = {
  _vehicle = createVehicle ["B_T_VTOL_01_Armed_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Olive",1],
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_USAF_Pilots_CreateTransportPilot;
  _pilot moveInDriver _vehicle;
  private _copilot1 = [] call PZFP_fnc_blufor_USAF_Pilots_CreateTransportPilot;
  _copilot1 moveInTurret [_vehicle, [0]];
  private _copilot2 = [] call PZFP_fnc_blufor_USAF_Pilots_CreateTransportPilot;
  _copilot2 moveInTurret [_vehicle, [1]];
  private _copilot3 = [] call PZFP_fnc_blufor_USAF_Pilots_CreateTransportPilot;
  _copilot3 moveInTurret [_vehicle, [2]];

  private _group = createGroup [west, true];
  [_pilot,_copilot1,_copilot2,_copilot3] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USAF_Planes_CreateVTOLVehicle = {
  _vehicle = createVehicle ["B_T_VTOL_01_Vehicle_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Olive",1],
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_USAF_Pilots_CreateTransportPilot;
  _pilot moveInDriver _vehicle;
  private _copilot1 = [] call PZFP_fnc_blufor_USAF_Pilots_CreateTransportPilot;
  _copilot1 moveInTurret [_vehicle, [0]];
  private _copilot2 = [] call PZFP_fnc_blufor_USAF_Pilots_CreateTransportPilot;
  _copilot2 moveInTurret [_vehicle, [1]];
  private _copilot3 = [] call PZFP_fnc_blufor_USAF_Pilots_CreateTransportPilot;
  _copilot3 moveInTurret [_vehicle, [2]];

  private _group = createGroup [west, true];
  [_pilot,_copilot1,_copilot2,_copilot3] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USAF_Pilots_CreateTransportPilot = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Pilot_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USAF_Pilots_AddLoadoutTransportPilot;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_AntiAir_CreateIFV6	= {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_APC_Tracked_01_AA_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Sand",1],
   ["showCamonetTurret",0,"showCamonetHull",0,"showBags",1]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _commander moveInCommander _vehicle;

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_APC_CreateAMV7MarshallMG = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_APC_Wheeled_01_cannon_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Sand",1],
   ["showBags",0,"showCamonetHull",0,"showCamonetTurret",0,"showSLATHull",0,"showSLATTurret",0]
  ] call BIS_fnc_initVehicle;
  private _allTurrets = _vehicle call BIS_fnc_allTurrets;
  [_vehicle, ["HideTurret",1]] remoteExec ['animate',0,true];
  [_vehicle, [[0],true]] remoteExec ['lockTurret',0,true];
  [_vehicle, [[0,0],true]] remoteExec ['lockTurret',0,true];
  [_vehicle] call PZFP_fnc_vehicleCleanup;

  _vehicle2 = createVehicle ["O_MRAP_02_hmg_F",position _vehicle,[],0,"NONE"];
  [
   _vehicle2,
   ["Hex",1],
   true
  ] call BIS_fnc_initVehicle;
  _vehicle2 attachTo [_vehicle,[-0.05,1.3,-0.276]];
  _vehicle2 lockDriver true;
  _vehicle2 lockCargo true;
  _vehicle2 lockInventory true;
  [_vehicle2, [0, ""]] remoteExec ['setObjectTexture',0,true];
  [_vehicle2, [1, ""]] remoteExec ['setObjectTexture',0,true];
  [_vehicle2, [2, "A3\data_f\vehicles\turret_co.paa"]] remoteExec ['setObjectTexture',0,true];

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle2;

  private _group = createGroup [west, true];
  [_driver, _gunner] joinSilent _group;
  _group addVehicle _vehicle2;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_APC_CreateAMV7Marshall = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_APC_Wheeled_01_cannon_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Sand",1],
   ["showBags",1,"showCamonetHull",0,"showCamonetTurret",0,"showSLATHull",0,"showSLATTurret",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _commander moveInCommander _vehicle;

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_APC_CreateCRV6Bobcat = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_APC_Tracked_01_CRV_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Sand",1],
   ["showAmmobox",selectRandom [0,1],"showWheels",1,"showCamonetHull",0,"showBags",selectRandom [0,1]]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _commander moveInCommander _vehicle;

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_APC_CreateIFV6cPanther = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_APC_Tracked_01_rcws_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Sand",1],
   ["showCamonetHull",0,"showBags",1]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _commander moveInCommander _vehicle;

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Artillery_CreateScorcher = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_MBT_01_Arty_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Sand",1],
   ["showCanisters",1,"showCamonetTurret",0,"showAmmobox",1,"showCamonetHull",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _commander moveInCommander _vehicle;

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Artillery_CreateSandstorm = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_MBT_01_mlrs_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Sand",1],
   ["showCamonetTurret",0,"showCamonetHull",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;

  private _group = createGroup [west, true];
  [_gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Boats_CreateAssaultBoat = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Boat_Transport_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Black",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Boats_CreateRescueBoat = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Lifeboat",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Rescue",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Boats_CreateRHIB = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_C_Boat_Transport_02_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Black",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Cars_CreateHEMTT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_mover_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Cars_CreateHEMTTAmmo = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_ammo_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Cars_CreateHEMTTBox = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_box_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Cars_CreateHEMTTCargo = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_cargo_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Cars_CreateHEMTTFlatbed = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_flatbed_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Cars_CreateHEMTTFuel = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_fuel_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Cars_CreateHEMTTMedical = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_medical_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Cars_CreateHEMTTRepair = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_repair_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Cars_CreateHEMTTTransport = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_transport_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Cars_CreateHEMTTCovered = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_covered_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Cars_CreateHunter = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_MRAP_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Cars_CreateHunterHMG = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_MRAP_01_hmg_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  private _group = createGroup [west, true];
  [_gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Cars_CreateHunterGMG = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_MRAP_01_gmg_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  private _group = createGroup [west, true];
  [_gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Drones_CreatePelican = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_UAV_06_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   ["lights_em_hide",0,"LED_lights_hide",1,"Inventory_door",0]
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Drones_CreatePelicanMedical = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_UAV_06_medical_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   ["lights_em_hide",0,"LED_lights_hide",1,"Inventory_door",0]
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Drones_CreateDarter = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_UAV_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Drones_CreatePelter = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_UGV_02_Demining_F",_position,[],0,"NONE"];

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Drones_CreateRoller = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_UGV_02_Science_F",_position,[],0,"NONE"];

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Drones_CreateStomper = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_UGV_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Drones_CreateStomper = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_UGV_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Drones_CreateStomperMG = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_UGV_01_RCWS_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Helicopters_CreatePawnee = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Heli_Light_01_dynamicloadout_F",_position,[],0,"NONE"];
  [
   _vehicle,
   nil,
   ["AddTread_Short",1,"AddTread",0]
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];

  private _group = createGroup [west, true];
  [_pilot, _copilot] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Helicopters_CreateBlackfoot = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Heli_Attack_01_dynamicloadout_F",_position,[],0,"NONE"];
  [
   _vehicle,
   nil,
   true
  ] call BIS_fnc_initVehicle;
  [_vehicle, [0, "A3\Air_F\Heli_Light_02\Data\heli_light_02_common_co.paa"]] remoteExec ['setObjectTexture',0,true];

  private _pilot = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];

  private _group = createGroup [west, true];
  [_pilot, _copilot] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Helicopters_CreateBlackfootStub = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Heli_Attack_01_pylons_dynamicloadout_F",_position,[],0,"NONE"];
  [
   _vehicle,
   nil,
   true
  ] call BIS_fnc_initVehicle;
  [_vehicle, [0, "A3\Air_F\Heli_Light_02\Data\heli_light_02_common_co.paa"]] remoteExec ['setObjectTexture',0,true];

  private _pilot = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];

  private _group = createGroup [west, true];
  [_pilot, _copilot] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Helicopters_CreateHuron = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Heli_Transport_03_Unarmed_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Green",1],
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  _vehicle lockCargo true;
  _vehicle setVariable ["doorsClosed", true];

  [_vehicle,
  ["<img image='\a3\ui_f\data\IGUI\Cfg\Actions\open_door_ca.paa'></image><t color='#32CD32'> Open Passenger Doors</t>",
   {
    params ["_target"];
    [_target, ["Door_L_source", 1]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_R_source", 1]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_rear_source", 1]] remoteExec ['animateDoor',0,true];
    _target lockCargo false;
    _target setVariable ["doorsClosed", false];
   },
   nil,
   2,
   true,
   false,
   "",
   "_target getVariable ['doorsClosed', true] == true",
   7,
   false,
   "",
   ""
  ]] remoteExec ['addAction',0,true];

  [_vehicle,
  ["<img image='\a3\ui_f\data\IGUI\Cfg\Actions\open_door_ca.paa'></image><t color='#32CD32'> Close Passenger Doors</t>",
   {
    params ["_target"];
    [_target, ["Door_L_source", 0]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_R_source", 0]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_rear_source", 0]] remoteExec ['animateDoor',0,true];
    _target lockCargo true;
    _target setVariable ["doorsClosed", true];
   },
   nil,
   2,
   true,
   false,
   "",
   "_target getVariable ['doorsClosed', false] == false",
   7,
   false,
   "",
   ""
  ]] remoteExec ['addAction',0,true];

  private _group = createGroup [west, true];
  [_pilot, _copilot] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Helicopters_CreateHuronArmed = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Heli_Transport_03_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Green",1],
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  private _crew1 = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterCrew;
  _crew1 moveInTurret [_vehicle, [1]];
  private _crew2 = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterCrew;
  _crew2 moveInTurret [_vehicle, [2]];
  _vehicle lockCargo true;
  _vehicle setVariable ["doorsClosed", true];

  [_vehicle,
  ["<img image='\a3\ui_f\data\IGUI\Cfg\Actions\open_door_ca.paa'></image><t color='#32CD32'> Open Passenger Doors</t>",
   {
    params ["_target"];
    [_target, ["Door_L_source", 1]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_R_source", 1]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_rear_source", 1]] remoteExec ['animateDoor',0,true];
    _target lockCargo false;
    _target setVariable ["doorsClosed", false];
   },
   nil,
   2,
   true,
   false,
   "",
   "_target getVariable ['doorsClosed', true] == true",
   7,
   false,
   "",
   ""
  ]] remoteExec ['addAction',0,true];

  [_vehicle,
  ["<img image='\a3\ui_f\data\IGUI\Cfg\Actions\open_door_ca.paa'></image><t color='#32CD32'> Close Passenger Doors</t>",
   {
    params ["_target"];
    [_target, ["Door_L_source", 0]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_R_source", 0]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_rear_source", 0]] remoteExec ['animateDoor',0,true];
    _target lockCargo true;
    _target setVariable ["doorsClosed", true];
   },
   nil,
   2,
   true,
   false,
   "",
   "_target getVariable ['doorsClosed', false] == false",
   7,
   false,
   "",
   ""
  ]] remoteExec ['addAction',0,true];

  private _group = createGroup [west, true];
  [_pilot, _copilot, _crew1, _crew2] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Helicopters_CreateHummingbird = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Heli_Light_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   nil,
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];

  private _group = createGroup [west, true];
  [_pilot, _copilot] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Helicopters_CreateGhosthawk = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Heli_Transport_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Black",1],
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  private _crew1 = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterCrew;
  _crew1 moveInTurret [_vehicle, [1]];
  private _crew2 = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterCrew;
  _crew2 moveInTurret [_vehicle, [2]];
  _vehicle lockCargo true;
  _vehicle setVariable ["doorsClosed", true];

  [_vehicle,
  ["<img image='\a3\ui_f\data\IGUI\Cfg\Actions\open_door_ca.paa'></image><t color='#32CD32'> Open Passenger Doors</t>",
   {
    params ["_target"];
    [_target, ["Door_L", 1]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_R", 1]] remoteExec ['animateDoor',0,true];
    _target lockCargo false;
    _target setVariable ["doorsClosed", false];
   },
   nil,
   2,
   true,
   false,
   "",
   "_target getVariable ['doorsClosed', true] == true",
   7,
   false,
   "",
   ""
  ]] remoteExec ['addAction',0,true];

  [_vehicle,
  ["<img image='\a3\ui_f\data\IGUI\Cfg\Actions\open_door_ca.paa'></image><t color='#32CD32'> Close Passenger Doors</t>",
   {
    params ["_target"];
    [_target, ["Door_L", 0]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_R", 0]] remoteExec ['animateDoor',0,true];
    _target lockCargo true;
    _target setVariable ["doorsClosed", true];
   },
   nil,
   2,
   true,
   false,
   "",
   "_target getVariable ['doorsClosed', false] == false",
   7,
   false,
   "",
   ""
  ]] remoteExec ['addAction',0,true];

  private _group = createGroup [west, true];
  [_pilot, _copilot, _crew1, _crew2] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Helicopters_CreateGhosthawkStub = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Heli_Transport_01_pylons_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Black",1],
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_USA_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  _vehicle lockCargo true;
  _vehicle setVariable ["doorsClosed", true];

  [_vehicle,
  ["<img image='\a3\ui_f\data\IGUI\Cfg\Actions\open_door_ca.paa'></image><t color='#32CD32'> Open Passenger Doors</t>",
   {
    params ["_target"];
    [_target, ["Door_L", 1]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_R", 1]] remoteExec ['animateDoor',0,true];
    _target lockCargo false;
    _target setVariable ["doorsClosed", false];
   },
   nil,
   2,
   true,
   false,
   "",
   "_target getVariable ['doorsClosed', true] == true",
   7,
   false,
   "",
   ""
  ]] remoteExec ['addAction',0,true];

  [_vehicle,
  ["<img image='\a3\ui_f\data\IGUI\Cfg\Actions\open_door_ca.paa'></image><t color='#32CD32'> Close Passenger Doors</t>",
   {
    params ["_target"];
    [_target, ["Door_L", 0]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_R", 0]] remoteExec ['animateDoor',0,true];
    _target lockCargo true;
    _target setVariable ["doorsClosed", true];
   },
   nil,
   2,
   true,
   false,
   "",
   "_target getVariable ['doorsClosed', false] == false",
   7,
   false,
   "",
   ""
  ]] remoteExec ['addAction',0,true];

  private _group = createGroup [west, true];
  [_pilot, _copilot] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutRifleman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_PlateCarrier1_rgr";
  _unit addHeadgear "H_HelmetB_snakeskin";
  _goggles = ["G_Tactical_Clear", "G_Tactical_Clear", "G_Tactical_Clear", "G_Combat", "G_Combat", "G_Combat", "G_Spectacles_Tinted", "G_Squares_Tinted", ""];
  _unit addGoggles selectRandom _goggles;

  _unit addItemToUniform "Wallet_ID";
	_unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";


  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutLAT = {
  params ["_unit"];
  removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit;
  removeUniform _unit; removeVest _unit; removeBackpack _unit;
  removeHeadgear _unit; removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "launch_MRAWS_sand_F";
  _unit addSecondaryWeaponItem "MRAWS_HEAT_F";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_PlateCarrier2_rgr";
  _unit addBackpack "B_Kitbag_mcamo";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "MRAWS_HEAT_F";};
  _unit addItemToBackpack "MRAWS_HE_F";

  _unit addHeadgear "H_HelmetB_snakeskin";
  _goggles = ["G_Tactical_Clear", "G_Tactical_Clear", "G_Tactical_Clear", "G_Combat", "G_Combat", "G_Combat", "G_Spectacles_Tinted", "G_Squares_Tinted", ""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutAT = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Aco";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "launch_NLAW_F";
  _unit addSecondaryWeaponItem "NLAW_F";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_PlateCarrier2_rgr";
  _unit addBackpack "B_Kitbag_mcamo";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToBackpack "NLAW_F";};

  _unit addHeadgear "H_HelmetB_snakeskin";
  _goggles = ["G_Tactical_Clear", "G_Tactical_Clear", "G_Tactical_Clear", "G_Combat", "G_Combat", "G_Combat", "G_Spectacles_Tinted", "G_Squares_Tinted", ""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutAutorifleman = {
  params ["_unit"];
  removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit;
  removeUniform _unit; removeVest _unit; removeBackpack _unit;
  removeHeadgear _unit; removeGoggles _unit;

  _unit addWeapon "LMG_Mk200_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "200Rnd_65x39_cased_Box";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_PlateCarrier2_rgr";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  _unit addItemToVest "200Rnd_65x39_cased_Box_Red";
  _unit addItemToVest "200Rnd_65x39_cased_Box_Tracer_Red";
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";

  _unit addHeadgear "H_HelmetB_snakeskin";
  _goggles = ["G_Tactical_Clear", "G_Tactical_Clear", "G_Tactical_Clear", "G_Combat", "G_Combat", "G_Combat", "G_Spectacles_Tinted", "G_Squares_Tinted", ""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutMarksman = {
  params ["_unit"];
  removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit;
  removeUniform _unit; removeVest _unit; removeBackpack _unit;
  removeHeadgear _unit; removeGoggles _unit;

  _unit addWeapon "arifle_MXM_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_black_mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_PlateCarrier1_rgr";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";

  _unit addHeadgear "H_HelmetB_snakeskin";
  _goggles = ["G_Tactical_Clear", "G_Tactical_Clear", "G_Tactical_Clear", "G_Combat", "G_Combat", "G_Combat", "G_Spectacles_Tinted", "G_Squares_Tinted", ""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutMachineGunner = {
  params ["_unit"];
  removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit;
  removeUniform _unit; removeVest _unit; removeBackpack _unit;
  removeHeadgear _unit; removeGoggles _unit;

  _unit addWeapon "MMG_02_camo_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "130Rnd_338_Mag";
  _unit addPrimaryWeaponItem "bipod_01_F_snd";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_PlateCarrier1_rgr";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 2 do {_unit addItemToVest "130Rnd_338_Mag";};

  _unit addHeadgear "H_HelmetB_snakeskin";
  _goggles = ["G_Tactical_Clear", "G_Tactical_Clear", "G_Tactical_Clear", "G_Combat", "G_Combat", "G_Combat", "G_Spectacles_Tinted", "G_Squares_Tinted", ""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutTeamLeader = {
  params ["_unit"];
  removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit;
  removeUniform _unit; removeVest _unit; removeBackpack _unit;
  removeHeadgear _unit; removeGoggles _unit;

  _unit addWeapon "arifle_MX_GL_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addPrimaryWeaponItem "1Rnd_HE_Grenade_shell";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_PlateCarrier1_rgr";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 5 do {_unit addItemToVest "1Rnd_HE_Grenade_shell";};
  _unit addItemToVest "UGL_FlareWhite_F";
  _unit addItemToVest "1Rnd_Smoke_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeRed_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeGreen_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeBlue_Grenade_shell";
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_Mag";};

  _unit addHeadgear "H_HelmetB_snakeskin";
  _goggles = ["G_Tactical_Clear", "G_Tactical_Clear", "G_Tactical_Clear", "G_Combat", "G_Combat", "G_Combat", "G_Spectacles_Tinted", "G_Squares_Tinted", ""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutSquadLeader = {
  params ["_unit"];
  removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit;
  removeUniform _unit; removeVest _unit; removeBackpack _unit;
  removeHeadgear _unit; removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_PlateCarrier1_rgr";
  _unit addBackpack "B_AssaultPack_mcamo";

  _unit addWeapon "Binocular";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "SmokeShellOrange";

  _unit addHeadgear "H_HelmetB_snakeskin";
  _goggles = ["G_Tactical_Clear", "G_Tactical_Clear", "G_Tactical_Clear", "G_Combat", "G_Combat", "G_Combat", "G_Spectacles_Tinted", "G_Squares_Tinted", ""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutAmmoBearer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_PlateCarrier1_rgr";
  _unit addBackpack "B_Carryall_mcamo";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  for "_i" from 1 to 2 do {_unit addItemToVest "SmokeShell";};
  for "_i" from 1 to 10 do {_unit addItemToBackpack "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 3 do {_unit addItemToBackpack "200Rnd_65x39_cased_Box";};
  for "_i" from 1 to 2 do {_unit addItemToBackpack "1Rnd_SmokeRed_Grenade_shell";};
  _unit addItemToBackpack "1Rnd_Smoke_Grenade_shell";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "1Rnd_SmokeBlue_Grenade_shell";};
  for "_i" from 1 to 2 do {_unit addItemToBackpack "1Rnd_SmokeGreen_Grenade_shell";};
  for "_i" from 1 to 5 do {_unit addItemToBackpack "1Rnd_HE_Grenade_shell";};

  _unit addHeadgear "H_HelmetB_snakeskin";
  _goggles = ["G_Tactical_Clear", "G_Tactical_Clear", "G_Tactical_Clear", "G_Combat", "G_Combat", "G_Combat", "G_Spectacles_Tinted", "G_Squares_Tinted", ""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutMedic = {
  params ["_unit"];
  removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit;
  removeUniform _unit; removeVest _unit; removeBackpack _unit;
  removeHeadgear _unit; removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam_tshirt";
  _unit addVest "V_PlateCarrierGL_mtp";
  _unit addBackpack "B_Kitbag_mcamo";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  for "_i" from 1 to 2 do {_unit addItemToVest "SmokeShell";};
  _unit addItemToBackpack "Medikit";
  for "_i" from 1 to 3 do {_unit addItemToBackpack "FirstAidKit";};

  _unit addHeadgear "H_HelmetB_snakeskin";
  _goggles = ["G_Tactical_Clear", "G_Tactical_Clear", "G_Tactical_Clear", "G_Combat", "G_Combat", "G_Combat", "G_Spectacles_Tinted", "G_Squares_Tinted", ""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutRTO = {
  params ["_unit"];
  removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit;
  removeUniform _unit; removeVest _unit; removeBackpack _unit;
  removeHeadgear _unit; removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "hgun_P07_khk_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_PlateCarrier1_rgr";
  _unit addBackpack "B_RadioBag_01_mtp_F";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  for "_i" from 1 to 2 do {_unit addItemToVest "SmokeShell";};

  _unit addHeadgear "H_HelmetB_snakeskin";
  _goggles = ["G_Tactical_Clear", "G_Tactical_Clear", "G_Tactical_Clear", "G_Combat", "G_Combat", "G_Combat", "G_Spectacles_Tinted", "G_Squares_Tinted", ""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutSergeant = {
  params ["_unit"];
  removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit;
  removeUniform _unit; removeVest _unit; removeBackpack _unit;
  removeHeadgear _unit; removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_PlateCarrier2_rgr";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellPurple";
  _unit addItemToVest "SmokeShellGreen";

  _unit addHeadgear "H_HelmetB_snakeskin";
  _goggles = ["G_Tactical_Clear", "G_Tactical_Clear", "G_Tactical_Clear", "G_Combat", "G_Combat", "G_Combat", "G_Spectacles_Tinted", "G_Squares_Tinted", ""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutOfficer = {
  params ["_unit"];
  removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit;
  removeUniform _unit; removeVest _unit; removeBackpack _unit;
  removeHeadgear _unit; removeGoggles _unit;

  _unit addWeapon "arifle_MXC_F";
  _unit addPrimaryWeaponItem "optic_Holosight";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_PlateCarrier1_rgr";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 5 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellBlue";
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_Mag";};

  _unit addHeadgear "H_HelmetB_snakeskin";
  _goggles = ["G_Tactical_Clear", "G_Tactical_Clear", "G_Tactical_Clear", "G_Combat", "G_Combat", "G_Combat", "G_Spectacles_Tinted", "G_Squares_Tinted", ""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutCrewman = {
  params ["_unit"];
  removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit;
  removeUniform _unit; removeVest _unit; removeBackpack _unit;
  removeHeadgear _unit; removeGoggles _unit;

  _unit addWeapon "arifle_MXC_F";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_BandollierB_rgr";
  _unit addHeadgear "H_HelmetCrew_B";
  _unit addGoggles "G_Combat";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";

  for "_i" from 1 to 4 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "SmokeShellBlue";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutEngineer = {
  params ["_unit"];
  removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit;
  removeUniform _unit; removeVest _unit; removeBackpack _unit;
  removeHeadgear _unit; removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Holosight";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_PlateCarrier1_rgr";
  _unit addBackpack "B_AssaultPack_mcamo";
  _unit addHeadgear "H_HelmetB_snakeskin";
  _unit addGoggles "G_Combat";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";

  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToBackpack "ToolKit";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutExplosiveSpecialist = {
  params ["_unit"];
  removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit;
  removeUniform _unit; removeVest _unit; removeBackpack _unit;
  removeHeadgear _unit; removeGoggles _unit;

  _unit addWeapon "arifle_MXC_F";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "optic_Holosight";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_PlateCarrierSpec_mtp";
  _unit addBackpack "B_Kitbag_mcamo";
  _unit addHeadgear "H_HelmetSpecB_snakeskin";
  _unit addGoggles "G_Tactical_Clear";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";

  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToBackpack "ToolKit";
  _unit addItemToBackpack "SatchelCharge_Remote_Mag";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "DemoCharge_Remote_Mag";};

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutHelicopterPilot = {
  params ["_unit"];
  removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit;
  removeUniform _unit; removeVest _unit; removeBackpack _unit;
  removeHeadgear _unit; removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "optic_Holosight";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_TacVest_oli";
  _unit addHeadgear "H_PilotHelmetHeli_B";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";

  for "_i" from 1 to 4 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "B_IR_Grenade";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellOrange";
  _unit addItemToVest "SmokeShellYellow";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutHelicopterCrew = {
  params ["_unit"];
  removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit;
  removeUniform _unit; removeVest _unit; removeBackpack _unit;
  removeHeadgear _unit; removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_TacVest_oli";
  _unit addHeadgear "H_CrewHelmetHeli_B";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";

  for "_i" from 1 to 4 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "B_IR_Grenade";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellOrange";
  _unit addItemToVest "SmokeShellYellow";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutMineSpecialist = {
  params ["_unit"];
  removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit;
  removeUniform _unit; removeVest _unit; removeBackpack _unit;
  removeHeadgear _unit; removeGoggles _unit;

  _unit addWeapon "arifle_MXC_F";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "optic_Holosight";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_PlateCarrierSpec_mtp";
  _unit addBackpack "B_Carryall_mcamo";
  _unit addHeadgear "H_HelmetB_snakeskin";
  _unit addGoggles "G_Combat";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";

  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";

  _unit addItemToBackpack "MineDetector";
  _unit addItemToBackpack "ATMine_Range_Mag";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "APERSMineDispenser_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToBackpack "APERSBoundingMine_Range_Mag";};

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutSurvivor = {
  params ["_unit"];
  removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit;
  removeUniform _unit; removeVest _unit; removeBackpack _unit;
  removeHeadgear _unit; removeGoggles _unit;

  _unit forceAddUniform "U_B_CombatUniform_mcam";
 };

 PZFP_fnc_blufor_USA_Men_AddLoadoutUAVOperator = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_PlateCarrier1_rgr";
  _unit addHeadgear "H_HelmetB_snakeskin";
  _goggles = ["G_Tactical_Clear", "G_Tactical_Clear", "G_Tactical_Clear", "G_Combat", "G_Combat", "G_Combat", "G_Spectacles_Tinted", "G_Squares_Tinted", ""];
  _unit addGoggles selectRandom _goggles;

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";

  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "B_UavTerminal";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_Men_CreateRifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutRifleman;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateLAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_LAT_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutLAT;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true]; _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_AT_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutAT;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateAutorifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_soldier_AR_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutAutorifleman;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateMarksman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_soldier_M_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutMarksman;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateMachineGunner = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_support_MG_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutMachineGunner;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateTeamLeader = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_soldier_TL_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutTeamLeader;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
  };

 PZFP_fnc_blufor_USA_Men_CreateSquadLeader = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_soldier_SL_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutSquadLeader;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateAmmoBearer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_A_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutAmmoBearer;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateMedic = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_medic_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutMedic;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateRTO = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_W_RadioOperator_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutRTO;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateSergeant = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["C_Marshal_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] joinSilent _group;
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutSergeant;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateOfficer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_officer_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutOfficer;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateCrewman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_crew_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutCrewman;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateEngineer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_engineer_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutEngineer;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateExplosiveSpecialist = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_EXP_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutExplosiveSpecialist;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateHelicopterPilot = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_HeliPilot_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutHelicopterPilot;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  };
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateHelicopterCrew = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_HeliCrew_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutHelicopterCrew;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateMineSpecialist = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_mine_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutMineSpecialist;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateSurvivor = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Survivor_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutSurvivor;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Men_CreateUAVOperator = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_soldier_UAV_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_Men_AddLoadoutUAVOperator;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_AddLoadoutRifleman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam_vest";
  _unit addVest "V_PlateCarrier2_rgr_noflag_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_H_snd_F";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "B_IR_Grenade";
  _unit addHeadgear "H_HelmetSpecB_snakeskin";
  _unit addGoggles "G_Tactical_Clear";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

  PZFP_fnc_blufor_USA_MenSF_AddLoadoutRiflemanLAT = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "launch_MRAWS_sand_F";
  _unit addSecondaryWeaponItem "MRAWS_HEAT_F";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";


  _unit forceAddUniform "U_B_CombatUniform_mcam_vest";
  _unit addVest "V_PlateCarrier2_rgr_noflag_F";
  _unit addBackpack "B_KitBag_mcamo";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_H_snd_F";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "B_IR_Grenade";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "MRAWS_HEAT_F";};
  _unit addItemToBackpack "MRAWS_HE_F";
  _unit addHeadgear "H_HelmetSpecB_snakeskin";
  _unit addGoggles "G_Tactical_Clear";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_MenSF_AddLoadoutRiflemanAT = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "launch_NLAW_F";
  _unit addSecondaryWeaponItem "NLAW_F";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";


  _unit forceAddUniform "U_B_CombatUniform_mcam_vest";
  _unit addVest "V_PlateCarrier2_rgr_noflag_F";
  _unit addBackpack "B_KitBag_mcamo";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_H_snd_F";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "NLAW_F";};
  _unit addHeadgear "H_HelmetSpecB_snakeskin";
  _unit addGoggles "G_Tactical_Clear";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_MenSF_AddLoadoutAutorifleman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "LMG_Mk200_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "200Rnd_65x39_cased_Box";

  _unit forceAddUniform "U_B_CombatUniform_mcam_vest";
  _unit addVest "V_PlateCarrier2_rgr_noflag_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_H_snd_F";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 2 do {_unit addItemToVest "200Rnd_65x39_cased_Box_Red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addHeadgear "H_HelmetSpecB_snakeskin";
  _unit addGoggles "G_Tactical_Clear";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";

 };

 PZFP_fnc_blufor_USA_MenSF_AddLoadoutMarksman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;-
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "srifle_EBR_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_AMS_snd";
  _unit addPrimaryWeaponItem "20Rnd_762x51_Mag";
  _unit addPrimaryWeaponItem "bipod_01_F_blk";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam_vest";
  _unit addVest "V_PlateCarrier2_rgr_noflag_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_H_snd_B";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "20Rnd_762x51_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "B_IR_Grenade";
  _unit addHeadgear "H_HelmetSpecB_snakeskin";
  _unit addGoggles "G_Tactical_Clear";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_MenSF_AddLoadoutTeamLeader = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MX_GL_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addPrimaryWeaponItem "3Rnd_HE_Grenade_shell";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_PlateCarrier2_rgr";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";
  _unit addItemToUniform "muzzle_snds_H_snd_F";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "3Rnd_HE_Grenade_shell";};
  _unit addItemToVest "UGL_FlareCIR_F";
  _unit addItemToVest "1Rnd_Smoke_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeRed_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeGreen_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeBlue_Grenade_shell";
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addHeadgear "H_HelmetSpecB_snakeskin";
  _unit addGoggles "G_Tactical_Clear";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_MenSF_AddLoadoutSquadLeader = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam";
  _unit addVest "V_PlateCarrier2_rgr_noflag_F";

  _unit addWeapon "Binocular";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";
  _unit addItemToUniform "muzzle_snds_H_snd_F";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "SmokeShellOrange";
  _unit addHeadgear "H_HelmetSpecB_snakeskin";
  _unit addGoggles "G_Tactical_Clear";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_MenSF_AddLoadoutJTAC = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam_vest";
  _unit addVest "V_PlateCarrier2_rgr_noflag_F";

  _unit addMagazine "Laserbatteries";
  _unit addWeapon "Laserdesignator";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_H_snd_F";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";
  _unit addItemToUniform "Laserbatteries";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "B_IR_Grenade";
  _unit addHeadgear "H_HelmetSpecB_snakeskin";
  _unit addGoggles "G_Tactical_Clear";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_MenSF_AddLoadoutMedic = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam_vest";
  _unit addVest "V_PlateCarrier2_rgr_noflag_F";
  _unit addBackpack "B_Kitbag_mcamo";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";
  _unit addItemToUniform "muzzle_snds_H_snd_F";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  for "_i" from 1 to 2 do {_unit addItemToVest "SmokeShell";};
  _unit addItemToBackpack "Medikit";
  for "_i" from 1 to 3 do {_unit addItemToBackpack "FirstAidKit";};
  _unit addHeadgear "H_HelmetSpecB_snakeskin";
  _unit addGoggles "G_Tactical_Clear";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_MenSF_AddLoadoutRTO = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam_vest";
  _unit addVest "V_PlateCarrier2_rgr_noflag_F";
  _unit addBackpack "B_RadioBag_01_mtp_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  for "_i" from 1 to 2 do {_unit addItemToVest "SmokeShell";};
  _unit addHeadgear "H_HelmetSpecB_snakeskin";
  _unit addGoggles "G_Tactical_Clear";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_MenSF_AddLoadoutAmmoBearer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam_vest";
  _unit addVest "V_PlateCarrier2_rgr_noflag_F";
  _unit addBackpack "B_Kitbag_mcamo";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  for "_i" from 1 to 2 do {_unit addItemToVest "SmokeShell";};

  _unit addHeadgear "H_HelmetSpecB_snakeskin";
  _unit addGoggles "G_Tactical_Clear";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_MenSF_AddLoadoutDemoSpecialist = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam_vest";
  _unit addVest "V_PlateCarrier2_rgr_noflag_F";
  _unit addBackpack "B_kitbag_mcamo";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToBackpack "ToolKit";
  _unit addItemToBackpack "SatchelCharge_Remote_Mag";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "DemoCharge_Remote_Mag";};
  _unit addHeadgear "H_HelmetSpecB_snakeskin";
  _unit addGoggles "G_Tactical_Clear";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_MenSF_AddLoadoutEngineer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam_vest";
  _unit addVest "V_PlateCarrier2_rgr_noflag_F";
  _unit addBackpack "B_kitbag_mcamo";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToBackpack "ToolKit";
  _unit addHeadgear "H_HelmetSpecB_snakeskin";
  _unit addGoggles "G_Tactical_Clear";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_MenSF_AddLoadoutSniper = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "srifle_LRR_camo_F";
  _unit addPrimaryWeaponItem "optic_AMS";
  _unit addPrimaryWeaponItem "7Rnd_408_Mag";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "muzzle_snds_L";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_FullGhillie_sard";
  _unit addVest "V_Chestrig_rgr";

  _unit addWeapon "Rangefinder";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 2 do {_unit addItemToUniform "7Rnd_408_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "B_IR_Grenade";
  _unit addItemToVest "ClaymoreDirectionalMine_Remote_Mag";
  _unit addItemToVest "APERSTripMine_Wire_Mag";
  for "_i" from 1 to 3 do {_unit addItemToVest "7Rnd_408_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_Mag";};

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";

 };

 PZFP_fnc_blufor_USA_MenSF_AddLoadoutSpotter = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "srifle_DMR_03_multicam_F";
  _unit addPrimaryWeaponItem "muzzle_snds_B_snd_F";
  _unit addPrimaryWeaponItem "optic_AMS";
  _unit addPrimaryWeaponItem "20Rnd_762x51_Mag";
  _unit addPrimaryWeaponItem "bipod_01_F_mtp";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "muzzle_snds_L";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_FullGhillie_sard";
  _unit addVest "V_Chestrig_rgr";

  _unit addMagazine "Laserbatteries";
  _unit addWeapon "Laserdesignator";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Laserbatteries";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 7 do {_unit addItemToVest "20Rnd_762x51_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_Mag";};
  _unit addItemToVest "APERSTripMine_Wire_Mag";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellOrange";
  _unit addItemToVest "B_IR_Grenade";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";

 };

 PZFP_fnc_blufor_USA_MenSF_AddLoadoutSergeant = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam_vest";
  _unit addVest "V_PlateCarrier2_rgr_noflag_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_H_snd_F";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellPurple";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "B_IR_Grenade";
  _unit addHeadgear "H_HelmetSpecB_snakeskin";
  _unit addGoggles "G_Tactical_Clear";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_MenSF_AddLoadoutOfficer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";
  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_CombatUniform_mcam_vest";
  _unit addVest "V_PlateCarrier2_rgr_noflag_F";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 5 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellBlue";
  for "_i" from 1 to 2 do {_unit addItemToVest "16Rnd_9x21_Mag";};
  _unit addHeadgear "H_HelmetSpecB_snakeskin";
  _unit addGoggles "G_Tactical_Clear";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USA_MenSF_CreateRifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutRifleman;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_CreateRiflemanLAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_LAT_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
	params ["_unit"];
	sleep 0.1;
	[_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutRiflemanLAT;
	[_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_CreateRiflemanAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_soldier_LAT_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
	params ["_unit"];
	sleep 0.1;
	[_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutRiflemanAT;
	[_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_CreateAutorifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_AR_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
	params ["_unit"];
	sleep 0.1;
	[_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutAutorifleman;
	[_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_CreateMarksman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_M_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
	params ["_unit"];
	sleep 0.1;
	[_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutMarksman;
	[_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_CreateMachineGunner = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_support_MG_F", _position, [], 0, "CAN_COLLIDE"]; // heavy MG
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
	params ["_unit"];
	sleep 0.1;
	[_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutMachineGunner;
	[_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_CreateTeamLeader = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_TL_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
	params ["_unit"];
	sleep 0.1;
	[_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutTeamLeader;
	[_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_CreateSquadLeader = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_SL_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
	params ["_unit"];
	sleep 0.1;
	[_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutSquadLeader;
	[_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_CreateJTAC = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_CTRG_soldier_JTAC_tna_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
	params ["_unit"];
	sleep 0.1;
	[_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutJTAC;
	[_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_CreateMedic = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_medic_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
	params ["_unit"];
	sleep 0.1;
	[_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutMedic;
	[_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_CreateRTO = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_W_RadioOperator_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
	params ["_unit"];
	sleep 0.1;
	[_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutRTO;
	[_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_CreateJTAC = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_CTRG_Soldier_JTAC_tna_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutJTAC;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_CreateAmmoBearer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_A_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutAmmoBearer;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_CreateDemoSpecialist = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_CTRG_Soldier_Exp_tna_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutDemoSpecialist;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_CreateEngineer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_engineer_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutEngineer;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_CreateSniper = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_sniper_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutSniper;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_CreateSpotter = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_spotter_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutSpotter;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_CreateSergeant = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["C_Marshal_F", _position, [], 0, "CAN_COLLIDE"];
  [_unit] joinSilent _group;
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutSergeant;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_MenSF_CreateOfficer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_officer_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USA_MenSF_AddLoadoutOfficer;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USA_Tanks_CreateSquadLeaderammer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_MBT_01_Cannon_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Sand",1],
   ["showBags",1,"showCamonetTurret",0,"showCamonetHull",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _commander moveInCommander _vehicle;

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Tanks_CreateSquadLeaderammerUP = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_MBT_01_TUSK_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Sand",1],
   ["showBags",1,"showCamonetTurret",0,"showCamonetHull",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _commander moveInCommander _vehicle;

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_TankDestroyers_CreateRhino = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_AFV_Wheeled_01_Cannon_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Sand",1],
   ["showCamonetHull",0,"showCamonetTurret",0,"showSLATHull",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _commander moveInCommander _vehicle;

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_TankDestroyers_CreateRhinoUP = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_AFV_Wheeled_01_Up_Cannon_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Sand",1],
   ["showCamonetHull",0,"showCamonetTurret",0,"showSLATHull",1]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_USA_Men_CreateCrewman;
  _commander moveInCommander _vehicle;

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Turrets_CreateRadar = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Radar_System_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Desert",1],
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Turrets_CreateSAM = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_SAM_System_03_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Desert",1],
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Turrets_CreateHMGTripod = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_HMG_01_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Turrets_CreateHMGRaised = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_HMG_01_high_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Turrets_CreateHMGAuto = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_HMG_01_A_F",_position,[],0,"NONE"];

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Turrets_CreateGMGTripod = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_GMG_01_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Turrets_CreateGMGRaised = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_GMG_01_high_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Turrets_CreateGMGAuto = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_GMG_01_A_F",_position,[],0,"NONE"];

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Turrets_CreateMortar = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Mortar_01_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Turrets_CreatePraetorian = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_AAA_System_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Sand",1],
   true
  ] call BIS_fnc_initVehicle;

  _vehicle removeWeaponTurret["weapon_Cannon_Phalanx",[0]];
  _vehicle addWeaponTurret["gatling_20mm_VTOL_01",[0]];
  _vehicle addMagazineTurret["4000Rnd_20mm_Tracer_Red_shells",[0]];

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];
  crew _vehicle select 0 setSkill 1;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Turrets_CreateDesignator = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Static_Designator_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Desert",1],
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Turrets_CreateAA = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Static_AA_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USA_Turrets_CreateAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Static_AT_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_USA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USN_Boats_CreateAssaultBoat = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Boat_Transport_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Black",1],
   true
  ] call BIS_fnc_initVehicle;

  _driver = [] call PZFP_fnc_blufor_USN_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup ["west", true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USN_Boats_CreateRescueBoat = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Lifeboat",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Rescue",1],
   true
  ] call BIS_fnc_initVehicle;

  _driver = [] call PZFP_fnc_blufor_USN_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup ["west", true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USN_Drones_CreateSentinel = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_UAV_05_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["DarkGrey",1],
   ["wing_fold_l",0]
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USN_Boats_CreateRHIB = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_C_Boat_Transport_02_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Black",1],
   true
  ] call BIS_fnc_initVehicle;

  _driver = [] call PZFP_fnc_blufor_USN_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup ["west", true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USN_Boats_CreatePatrolBoat = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Boat_Armed_01_minigun_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  _driver = [] call PZFP_fnc_blufor_USN_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  _gunner = [] call PZFP_fnc_blufor_USN_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;
  _commander = [] call PZFP_fnc_blufor_USN_Men_CreateRifleman;
  _commander moveInCommander _vehicle;

  private _group = createGroup ["west", true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USN_Men_AddLoadoutRifleman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MX_Black_F";
  _unit addPrimaryWeaponItem "optic_Aco";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_black_mag";

  _unit forceAddUniform "U_C_WorkerCoveralls";
  [_unit, [0, "\A3\characters_f\common\data\coveralls_urbancamo_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_PlateCarrier1_blk";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_black_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellBlue";
  _unit addHeadgear "H_MilCap_gry";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
 };

 PZFP_fnc_blufor_USN_Men_AddLoadoutRiflemanUnarmed = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit forceAddUniform "U_C_WorkerCoveralls";
  [_unit, [0, "\A3\characters_f\common\data\coveralls_urbancamo_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_PlateCarrier1_blk";

  _unit addItemToUniform "Wallet_ID";
  _unit addHeadgear "H_MilCap_gry";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
 };

 PZFP_fnc_blufor_USN_Men_AddLoadoutShipCrew = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit forceAddUniform "U_C_WorkerCoveralls";
  [_unit, [0, "\A3\characters_f\common\data\coveralls_urbancamo_co.paa"]] remoteExec ['setObjectTexture',0,true];

  _unit addItemToUniform "Wallet_ID";
  _unit addHeadgear "H_MilCap_gry";

  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
 };

 PZFP_fnc_blufor_USN_Men_CreateRifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USN_Men_AddLoadoutRifleman;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USN_Men_CreateRiflemanUnarmed = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_Unarmed_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USN_Men_AddLoadoutRiflemanUnarmed;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USN_Men_CreateShipCrew = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Crew_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USN_Men_AddLoadoutShipCrew;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USN_MenSOFFrogmen_AddLoadoutRifleman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SDAR_F";
  _unit addPrimaryWeaponItem "20Rnd_556x45_UW_mag";

  _unit forceAddUniform "U_B_Wetsuit";
  _unit addVest "V_RebreatherB";

  _unit addItemToUniform "FirstAidKit";
  for "_i" from 1 to 3 do {_unit addItemToUniform "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 3 do {_unit addItemToUniform "20Rnd_556x45_UW_mag";};
  for "_i" from 1 to 3 do {_unit addItemToUniform "MiniGrenade";};
  for "_i" from 1 to 2 do {_unit addItemToUniform "SmokeShellBlue";};
  _unit addItemToUniform "Chemlight_blue";
  _unit addGoggles "G_B_Diving";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
 };

 PZFP_fnc_blufor_USN_MenSOFFrogmen_AddLoadoutExplosiveSpecialist = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SDAR_F";
  _unit addPrimaryWeaponItem "20Rnd_556x45_UW_mag";

  _unit forceAddUniform "U_B_Wetsuit";
  _unit addVest "V_RebreatherB";
  _unit addBackpack "B_Assault_Diver";

  _unit addItemToUniform "FirstAidKit";
  for "_i" from 1 to 3 do {_unit addItemToUniform "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 3 do {_unit addItemToUniform "20Rnd_556x45_UW_mag";};
  for "_i" from 1 to 3 do {_unit addItemToUniform "MiniGrenade";};
  for "_i" from 1 to 2 do {_unit addItemToUniform "SmokeShellBlue";};
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 3 do {_unit addItemToBackpack "DemoCharge_Remote_Mag";};
  _unit addGoggles "G_B_Diving";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
 };

 PZFP_fnc_blufor_USN_MenSOFFrogmen_AddLoadoutTeamLeader = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SDAR_F";
  _unit addPrimaryWeaponItem "20Rnd_556x45_UW_mag";

  _unit forceAddUniform "U_B_Wetsuit";
  _unit addVest "V_RebreatherB";
  _unit addBackpack "B_AssaultPack_blk";

  _unit addItemToUniform "FirstAidKit";
  for "_i" from 1 to 3 do {_unit addItemToUniform "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 3 do {_unit addItemToUniform "20Rnd_556x45_UW_mag";};
  for "_i" from 1 to 3 do {_unit addItemToUniform "MiniGrenade";};
  for "_i" from 1 to 2 do {_unit addItemToUniform "SmokeShellBlue";};
  _unit addItemToUniform "Chemlight_blue";
  _unit addGoggles "G_B_Diving";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
 };

 PZFP_fnc_blufor_USN_MenSOFFrogmen_CreateRifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_diver_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USN_MenSOFFrogmen_AddLoadoutRifleman;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USN_MenSOFFrogmen_CreateExplosiveSpecialist = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_diver_exp_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USN_MenSOFFrogmen_AddLoadoutExplosiveSpecialist;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USN_MenSOFFrogmen_CreateTeamLeader = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_diver_TL_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USN_MenSOFFrogmen_AddLoadoutTeamLeader;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USN_MenSOFRaiders_AddLoadoutRifleman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "SMG_05_F";
  _unit addPrimaryWeaponItem "muzzle_snds_L";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "optic_Holosight_smg_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_9x21_Mag_SMG_02";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "muzzle_snds_acp";
  _unit addHandgunItem "acc_flashlight_pistol";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_B_CTRG_3";
  [_unit, [0, "\A3\Characters_F\Common\Data\basicbody_black_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_PlateCarrier1_blk";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 3 do {_unit addItemToUniform "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_9x21_Mag_SMG_02";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  _unit addItemToVest "Chemlight_blue";
  _unit addItemToVest "Chemlight_green";
  _unit addItemToVest "B_IR_Grenade";
  for "_i" from 1 to 2 do {_unit addItemToVest "MiniGrenade";};
  _unit addHeadgear "H_HelmetB_light_black";
  _unit addGoggles "G_Balaclava_TI_blk_F";

  _unit linkItem "ItemGPS";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
 };

 PZFP_fnc_blufor_USN_MenSOFRaiders_AddLoadoutTeamLeader = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "SMG_05_F";
  _unit addPrimaryWeaponItem "muzzle_snds_L";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "optic_Holosight_smg_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_9x21_Mag_SMG_02";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "muzzle_snds_acp";
  _unit addHandgunItem "acc_flashlight_pistol";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_B_CTRG_3";
  [_unit, [0, "\A3\Characters_F\Common\Data\basicbody_black_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_PlateCarrier1_blk";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 3 do {_unit addItemToUniform "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_9x21_Mag_SMG_02";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  _unit addItemToVest "Chemlight_blue";
  _unit addItemToVest "Chemlight_green";
  _unit addItemToVest "B_IR_Grenade";
  for "_i" from 1 to 2 do {_unit addItemToVest "MiniGrenade";};
  _unit addHeadgear "H_HelmetB_light_black";
  _unit addGoggles "G_Balaclava_TI_blk_F";

  _unit linkItem "ItemGPS";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
 };

 PZFP_fnc_blufor_USN_MenSOFRaiders_AddLoadoutExplosiveSpecialist = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "SMG_05_F";
  _unit addPrimaryWeaponItem "muzzle_snds_L";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "optic_Holosight_smg_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_9x21_Mag_SMG_02";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "muzzle_snds_acp";
  _unit addHandgunItem "acc_flashlight_pistol";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_B_CTRG_3";
  [_unit, [0, "\A3\Characters_F\Common\Data\basicbody_black_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_PlateCarrier1_blk";
  _unit addBackpack "B_AssaultPack_blk";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 3 do {_unit addItemToUniform "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_9x21_Mag_SMG_02";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  _unit addItemToVest "Chemlight_blue";
  _unit addItemToVest "Chemlight_green";
  _unit addItemToVest "B_IR_Grenade";
  for "_i" from 1 to 2 do {_unit addItemToVest "MiniGrenade";};
  for "_i" from 1 to 2 do {_unit addItemToBackpack "DemoCharge_Remote_Mag";};
  _unit addHeadgear "H_HelmetB_light_black";
  _unit addGoggles "G_Balaclava_TI_blk_F";

  _unit linkItem "ItemGPS";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
 };

 PZFP_fnc_blufor_USN_MenSOFRaiders_AddLoadoutMedic = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "SMG_05_F";
  _unit addPrimaryWeaponItem "muzzle_snds_L";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "optic_Holosight_smg_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_9x21_Mag_SMG_02";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "muzzle_snds_acp";
  _unit addHandgunItem "acc_flashlight_pistol";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_B_CTRG_3";
  [_unit, [0, "\A3\Characters_F\Common\Data\basicbody_black_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_PlateCarrier1_blk";
  _unit addBackpack "B_AssaultPack_blk";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 3 do {_unit addItemToUniform "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_9x21_Mag_SMG_02";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  _unit addItemToVest "Chemlight_blue";
  _unit addItemToVest "Chemlight_green";
  _unit addItemToVest "B_IR_Grenade";
  for "_i" from 1 to 2 do {_unit addItemToVest "MiniGrenade";};
  _unit addItemToBackpack "Medikit";
  for "_i" from 1 to 3 do {_unit addItemToBackpack "FirstAidKit";};
  _unit addHeadgear "H_HelmetB_light_black";
  _unit addGoggles "G_Balaclava_TI_blk_F";

  _unit linkItem "ItemGPS";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
 };

 PZFP_fnc_blufor_USN_MenSOFRaiders_AddLoadoutMarksman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SPAR_03_blk_F";
  _unit addPrimaryWeaponItem "optic_LRPS";
  _unit addPrimaryWeaponItem "20Rnd_762x51_Mag";
  _unit addPrimaryWeaponItem "bipod_01_F_blk";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "muzzle_snds_acp";
  _unit addHandgunItem "acc_flashlight_pistol";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_B_CTRG_3";
  [_unit, [0, "\A3\Characters_F\Common\Data\basicbody_black_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_PlateCarrier1_blk";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 3 do {_unit addItemToUniform "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 5 do {_unit addItemToVest "20Rnd_762x51_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  _unit addItemToVest "Chemlight_blue";
  _unit addItemToVest "Chemlight_green";
  _unit addItemToVest "B_IR_Grenade";
  for "_i" from 1 to 2 do {_unit addItemToVest "MiniGrenade";};
  _unit addHeadgear "H_HelmetB_light_black";
  _unit addGoggles "G_Balaclava_TI_blk_F";

  _unit linkItem "ItemGPS";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
 };

 PZFP_fnc_blufor_USN_MenSOFRaiders_AddLoadoutRTO = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "SMG_05_F";
  _unit addPrimaryWeaponItem "muzzle_snds_L";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "optic_Holosight_smg_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_9x21_Mag_SMG_02";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "muzzle_snds_acp";
  _unit addHandgunItem "acc_flashlight_pistol";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_B_CTRG_3";
  [_unit, [0, "\A3\Characters_F\Common\Data\basicbody_black_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_PlateCarrier1_blk";
  _unit addBackpack "B_RadioBag_01_black_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 3 do {_unit addItemToUniform "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_9x21_Mag_SMG_02";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  _unit addItemToVest "Chemlight_blue";
  _unit addItemToVest "Chemlight_green";
  _unit addItemToVest "B_IR_Grenade";
  for "_i" from 1 to 2 do {_unit addItemToVest "MiniGrenade";};
  _unit addHeadgear "H_HelmetB_light_black";
  _unit addGoggles "G_Balaclava_TI_blk_F";

  _unit linkItem "ItemGPS";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
 };

 PZFP_fnc_blufor_USN_MenSOFRaiders_CreateRifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USN_MenSOFRaiders_AddLoadoutRifleman;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USN_MenSOFRaiders_CreateTeamLeader = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_TL_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USN_MenSOFRaiders_AddLoadoutTeamLeader;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USN_MenSOFRaiders_CreateExplosiveSpecialist = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_exp_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USN_MenSOFRaiders_AddLoadoutExplosiveSpecialist;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USN_MenSOFRaiders_CreateMedic = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_medic_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USN_MenSOFRaiders_AddLoadoutMedic;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USN_MenSOFRaiders_CreateMarksman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_M_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USN_MenSOFRaiders_AddLoadoutMarksman;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USN_MenSOFRaiders_CreateRTO = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_W_RadioOperator_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USN_MenSOFRaiders_AddLoadoutRTO;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USN_Pilots_AddLoadoutFighterPilot = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "hgun_P07_F";
  _unit addHandgunItem "16Rnd_9x21_Mag";

  _unit forceAddUniform "U_B_PilotCoveralls";

  _unit addItemToUniform "FirstAidKit";
  for "_i" from 1 to 3 do {_unit addItemToUniform "16Rnd_9x21_Mag";};
  _unit addItemToUniform "SmokeShellOrange";
  for "_i" from 1 to 2 do {_unit addItemToUniform "Chemlight_blue";};
  _unit addItemToUniform "B_IR_Grenade";
  _unit addItemToUniform "SmokeShell";
  _unit addItemToUniform "SmokeShellBlue";
  _unit addHeadgear "H_PilotHelmetFighter_B";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit
 };

 PZFP_fnc_blufor_USN_Pilots_AddLoadoutTransportPilot = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MX_F";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "optic_Holosight";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_mag";

  _unit forceAddUniform "U_C_WorkerCoveralls";
  [_unit, [0, "\A3\characters_f\common\data\coveralls_urbancamo_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_TacVest_blk";
  _unit addHeadgear "H_PilotHelmetHeli_B";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";

  for "_i" from 1 to 4 do {_unit addItemToVest "30Rnd_65x39_caseless_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "B_IR_Grenade";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellOrange";
  _unit addItemToVest "SmokeShellYellow";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_USN_Pilots_CreateFighterPilot = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Fighter_Pilot_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USN_Pilots_AddLoadoutFighterPilot;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USN_Pilots_CreateTransportPilot = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Pilot_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_USN_Pilots_AddLoadoutTransportPilot;
   [_unit] call PZFP_fnc_blufor_USA_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_USN_Planes_CreateBlackWasp = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Plane_Fighter_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["DarkGrey",1],
   ["wing_fold_l",0]
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_USN_Pilots_CreateFighterPilot;
  _pilot moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_pilot,_copilot1,_copilot2,_copilot3] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USN_Planes_CreateVTOL = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_T_VTOL_01_infantry_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blue",1],
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_USN_Pilots_CreateTransportPilot;
  _pilot moveInDriver _vehicle;
  private _copilot1 = [] call PZFP_fnc_blufor_USN_Pilots_CreateTransportPilot;
  _copilot1 moveInTurret [_vehicle, [0]];
  private _copilot2 = [] call PZFP_fnc_blufor_USN_Pilots_CreateTransportPilot;
  _copilot2 moveInTurret [_vehicle, [1]];
  private _copilot3 = [] call PZFP_fnc_blufor_USN_Pilots_CreateTransportPilot;
  _copilot3 moveInTurret [_vehicle, [2]];

  private _group = createGroup [west, true];
  [_pilot,_copilot1,_copilot2,_copilot3] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];

 };

 PZFP_fnc_blufor_USN_Planes_CreateVTOLArmed = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_T_VTOL_01_Armed_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blue",1],
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_USN_Pilots_CreateTransportPilot;
  _pilot moveInDriver _vehicle;
  private _copilot1 = [] call PZFP_fnc_blufor_USN_Pilots_CreateTransportPilot;
  _copilot1 moveInTurret [_vehicle, [0]];
  private _copilot2 = [] call PZFP_fnc_blufor_USN_Pilots_CreateTransportPilot;
  _copilot2 moveInTurret [_vehicle, [1]];
  private _copilot3 = [] call PZFP_fnc_blufor_USN_Pilots_CreateTransportPilot;
  _copilot3 moveInTurret [_vehicle, [2]];

  private _group = createGroup [west, true];
  [_pilot,_copilot1,_copilot2,_copilot3] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USN_Planes_CreateVTOLVehicle = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_T_VTOL_01_Vehicle_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blue",1],
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_USN_Pilots_CreateTransportPilot;
  _pilot moveInDriver _vehicle;
  private _copilot1 = [] call PZFP_fnc_blufor_USN_Pilots_CreateTransportPilot;
  _copilot1 moveInTurret [_vehicle, [0]];
  private _copilot2 = [] call PZFP_fnc_blufor_USN_Pilots_CreateTransportPilot;
  _copilot2 moveInTurret [_vehicle, [1]];
  private _copilot3 = [] call PZFP_fnc_blufor_USN_Pilots_CreateTransportPilot;
  _copilot3 moveInTurret [_vehicle, [2]];

  private _group = createGroup [west, true];
  [_pilot,_copilot1,_copilot2,_copilot3] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USN_Turrets_CreateCenturion = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_SAM_System_02_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["LightGrey",1],
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USN_Turrets_CreateVLS = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Ship_MRLS_01_F",_position,[],0,"NONE"];

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USN_Turrets_CreateHammer= {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Ship_Gun_01_F",_position,[],0,"NONE"];

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USN_Turrets_CreateSpartan = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_SAM_System_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["LightGrey",1],
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_USN_Turrets_CreatePraetorian = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_AAA_System_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["LightGrey",1],
   true
  ] call BIS_fnc_initVehicle;

  _vehicle removeWeaponTurret["weapon_Cannon_Phalanx",[0]];
  _vehicle addWeaponTurret["gatling_20mm_VTOL_01",[0]];
  _vehicle addMagazineTurret["4000Rnd_20mm_Tracer_Red_shells",[0]];

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];
  crew _vehicle select 0 setSkill 1;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_AntiAir_CreateIFV6	= {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_APC_Tracked_01_AA_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Sand",1],
   ["showCamonetTurret",0,"showCamonetHull",0,"showBags",1]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_BA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_BA_Men_CreateCrewman;
  _commander moveInCommander _vehicle;

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_APC_CreateCRV6Bobcat = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_APC_Tracked_01_CRV_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Sand",1],
   ["showAmmobox",selectRandom [0,1],"showWheels",1,"showCamonetHull",0,"showBags",selectRandom [0,1]]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_BA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_BA_Men_CreateCrewman;
  _commander moveInCommander _vehicle;

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_APC_CreateGorgon = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_APC_Wheeled_03_cannon_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Indep",1],
   ["showCamonetHull",0,"showBags",1,"showBags2",1,"showTools",selectRandom [0,1],"showSLATHull",0]
  ] call BIS_fnc_initVehicle;

  [_vehicle, [0, "A3\Armor_F_Gamma\APC_Wheeled_03\Data\apc_wheeled_03_ext_co.paa"]] remoteExec ['setObjectTexture',0,true];
  [_vehicle, [1, "A3\Armor_F_Gamma\APC_Wheeled_03\Data\apc_wheeled_03_ext2_co.paa"]] remoteExec ['setObjectTexture',0,true];
  [_vehicle, [2, "A3\Armor_F_Gamma\APC_Wheeled_03\Data\rcws30_co.paa"]] remoteExec ['setObjectTexture',0,true];
  [_vehicle, [3, "A3\Armor_F_Gamma\APC_Wheeled_03\Data\apc_wheeled_03_ext_alpha_co.paa"]] remoteExec ['setObjectTexture',0,true];


  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_BA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_BA_Men_CreateCrewman;
  _commander moveInCommander _vehicle;

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_APC_CreateIFV6cPanther = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_APC_Tracked_01_rcws_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Sand",1],
   ["showCamonetHull",0,"showBags",1]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_BA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_BA_Men_CreateCrewman;
  _commander moveInCommander _vehicle;

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

  PZFP_fnc_blufor_BA_Artillery_CreateScorcher = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_MBT_01_Arty_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Green",1],
   ["showCanisters",1,"showCamonetTurret",0,"showAmmobox",1,"showCamonetHull",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_BA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_BA_Men_CreateCrewman;
  _commander moveInCommander _vehicle;

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Artillery_CreateSandstorm = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_MBT_01_mlrs_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Green",1],
   ["showCamonetTurret",0,"showCamonetHull",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_BA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;

  private _group = createGroup [west, true];
  [_gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Boats_CreateAssaultBoat = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Boat_Transport_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Black",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Boats_CreateRescueBoat = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Lifeboat",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Rescue",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Boats_CreateRHIB = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_C_Boat_Transport_02_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Black",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Cars_CreateHEMTT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_mover_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Cars_CreateHEMTTAmmo = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_ammo_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Cars_CreateHEMTTBox = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_box_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Cars_CreateHEMTTCargo = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_cargo_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Cars_CreateHEMTTFlatbed = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_flatbed_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Cars_CreateHEMTTFuel = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_fuel_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Cars_CreateHEMTTMedical = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_medical_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Cars_CreateHEMTTRepair = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_repair_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Cars_CreateHEMTTTransport = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_transport_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Cars_CreateHEMTTCovered = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Truck_01_covered_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Cars_CreateStrider = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_MRAP_03_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Cars_CreateStriderHMG = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_MRAP_03_hmg_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _commander moveInTurret [_vehicle, [1]];

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Cars_CreateStriderGMG = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_MRAP_03_gmg_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _commander moveInTurret [_vehicle, [1]];

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Drones_CreatePelican = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_UAV_06_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   ["lights_em_hide",0,"LED_lights_hide",1,"Inventory_door",0]
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Drones_CreatePelicanMedical = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_UAV_06_medical_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   ["lights_em_hide",0,"LED_lights_hide",1,"Inventory_door",0]
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Drones_CreateDarter = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_UAV_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Drones_CreatePelter = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_UGV_02_Demining_F",_position,[],0,"NONE"];

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Drones_CreateRoller = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_UGV_02_Science_F",_position,[],0,"NONE"];

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Cars_CreateStrider = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_MRAP_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Helicopters_CreateBlackfoot = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Heli_Attack_01_dynamicloadout_F",_position,[],0,"NONE"];
  [
   _vehicle,
   nil,
   true
  ] call BIS_fnc_initVehicle;
  [_vehicle, [0, "A3\Air_F\Heli_Light_02\Data\heli_light_02_common_co.paa"]] remoteExec ['setObjectTexture',0,true];

  private _pilot = [] call PZFP_fnc_blufor_BA_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_BA_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];

  private _group = createGroup [west, true];
  [_pilot, _copilot] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Helicopters_CreateGhosthawk = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Heli_Transport_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Black",1],
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_BA_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_BA_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  private _crew1 = [] call PZFP_fnc_blufor_BA_Men_CreateHelicopterCrew;
  _crew1 moveInTurret [_vehicle, [1]];
  private _crew2 = [] call PZFP_fnc_blufor_BA_Men_CreateHelicopterCrew;
  _crew2 moveInTurret [_vehicle, [2]];
  _vehicle lockCargo true;
  _vehicle setVariable ["doorsClosed", true];

  [_vehicle,
  ["<img image='\a3\ui_f\data\IGUI\Cfg\Actions\open_door_ca.paa'></image><t color='#32CD32'> Open Passenger Doors</t>",
   {
    params ["_target"];
    [_target, ["Door_L", 1]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_R", 1]] remoteExec ['animateDoor',0,true];
    _target lockCargo false;
    _target setVariable ["doorsClosed", false];
   },
   nil,
   2,
   true,
   false,
   "",
   "_target getVariable ['doorsClosed', true] == true",
   7,
   false,
   "",
   ""
  ]] remoteExec ['addAction',0,true];

  [_vehicle,
  ["<img image='\a3\ui_f\data\IGUI\Cfg\Actions\open_door_ca.paa'></image><t color='#32CD32'> Close Passenger Doors</t>",
   {
    params ["_target"];
    [_target, ["Door_L", 0]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_R", 0]] remoteExec ['animateDoor',0,true];
    _target lockCargo true;
    _target setVariable ["doorsClosed", true];
   },
   nil,
   2,
   true,
   false,
   "",
   "_target getVariable ['doorsClosed', false] == false",
   7,
   false,
   "",
   ""
  ]] remoteExec ['addAction',0,true];
  

  private _group = createGroup [west, true];
  [_pilot, _copilot, _crew1, _crew2] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Helicopters_CreateGhosthawkStub = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Heli_Transport_01_pylons_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Black",1],
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_BA_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_BA_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  _vehicle lockCargo true;
  _vehicle setVariable ["doorsClosed", true];

  [_vehicle,
  ["<img image='\a3\ui_f\data\IGUI\Cfg\Actions\open_door_ca.paa'></image><t color='#32CD32'> Open Passenger Doors</t>",
   {
    params ["_target"];
    [_target, ["Door_L", 1]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_R", 1]] remoteExec ['animateDoor',0,true];
    _target lockCargo false;
    _target setVariable ["doorsClosed", false];
   },
   nil,
   2,
   true,
   false,
   "",
   "_target getVariable ['doorsClosed', true] == true",
   7,
   false,
   "",
   ""
  ]] remoteExec ['addAction',0,true];

  [_vehicle,
  ["<img image='\a3\ui_f\data\IGUI\Cfg\Actions\open_door_ca.paa'></image><t color='#32CD32'> Close Passenger Doors</t>",
   {
    params ["_target"];
    [_target, ["Door_L", 0]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_R", 0]] remoteExec ['animateDoor',0,true];
    _target lockCargo true;
    _target setVariable ["doorsClosed", true];
   },
   nil,
   2,
   true,
   false,
   "",
   "_target getVariable ['doorsClosed', false] == false",
   7,
   false,
   "",
   ""
  ]] remoteExec ['addAction',0,true];
  

  private _group = createGroup [west, true];
  [_pilot, _copilot] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Helicopters_CreateHuron = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Heli_Transport_03_Unarmed_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Green",1],
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_BA_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_BA_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  _vehicle lockCargo true;
  _vehicle setVariable ["doorsClosed", true];

  [_vehicle,
  ["<img image='\a3\ui_f\data\IGUI\Cfg\Actions\open_door_ca.paa'></image><t color='#32CD32'> Open Passenger Doors</t>",
   {
    params ["_target"];
    [_target, ["Door_L_source", 1]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_R_source", 1]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_rear_source", 1]] remoteExec ['animateDoor',0,true];
    _target lockCargo false;
    _target setVariable ["doorsClosed", false];
   },
   nil,
   2,
   true,
   false,
   "",
   "_target getVariable ['doorsClosed', true] == true",
   7,
   false,
   "",
   ""
  ]] remoteExec ['addAction',0,true];

  [_vehicle,
  ["<img image='\a3\ui_f\data\IGUI\Cfg\Actions\open_door_ca.paa'></image><t color='#32CD32'> Close Passenger Doors</t>",
   {
    params ["_target"];
    [_target, ["Door_L_source", 0]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_R_source", 0]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_rear_source", 0]] remoteExec ['animateDoor',0,true];
    _target lockCargo true;
    _target setVariable ["doorsClosed", true];
   },
   nil,
   2,
   true,
   false,
   "",
   "_target getVariable ['doorsClosed', false] == false",
   7,
   false,
   "",
   ""
  ]] remoteExec ['addAction',0,true];

  private _group = createGroup [west, true];
  [_pilot, _copilot] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Helicopters_CreateHuronArmed = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Heli_Transport_03_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Green",1],
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_BA_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_BA_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  private _crew1 = [] call PZFP_fnc_blufor_BA_Men_CreateHelicopterCrew;
  _crew1 moveInTurret [_vehicle, [1]];
  private _crew2 = [] call PZFP_fnc_blufor_BA_Men_CreateHelicopterCrew;
  _crew2 moveInTurret [_vehicle, [2]];
  _vehicle lockCargo true;
  _vehicle setVariable ["doorsClosed", true];

  [_vehicle,
  ["<img image='\a3\ui_f\data\IGUI\Cfg\Actions\open_door_ca.paa'></image><t color='#32CD32'> Open Passenger Doors</t>",
   {
    params ["_target"];
    [_target, ["Door_L_source", 1]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_R_source", 1]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_rear_source", 1]] remoteExec ['animateDoor',0,true];
    _target lockCargo false;
    _target setVariable ["doorsClosed", false];
   },
   nil,
   2,
   true,
   false,
   "",
   "_target getVariable ['doorsClosed', true] == true",
   7,
   false,
   "",
   ""
  ]] remoteExec ['addAction',0,true];

  [_vehicle,
  ["<img image='\a3\ui_f\data\IGUI\Cfg\Actions\open_door_ca.paa'></image><t color='#32CD32'> Close Passenger Doors</t>",
   {
    params ["_target"];
    [_target, ["Door_L_source", 0]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_R_source", 0]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_rear_source", 0]] remoteExec ['animateDoor',0,true];
    _target lockCargo true;
    _target setVariable ["doorsClosed", true];
   },
   nil,
   2,
   true,
   false,
   "",
   "_target getVariable ['doorsClosed', false] == false",
   7,
   false,
   "",
   ""
  ]] remoteExec ['addAction',0,true];

  private _group = createGroup [west, true];
  [_pilot, _copilot, _crew1, _crew2] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutRifleman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_plain_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_PlateCarrierL_CTRG";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellBlue";

  _helmets = ["H_HelmetB_camo","H_HelmetB_camo","H_HelmetB_snakeskin"];
  _unit addHeadgear selectRandom _helmets;
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutLAT = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_plain_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "launch_MRAWS_sand_F";
  _unit addSecondaryWeaponItem "MRAWS_HEAT_F";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_PlateCarrierH_CTRG";
  _unit addBackpack "B_Kitbag_cbr";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "MRAWS_HEAT_F";};
  _unit addItemToBackpack "MRAWS_HE_F";

  _helmets = ["H_HelmetB_camo","H_HelmetB_camo","H_HelmetB_snakeskin"];
  _unit addHeadgear selectRandom _helmets;
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutAT = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_plain_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "launch_NLAW_F";
  _unit addSecondaryWeaponItem "NLAW_F";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_PlateCarrierH_CTRG";
  _unit addBackpack "B_Kitbag_cbr";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToBackpack "NLAW_F";};

  _helmets = ["H_HelmetB_camo","H_HelmetB_camo","H_HelmetB_snakeskin"];
  _unit addHeadgear selectRandom _helmets;
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutAutorifleman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "LMG_Mk200_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "200Rnd_65x39_cased_Box";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_PlateCarrierH_CTRG";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  _unit addItemToVest "200Rnd_65x39_cased_Box_Red";
  _unit addItemToVest "200Rnd_65x39_cased_Box_Tracer_Red";
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";

  _helmets = ["H_HelmetB_camo","H_HelmetB_camo","H_HelmetB_snakeskin"];
  _unit addHeadgear selectRandom _helmets;
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutMarksman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SPAR_03_snd_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_AMS_snd";
  _unit addPrimaryWeaponItem "20Rnd_762x51_Mag";
  _unit addPrimaryWeaponItem "bipod_01_F_snd";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_PlateCarrierL_CTRG";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "20Rnd_762x51_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellBlue";
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  _helmets = ["H_HelmetB_camo","H_HelmetB_camo","H_HelmetB_snakeskin"];
  _unit addHeadgear selectRandom _helmets;
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutMachineGunner = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "MMG_02_camo_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "130Rnd_338_Mag";
  _unit addPrimaryWeaponItem "bipod_01_F_snd";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_PlateCarrierL_CTRG";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 2 do {_unit addItemToVest "130Rnd_338_Mag";};

  _helmets = ["H_HelmetB_camo","H_HelmetB_camo","H_HelmetB_snakeskin"];
  _unit addHeadgear selectRandom _helmets;
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutTeamLeader = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_GL_plain_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addPrimaryWeaponItem "1Rnd_HE_Grenade_shell";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_PlateCarrierL_CTRG";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 5 do {_unit addItemToVest "1Rnd_HE_Grenade_shell";};
  _unit addItemToVest "UGL_FlareWhite_F";
  _unit addItemToVest "1Rnd_Smoke_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeRed_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeGreen_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeBlue_Grenade_shell";
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};

  _helmets = ["H_HelmetB_camo","H_HelmetB_camo","H_HelmetB_snakeskin"];
  _unit addHeadgear selectRandom _helmets;
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutSquadLeader = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_plain_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_PlateCarrierL_CTRG";
  _unit addBackpack "B_AssaultPack_cbr";

  _unit addWeapon "Binocular";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "SmokeShellOrange";

  _helmets = ["H_HelmetB_camo","H_HelmetB_camo","H_HelmetB_snakeskin"];
  _unit addHeadgear selectRandom _helmets;
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutAmmoBearer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_plain_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_PlateCarrierL_CTRG";
  _unit addBackpack "B_Carryall_cbr";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  for "_i" from 1 to 2 do {_unit addItemToVest "SmokeShell";};
  for "_i" from 1 to 10 do {_unit addItemToBackpack "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 3 do {_unit addItemToBackpack "200Rnd_65x39_cased_Box";};
  for "_i" from 1 to 2 do {_unit addItemToBackpack "1Rnd_SmokeRed_Grenade_shell";};
  _unit addItemToBackpack "1Rnd_Smoke_Grenade_shell";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "1Rnd_SmokeBlue_Grenade_shell";};
  for "_i" from 1 to 2 do {_unit addItemToBackpack "1Rnd_SmokeGreen_Grenade_shell";};
  for "_i" from 1 to 5 do {_unit addItemToBackpack "1Rnd_HE_Grenade_shell";};

  _helmets = ["H_HelmetB_camo","H_HelmetB_camo","H_HelmetB_snakeskin"];
  _unit addHeadgear selectRandom _helmets;
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutMedic = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_plain_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_PlateCarrierGL_rgr";
  _unit addBackpack "B_Kitbag_cbr";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  for "_i" from 1 to 2 do {_unit addItemToVest "SmokeShell";};
  _unit addItemToBackpack "Medikit";
  for "_i" from 1 to 3 do {_unit addItemToBackpack "FirstAidKit";};

  _helmets = ["H_HelmetB_camo","H_HelmetB_camo","H_HelmetB_snakeskin"];
  _unit addHeadgear selectRandom _helmets;
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutRTO = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_plain_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_PlateCarrierL_CTRG";
  _unit addBackpack "B_RadioBag_01_mtp_F";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  for "_i" from 1 to 2 do {_unit addItemToVest "SmokeShell";};

  _helmets = ["H_HelmetB_camo","H_HelmetB_camo","H_HelmetB_snakeskin"];
  _unit addHeadgear selectRandom _helmets;
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutSergeant = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_plain_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_PlateCarrierH_CTRG";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellPurple";
  _unit addItemToVest "SmokeShellGreen";

  _helmets = ["H_HelmetB_camo","H_HelmetB_camo","H_HelmetB_snakeskin"];
  _unit addHeadgear selectRandom _helmets;
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutOfficer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20C_plain_F";
  _unit addPrimaryWeaponItem "optic_Holosight";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_PlateCarrierL_CTRG";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 5 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellBlue";
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};

  _helmets = ["H_HelmetB_camo","H_HelmetB_camo","H_HelmetB_snakeskin"];
  _unit addHeadgear selectRandom _helmets;
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutCrewman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20C_plain_F";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_BandollierB_rgr";
  _unit addHeadgear "H_HelmetCrew_B";
  _unit addGoggles "G_Combat";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";

  for "_i" from 1 to 4 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "SmokeShellBlue";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutEngineer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20C_plain_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Holosight";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_PlateCarrierL_CTRG";
  _unit addBackpack "B_AssaultPack_cbr";

  _helmets = ["H_HelmetB_camo","H_HelmetB_camo","H_HelmetB_snakeskin"];
  _unit addHeadgear selectRandom _helmets;
  _unit addGoggles "G_Combat";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";

  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToBackpack "ToolKit";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutExplosiveSpecialist = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20C_plain_F";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "optic_Holosight";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_PlateCarrierSpec_rgr";
  _unit addBackpack "B_Kitbag_cbr";

  _helmets = ["H_HelmetSpecB_snakeskin","H_HelmetSpecB_snakeskin","H_HelmetB_snakeskin"];
  _unit addHeadgear selectRandom _helmets;
  _unit addGoggles "G_Tactical_Clear";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";

  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToBackpack "ToolKit";
  _unit addItemToBackpack "SatchelCharge_Remote_Mag";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "DemoCharge_Remote_Mag";};

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutHelicopterPilot = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20C_plain_F";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "optic_Holosight";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_TacVest_oli";

  _unit addHeadgear "H_PilotHelmetHeli_B";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";

  for "_i" from 1 to 4 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "B_IR_Grenade";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellOrange";
  _unit addItemToVest "SmokeShellYellow";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutHelicopterCrew = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20C_plain_F";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_TacVest_oli";

  _unit addHeadgear "H_CrewHelmetHeli_B";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";

  for "_i" from 1 to 4 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "B_IR_Grenade";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellOrange";
  _unit addItemToVest "SmokeShellYellow";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutMineSpecialist = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20C_plain_F";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "optic_Holosight";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_PlateCarrierSpec_rgr";
  _unit addBackpack "B_Carryall_cbr";

  _helmets = ["H_HelmetB_camo","H_HelmetB_camo","H_HelmetB_snakeskin"];
  _unit addHeadgear selectRandom _helmets;
  _unit addGoggles "G_Combat";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";

  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";

  _unit addItemToBackpack "MineDetector";
  _unit addItemToBackpack "ATMine_Range_Mag";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "APERSMineDispenser_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToBackpack "APERSBoundingMine_Range_Mag";};

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutSurvivor = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit forceAddUniform "U_B_CTRG_1";
 };

 PZFP_fnc_blufor_BA_Men_AddLoadoutUAVOperator = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addWeapon "arifle_Mk20_plain_F";
  _unit addPrimaryWeaponItem "optic_ERCO_snd_F";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_B_CTRG_1";
  _unit addVest "V_PlateCarrierL_CTRG";

  _helmets = ["H_HelmetB_camo","H_HelmetB_camo","H_HelmetB_snakeskin"];
  _unit addHeadgear selectRandom _helmets;
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";

  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "B_UavTerminal";
  _unit linkItem "NVGoggles";
 };

 PZFP_fnc_blufor_BA_Men_CreateRifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutRifleman;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateLAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_LAT_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutLAT;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_AT_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutAT;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateAutorifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_AR_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutAutorifleman;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateMarksman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_M_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutMarksman;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateMachineGunner = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_support_MG_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutMachineGunner;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateTeamLeader = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_TL_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutTeamLeader;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
  };

 PZFP_fnc_blufor_BA_Men_CreateSquadLeader = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_SL_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutSquadLeader;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateAmmoBearer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_A_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutAmmoBearer;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateMedic = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_medic_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutMedic;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateRTO = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_W_RadioOperator_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutRTO;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateSergeant = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["C_Marshal_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] joinSilent _group;
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutSergeant;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateOfficer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_officer_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutOfficer;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateCrewman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_crew_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutCrewman;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateEngineer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_engineer_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutEngineer;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateExplosiveSpecialist = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_EXP_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutExplosiveSpecialist;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateHelicopterPilot = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_HeliPilot_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutHelicopterPilot;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  };
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateHelicopterCrew = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_HeliCrew_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutHelicopterCrew;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateMineSpecialist = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_mine_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutMineSpecialist;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateSurvivor = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Survivor_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutSurvivor;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Men_CreateUAVOperator = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_UAV_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_BA_Men_AddLoadoutUAVOperator;
   [_unit] call PZFP_fnc_blufor_UK_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_BA_Tanks_CreateSquadLeaderammer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_MBT_01_Cannon_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  private _group = createGroup [west, true];
  [_driver, _gunner] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Tanks_CreateSquadLeaderammerUP = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_MBT_01_TUSK_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  private _group = createGroup [west, true];
  [_driver, _gunner] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Turrets_CreateRadar = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Radar_System_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Olive",1],
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Turrets_CreateSAM = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_SAM_System_03_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Olive",1],
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Turrets_CreateHMGTripod = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_HMG_01_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Turrets_CreateHMGRaised = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_HMG_01_high_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Turrets_CreateHMGAuto = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_HMG_01_A_F",_position,[],0,"NONE"];

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Turrets_CreateGMGTripod = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_GMG_01_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Turrets_CreateGMGRaised = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_GMG_01_high_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Turrets_CreateGMGAuto = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_GMG_01_A_F",_position,[],0,"NONE"];

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Turrets_CreateMortar = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Mortar_01_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Turrets_CreatePraetorian = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_AAA_System_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Green",1],
   true
  ] call BIS_fnc_initVehicle;

  _vehicle removeWeaponTurret["weapon_Cannon_Phalanx",[0]];
  _vehicle addWeaponTurret["gatling_20mm_VTOL_01",[0]];
  _vehicle addMagazineTurret["4000Rnd_20mm_Tracer_Red_shells",[0]];

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];
  crew _vehicle select 0 setSkill 1;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Turrets_CreateDesignator = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Static_Designator_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Desert",1],
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Turrets_CreateAA = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Static_AA_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_BA_Turrets_CreateAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Static_AT_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_BA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFAF_Pilots_AddLoadoutFighterPilot = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "hgun_PDW2000_F";
  _unit addPrimaryWeaponItem "optic_Holosight_smg_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_9x21_Yellow_Mag";

  _unit forceAddUniform "U_I_pilotCoveralls";

  _unit addItemToUniform "FirstAidKit";
  for "_i" from 1 to 2 do {_unit addItemToUniform "30Rnd_9x21_Mag";};
  _unit addItemToUniform "I_IR_Grenade";
  _unit addItemToUniform "SmokeShellBlue";
  _unit addItemToUniform "SmokeShellOrange";
  _unit addItemToUniform "SmokeShellPurple";
  _unit addItemToUniform "SmokeShell";
  for "_i" from 1 to 2 do {_unit addItemToUniform "Chemlight_yellow";};
  _unit addHeadgear "H_PilotHelmetFighter_I";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
 };

 PZFP_fnc_blufor_AAFAF_Pilots_CreateFighterPilot = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Fighter_Pilot_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_AAFAF_Pilots_AddLoadoutFighterPilot;
    [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };
  
 PZFP_fnc_blufor_AAFAF_Planes_CreateBuzzard = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_Plane_Fighter_03_dynamicLoadout_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Green",1], 
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_AAFAF_Pilots_CreateFighterPilot;
  _pilot moveInDriver _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
  };
 
 PZFP_fnc_blufor_AAFAF_Planes_CreateGryphon = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_Plane_Fighter_04_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Green",1], 
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_AAFAF_Pilots_CreateFighterPilot;
  _pilot moveInDriver _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_AntiAir_CreateNyx	= {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_LT_01_AA_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Indep_02",1],
   ["showTools",selectRandom[0,1,1],"showCamonetHull",0,"showBags",selectRandom[0,1],"showSLATHull",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_AAFA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;

  private _group = createGroup [west, true];
  [_gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Artillery_CreateZamak = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_Truck_02_MRL_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Indep",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;
  [_driver, _gunner] joinSilent createGroup [west, true];
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_APC_CreateGorgon = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_APC_Wheeled_03_cannon_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Indep",1],
   ["showCamonetHull",0,"showBags",selectRandom[0,1],"showBags2",selectRandom[0,1],"showTools",selectRandom[0,1],"showSLATHull",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_AAFA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_AAFA_Men_CreateCrewman;
  _commander moveInCommander _vehicle;

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_APC_CreateMora = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_APC_tracked_03_cannon_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Indep",1],
   ["showCamonetHull",0,"showBags",selectRandom[0,1],"showBags2",selectRandom[0,1],"showTools",selectRandom[0,1],"showSLATHull",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_AAFA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_AAFA_Men_CreateCrewman;
  _commander moveInCommander _vehicle;

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Boats_CreateAssaultBoat = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_Boat_Transport_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Black",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Boats_CreateRescueBoat = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Lifeboat",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Rescue",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Boats_CreateRHIB = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_C_Boat_Transport_02_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Black",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Cars_CreateStrider = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_MRAP_03_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Indep",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;

  private _group = createGroup [west, true];
  [_driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Cars_CreateStriderHMG = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_MRAP_03_hmg_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Indep",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
  _commander moveInTurret [_vehicle, [1]];

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Cars_CreateStriderGMG = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_MRAP_03_gmg_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Indep",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
  _commander moveInTurret [_vehicle, [1]];

  private _group = createGroup [west, true];
  [_commander, _gunner, _driver] joinSilent _group;
  _group setBehaviour "SAFE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Cars_CreateZamak = {
   private _cursorPos = getMousePosition;
   private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
   _vehicle = createVehicle ["I_Truck_02_mover_F",_position,[],0,"NONE"];
   [
    _vehicle,
    ["Blufor",1],
    true
   ] call BIS_fnc_initVehicle;

   private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
   _driver moveInDriver _vehicle;

   private _group = createGroup [west, true];
   [_driver] joinSilent _group;
   _group setBehaviour "SAFE";

   getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Cars_CreateZamakAmmo = {
   private _cursorPos = getMousePosition;
   private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
   _vehicle = createVehicle ["I_Truck_02_ammo_F",_position,[],0,"NONE"];
   [
    _vehicle,
    ["Blufor",1],
    true
   ] call BIS_fnc_initVehicle;

   private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
   _driver moveInDriver _vehicle;

   private _group = createGroup [west, true];
   [_driver] joinSilent _group;
   _group setBehaviour "SAFE";

   getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
  };

  PZFP_fnc_blufor_AAFA_Cars_CreateZamakFuel = {
   private _cursorPos = getMousePosition;
   private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
   _vehicle = createVehicle ["I_Truck_02_fuel_F",_position,[],0,"NONE"];
   [
    _vehicle,
    ["Blufor",1],
    true
   ] call BIS_fnc_initVehicle;

   private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
   _driver moveInDriver _vehicle;

   private _group = createGroup [west, true];
   [_driver] joinSilent _group;
   _group setBehaviour "SAFE";

   getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Cars_CreateZamakMedical = {
   private _cursorPos = getMousePosition;
   private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
   _vehicle = createVehicle ["I_Truck_02_medical_F",_position,[],0,"NONE"];
   [
    _vehicle,
    ["Blufor",1],
    true
   ] call BIS_fnc_initVehicle;

   private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
   _driver moveInDriver _vehicle;

   private _group = createGroup [west, true];
   [_driver] joinSilent _group;
   _group setBehaviour "SAFE";

   getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Cars_CreateZamakRepair = {
   private _cursorPos = getMousePosition;
   private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
   _vehicle = createVehicle ["I_Truck_02_box_F",_position,[],0,"NONE"];
   [
    _vehicle,
    ["Blufor",1],
    true
   ] call BIS_fnc_initVehicle;

   private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
   _driver moveInDriver _vehicle;

   private _group = createGroup [west, true];
   [_driver] joinSilent _group;
   _group setBehaviour "SAFE";

   getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Cars_CreateZamakTransport = {
   private _cursorPos = getMousePosition;
   private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
   _vehicle = createVehicle ["I_Truck_02_transport_F",_position,[],0,"NONE"];
   [
    _vehicle,
    ["Blufor",1],
    true
   ] call BIS_fnc_initVehicle;

   private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
   _driver moveInDriver _vehicle;

   private _group = createGroup [west, true];
   [_driver] joinSilent _group;
   _group setBehaviour "SAFE";

   getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Cars_CreateZamakCovered = {
   private _cursorPos = getMousePosition;
   private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
   _vehicle = createVehicle ["I_Truck_02_covered_F",_position,[],0,"NONE"];
   [
    _vehicle,
    ["Blufor",1],
    true
   ] call BIS_fnc_initVehicle;

   private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
   _driver moveInDriver _vehicle;

   private _group = createGroup [west, true];
   [_driver] joinSilent _group;
   _group setBehaviour "SAFE";

   getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Drones_CreatePelican = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_UAV_06_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   ["lights_em_hide",0,"LED_lights_hide",1,"Inventory_door",0]
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Drones_CreatePelicanMedical = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_UAV_06_medical_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   ["lights_em_hide",0,"LED_lights_hide",1,"Inventory_door",0]
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Helicopters_CreateMohawk = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_Heli_Transport_02_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_AAFA_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_AAFA_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  crew _vehicle join createGroup [west, true];
  _vehicle lockCargo true;
  _vehicle setVariable ["doorsClosed", true];

  [_vehicle,
  ["<img image='\a3\ui_f\data\IGUI\Cfg\Actions\open_door_ca.paa'></image><t color='#32CD32'> Open Passenger Doors</t>",
   {
    params ["_target"];
    [_target, ["Door_Back_L", 1]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_Back_R", 1]] remoteExec ['animateDoor',0,true];
    [_target, ["CargoRamp_Open", 1]] remoteExec ['animateDoor',0,true];
    _target lockCargo false;
    _target setVariable ["doorsClosed", false];
   },
   nil,
   2,
   true,
   false,
   "",
   "_target getVariable ['doorsClosed', true] == true",
   7,
   false,
   "",
   ""
  ]] remoteExec ['addAction',0,true];

  [_vehicle,
  ["<img image='\a3\ui_f\data\IGUI\Cfg\Actions\open_door_ca.paa'></image><t color='#32CD32'> Close Passenger Doors</t>",
   {
    params ["_target"];
    [_target, ["Door_Back_L", 0]] remoteExec ['animateDoor',0,true];
    [_target, ["Door_Back_R", 0]] remoteExec ['animateDoor',0,true];
    [_target, ["CargoRamp_Open", 0]] remoteExec ['animateDoor',0,true];
    _target lockCargo true;
    _target setVariable ["doorsClosed", true];
   },
   nil,
   2,
   true,
   false,
   "",
   "_target getVariable ['doorsClosed', false] == false",
   7,
   false,
   "",
   ""
  ]] remoteExec ['addAction',0,true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Helicopters_CreateHellcat = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_Heli_Light_03_unarmed_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Indep",1],
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_AAFA_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_AAFA_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Helicopters_CreateHellcatArmed = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_Heli_Light_03_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Indep",1],
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_AAFA_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_AAFA_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Helicopters_CreateHummingbird = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Heli_Light_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;
  [_vehicle, [0, "A3\Air_F\Heli_Light_01\Data\heli_light_01_ext_indp_co.paa"]] remoteExec ['setObjectTexture',0,true];

  private _pilot = [] call PZFP_fnc_blufor_AAFA_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_AAFA_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Helicopters_CreatePawnee = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_Heli_Light_01_dynamicLoadout_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Blufor",1],
   true
  ] call BIS_fnc_initVehicle;
  [_vehicle, [0, "A3\Air_F\Heli_Light_01\Data\heli_light_01_ext_indp_co.paa"]] remoteExec ['setObjectTexture',0,true];

  private _pilot = [] call PZFP_fnc_blufor_AAFA_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_AAFA_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutRifleman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_MRCO";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_PlateCarrierIA1_dgtl";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_green";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetIA";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutLAT = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_MRCO";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "launch_MRAWS_green_rail_F";
  _unit addSecondaryWeaponItem "MRAWS_HEAT_F";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_PlateCarrierIA2_dgtl";
  _unit addBackpack "B_Kitbag_rgr";
  [backpackContainer _unit, [0, "A3\weapons_f\ammoboxes\bags\data\backpack_fast_digi_co.paa"]] remoteExec ['setObjectTexture',0,true];

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "MRAWS_HEAT_F";};
  _unit addItemToBackpack "MRAWS_HE_F";
  _unit addHeadgear "H_HelmetIA";
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutAT = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_MRCO";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "launch_NLAW_F";
  _unit addSecondaryWeaponItem "NLAW_F";
  _unit addWeapon "hgun_ACPC2_F";
  _unit addHandgunItem "9Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_PlateCarrierIA2_dgtl";
  _unit addBackpack "B_Kitbag_rgr";
  [backpackContainer _unit, [0, "A3\weapons_f\ammoboxes\bags\data\backpack_fast_digi_co.paa"]] remoteExec ['setObjectTexture',0,true];

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  for "_i" from 1 to 2 do {_unit addItemToVest "9Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToBackpack "NLAW_F";};
  _unit addHeadgear "H_HelmetIA";
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutAutorifleman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "LMG_Mk200_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "200Rnd_65x39_cased_Box";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_PlateCarrierIA2_dgtl";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  _unit addItemToVest "200Rnd_65x39_cased_Box_Red";
  _unit addItemToVest "200Rnd_65x39_cased_Box_Tracer_Red";
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addHeadgear "H_HelmetIA";
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutMarksman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "srifle_EBR_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_AMS_snd";
  _unit addPrimaryWeaponItem "20Rnd_762x51_Mag";
  _unit addPrimaryWeaponItem "bipod_01_F_snd";
  _unit addWeapon "hgun_ACPC2_F";
  _unit addHandgunItem "9Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_PlateCarrierIA2_dgtl";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "20Rnd_762x51_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellBlue";
  for "_i" from 1 to 2 do {_unit addItemToVest "9Rnd_45ACP_Mag";};
  _unit addHeadgear "H_HelmetIA";
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutTeamLeader = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_GL_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_MRCO";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addPrimaryWeaponItem "1Rnd_HE_Grenade_shell";
  _unit addWeapon "hgun_ACPC2_F";
  _unit addHandgunItem "9Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_PlateCarrierIA2_dgtl";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 5 do {_unit addItemToVest "1Rnd_HE_Grenade_shell";};
  _unit addItemToVest "UGL_FlareWhite_F";
  _unit addItemToVest "1Rnd_Smoke_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeRed_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeGreen_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeBlue_Grenade_shell";
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  for "_i" from 1 to 2 do {_unit addItemToVest "9Rnd_45ACP_Mag";};
  _unit addHeadgear "H_HelmetIA";
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutSquadLeader = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_MRCO";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_PlateCarrierIA1_dgtl";
  _unit addBackpack "B_AssaultPack_dgtl";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Chemlight_green";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetIA";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutAmmoBearer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_MRCO";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "hgun_ACPC2_F";
  _unit addHandgunItem "9Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_PlateCarrierIA2_dgtl";
  _unit addBackpack "B_Kitbag_rgr";
  [backpackContainer _unit, [0, "A3\weapons_f\ammoboxes\bags\data\backpack_fast_digi_co.paa"]] remoteExec ['setObjectTexture',0,true];

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  for "_i" from 1 to 2 do {_unit addItemToVest "9Rnd_45ACP_Mag";};

  for "_i" from 1 to 10 do {_unit addItemToBackpack "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 3 do {_unit addItemToBackpack "1Rnd_HE_Grenade_shell";};
  for "_i" from 1 to 3 do {_unit addItemToBackpack "1Rnd_Smoke_Grenade_shell";};
  _unit addHeadgear "H_HelmetIA";
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutMedic = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_MRCO";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "hgun_ACPC2_F";
  _unit addHandgunItem "9Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_PlateCarrierIAGL_dgtl";
  _unit addBackpack "B_Kitbag_rgr";
  [backpackContainer _unit, [0, "A3\weapons_f\ammoboxes\bags\data\backpack_fast_digi_co.paa"]] remoteExec ['setObjectTexture',0,true];

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "9Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  for "_i" from 1 to 2 do {_unit addItemToVest "SmokeShell";};
  _unit addItemToBackpack "Medikit";
  for "_i" from 1 to 3 do {_unit addItemToBackpack "FirstAidKit";};
  _unit addHeadgear "H_HelmetIA";
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutRTO = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_MRCO";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "hgun_ACPC2_F";
  _unit addHandgunItem "9Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_PlateCarrierIA2_dgtl";
  _unit addBackpack "B_RadioBag_01_digi_F";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "9Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  for "_i" from 1 to 2 do {_unit addItemToVest "SmokeShell";};
  _unit addHeadgear "H_HelmetIA";
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutSergeant = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_MRCO";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "hgun_ACPC2_F";
  _unit addHandgunItem "9Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_PlateCarrierIA2_dgtl";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "9Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellPurple";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetIA";
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutOfficer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20C_F";
  _unit addPrimaryWeaponItem "optic_Holosight_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "hgun_ACPC2_F";
  _unit addHandgunItem "9Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_PlateCarrierIA2_dgtl";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 5 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellBlue";
  for "_i" from 1 to 2 do {_unit addItemToVest "9Rnd_45ACP_Mag";};
  _unit addHeadgear "H_HelmetIA";
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_MenAddLoadoutCrewman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;
  
  _unit addWeapon "hgun_PDW2000_F";
  _unit addPrimaryWeaponItem "optic_Holosight_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_9x21_Mag";
  
  _unit forceAddUniform "U_Tank_green_F";
  _unit addVest "V_CarrierRigKBT_01_Olive_F";
  
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 2 do {_unit addItemToVest "30Rnd_9x21_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellPurple";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetCrew_I";
  _unit addGoggles "G_Combat";
  
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutEngineer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Holosight_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "hgun_ACPC2_F";
  _unit addHandgunItem "9Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_PlateCarrierIA2_dgtl";
  _unit addBackpack "B_Kitbag_rgr";
  [backpackContainer _unit, [0, "A3\weapons_f\ammoboxes\bags\data\backpack_fast_digi_co.paa"]] remoteExec ['setObjectTexture',0,true];

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "9Rnd_45ACP_Mag";};
  _unit addItemToVest "HandGrenade";
  _unit addItemToVest "SmokeShell";
  _unit addItemToBackpack "Toolkit";
  _unit addItemToBackpack "MineDetector";
  _unit addHeadgear "H_HelmetIA";
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutExplosiveSpecialist = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Holosight_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "hgun_ACPC2_F";
  _unit addHandgunItem "9Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_PlateCarrierIAGL_dgtl";
  _unit addBackpack "B_Kitbag_rgr";
  [backpackContainer _unit, [0, "A3\weapons_f\ammoboxes\bags\data\backpack_fast_digi_co.paa"]] remoteExec ['setObjectTexture',0,true];

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "9Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToBackpack "DemoCharge_Remote_Mag";
  _unit addItemToBackpack "SatchelCharge_Remote_Mag";
  _unit addHeadgear "H_HelmetIA";
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutHelicopterPilot = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "SMG_03C_camo";
  _unit addPrimaryWeaponItem "50Rnd_570x28_SMG_03";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_TacVest_oli";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 4 do {_unit addItemToVest "50Rnd_570x28_SMG_03";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_PilotHelmetHeli_I";

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";

  comment 'Use this for opfor:
  _unit addWeapon "hgun_ACPC2_F";
  _unit addHandgunItem "9Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_HelicopterPilotCoveralls";
  _unit addVest "V_TacVest_camo";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "HandGrenade";

  _helmets = ["H_PilotHelmetHeli_B","H_PilotHelmetHeli_B","H_PilotHelmetHeli_B"];
  _unit addHeadgear selectRandom _helmets;
  _goggles = ["G_Shades_Black","G_Shades_Black","G_Combat",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
  ';
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutHelicopterCrew = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Holosight_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_TacVest_oli";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 4 do {_unit addItemToVest "30rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_CrewHelmetHeli_I";

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutMineSpecialist = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Holosight_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addWeapon "hgun_ACPC2_F";
  _unit addHandgunItem "9Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_PlateCarrierIAGL_dgtl";
  _unit addBackpack "B_Kitbag_rgr";
  [backpackContainer _unit, [0, "A3\weapons_f\ammoboxes\bags\data\backpack_fast_digi_co.paa"]] remoteExec ['setObjectTexture',0,true];

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "9Rnd_45ACP_Mag";};
  _unit addItemToVest "HandGrenade";
  _unit addItemToVest "SmokeShell";
  _unit addItemToBackpack "APERSBoundingMine_Range_Mag";
  _unit addItemToBackpack "APERSMine_Range_Mag";
  _unit addItemToBackpack "IEDLandSmall_Remote_Mag";
  _unit addHeadgear "H_HelmetIA";
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutSurvivor = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit forceAddUniform "U_I_CombatUniform_shortsleeve";
  _unit addVest "V_TacVest_camo";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
 };

 PZFP_fnc_blufor_AAFA_Men_AddLoadoutUAVOperator = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Mk20_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Holosight_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_PlateCarrierIA2_dgtl";

  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_blue";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "9Rnd_45ACP_Mag";};
  _unit addItemToVest "HandGrenade";
  _unit addItemToVest "SmokeShell";
  _unit addHeadgear "H_HelmetIA";
  _goggles = ["G_Tactical_Clear","G_Tactical_Clear","G_Tactical_Clear","G_Combat","G_Combat","G_Combat","G_Spectacles_Tinted","G_Squares_Tinted",""];
  _unit addGoggles selectRandom _goggles;

  _unit linkItem "ItemCompass";
  _unit linkItem "ItemMap";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "I_UavTerminal";
 };

 PZFP_fnc_blufor_AAFA_Men_CreateRifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutRifleman;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateLAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_LAT_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutLAT;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_AT_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutAT;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateAutorifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_AR_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutAutorifleman;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateMarksman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_M_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutMarksman;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateTeamLeader = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_TL_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutTeamLeader;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateSquadLeader = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_SL_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutSquadLeader;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateAmmoBearer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_A_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutAmmoBearer;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateMedic = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_medic_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutMedic;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateRTO = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_W_RadioOperator_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutRTO;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateSergeant = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["C_Marshal_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] joinSilent _group;
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutSergeant;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateOfficer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_officer_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutOfficer;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateCrewman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_crew_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_MenAddLoadoutCrewman;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateEngineer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_engineer_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutEngineer;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateExplosiveSpecialist = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_EXP_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutExplosiveSpecialist;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateHelicopterPilot = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_HeliPilot_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutHelicopterPilot;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateHelicopterCrew = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_HeliCrew_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutHelicopterCrew;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateMineSpecialist = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_mine_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutMineSpecialist;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateSurvivor = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Survivor_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutSurvivor;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Men_CreateUAVOperator = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_UAV_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_Men_AddLoadoutUAVOperator;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  private _curator = getAssignedCuratorLogic player;
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit 
 };

 PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutRifleman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SPAR_02_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit removePrimaryWeaponItem "bipod_01_F_blk";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_CarrierRigKBT_01_light_Olive_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_M";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "I_IR_Grenade";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetHBK_F";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutRiflemanLAT = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SPAR_02_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit removePrimaryWeaponItem "bipod_01_F_blk";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addWeapon "launch_MRAWS_olive_F";
  _unit addSecondaryWeaponItem "MRAWS_HEAT_F";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_CarrierRigKBT_01_light_Olive_F";
  _unit addBackpack "B_Kitbag_rgr";
  [backpackContainer _unit, [0, "A3\weapons_f\ammoboxes\bags\data\backpack_fast_digi_co.paa"]] remoteExec ['setObjectTexture',0,true];

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_M";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "I_IR_Grenade";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "MRAWS_HEAT_F";};
  _unit addItemToBackpack "MRAWS_HE_F";
  _unit addHeadgear "H_HelmetHBK_F";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutRiflemanAT = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SPAR_02_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit removePrimaryWeaponItem "bipod_01_F_blk";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addWeapon "launch_NLAW_F";
  _unit addSecondaryWeaponItem "NLAW_F";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_CarrierRigKBT_01_light_Olive_F";
  _unit addBackpack "B_Kitbag_rgr";
  [backpackContainer _unit, [0, "A3\weapons_f\ammoboxes\bags\data\backpack_fast_digi_co.paa"]] remoteExec ['setObjectTexture',0,true];

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_M";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "I_IR_Grenade";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "NLAW_F";};
  _unit addHeadgear "H_HelmetHBK_F";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutAutorifleman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SPAR_02_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_MRCO";
  _unit addPrimaryWeaponItem "150Rnd_556x45_Drum_Mag_F";
  _unit addPrimaryWeaponItem "bipod_01_F_blk";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_CarrierRigKBT_01_light_Olive_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_M";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 3 do {_unit addItemToVest "150Rnd_556x45_Drum_Mag_F";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "I_IR_Grenade";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetHBK_F";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutMarksman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SPAR_03_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_AMS";
  _unit addPrimaryWeaponItem "20Rnd_762x51_Mag";
  _unit addPrimaryWeaponItem "bipod_01_F_blk";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_CarrierRigKBT_01_light_Olive_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_B";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "20Rnd_762x51_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "I_IR_Grenade";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetHBK_F";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutTeamLeader = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SPAR_01_GL_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit addPrimaryWeaponItem "1Rnd_HE_Grenade_shell";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_CarrierRigKBT_01_light_Olive_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_M";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 5 do {_unit addItemToVest "1Rnd_HE_Grenade_shell";};
  _unit addItemToVest "UGL_FlareCIR_F";
  _unit addItemToVest "1Rnd_Smoke_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeRed_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeGreen_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeYellow_Grenade_shell";
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addHeadgear "H_HelmetHBK_F";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutSquadLeader = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SPAR_02_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit removePrimaryWeaponItem "bipod_01_F_blk";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_CarrierRigKBT_01_light_Olive_F";
  _unit addBackpack "B_AssaultPack_dgtl";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_M";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "I_IR_Grenade";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetHBK_F";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutJTAC = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SPAR_02_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit removePrimaryWeaponItem "bipod_01_F_blk";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_CarrierRigKBT_01_light_Olive_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_M";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Laserbatteries";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "I_IR_Grenade";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetHBK_F";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "Laserdesignator_03";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutMedic = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SPAR_02_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit removePrimaryWeaponItem "bipod_01_F_blk";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_CarrierRigKBT_01_light_Olive_F";
  _unit addBackpack "B_Kitbag_rgr";
  [backpackContainer _unit, [0, "A3\weapons_f\ammoboxes\bags\data\backpack_fast_digi_co.paa"]] remoteExec ['setObjectTexture',0,true];

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_M";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "I_IR_Grenade";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToBackpack "Medikit";
  for "_i" from 1 to 5 do {_unit addItemToBackpack "FirstAidKit";};
  _unit addHeadgear "H_HelmetHBK_F";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutRTO = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SPAR_02_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit removePrimaryWeaponItem "bipod_01_F_blk";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_CarrierRigKBT_01_light_Olive_F";
  _unit addBackpack "B_RadioBag_01_digi_f";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_M";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "I_IR_Grenade";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetHBK_F";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutAmmoBearer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SPAR_02_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit removePrimaryWeaponItem "bipod_01_F_blk";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_CarrierRigKBT_01_light_Olive_F";
  _unit addBackpack "B_Carryall_oli";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_M";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "I_IR_Grenade";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  for "_i" from 1 to 10 do {_unit addItemToBackpack "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 5 do {_unit addItemToBackpack "150Rnd_556x45_Drum_Mag_F";};
  for "_i" from 1 to 5 do {_unit addItemToBackpack "HandGrenade";};
  _unit addItemToBackpack "SmokeShellRed";
  for "_i" from 1 to 3 do {_unit addItemToBackpack "SmokeShell";};
  _unit addItemToBackpack "SmokeShellBlue";
  _unit addHeadgear "H_HelmetHBK_F";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutDemoSpecialist = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SPAR_02_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit removePrimaryWeaponItem "bipod_01_F_blk";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_CarrierRigKBT_01_light_Olive_F";
  _unit addBackpack "B_Kitbag_rgr";
  [backpackContainer _unit, [0, "A3\weapons_f\ammoboxes\bags\data\backpack_fast_digi_co.paa"]] remoteExec ['setObjectTexture',0,true];

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_M";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "I_IR_Grenade";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  for "_i" from 1 to 3 do {_unit addItemToBackpack "DemoCharge_Remote_Mag";};
  _unit addHeadgear "H_HelmetHBK_F";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutEngineer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SPAR_02_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit removePrimaryWeaponItem "bipod_01_F_blk";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_CarrierRigKBT_01_light_Olive_F";
  _unit addBackpack "B_Kitbag_rgr";
  [backpackContainer _unit, [0, "A3\weapons_f\ammoboxes\bags\data\backpack_fast_digi_co.paa"]] remoteExec ['setObjectTexture',0,true];

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_M";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "I_IR_Grenade";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToBackpack "ToolKit";
  _unit addHeadgear "H_HelmetHBK_F";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutSniper = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "srifle_GM6_F";
  _unit addPrimaryWeaponItem "optic_AMS";
  _unit addPrimaryWeaponItem "5Rnd_127x108_Mag";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "muzzle_snds_acp";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit addWeapon "Rangefinder";

  _unit forceAddUniform "U_I_FullGhillie_sard";
  _unit addVest "V_Chestrig_rgr";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 4 do {_unit addItemToVest "5Rnd_127x108_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellBlue";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "B_IR_Grenade";
  _unit addItemToVest "ClaymoreDirectionalMine_Remote_Mag";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutSpotter = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SPAR_02_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_MRCO";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit removePrimaryWeaponItem "bipod_01_F_blk";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "muzzle_snds_acp";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit addWeapon "Rangefinder";

  _unit forceAddUniform "U_I_FullGhillie_sard";
  _unit addVest "V_CarrierRigKBT_01_light_Olive_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_M";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "I_IR_Grenade";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutSergeant = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SPAR_02_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit removePrimaryWeaponItem "bipod_01_F_blk";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_CarrierRigKBT_01_light_Olive_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_M";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "I_IR_Grenade";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetHBK_F";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutOfficer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_SPAR_02_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Hamr";
  _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag_red";
  _unit removePrimaryWeaponItem "bipod_01_F_blk";
  _unit addWeapon "hgun_Pistol_heavy_01_F";
  _unit addHandgunItem "optic_MRD";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_CombatUniform";
  _unit addVest "V_CarrierRigKBT_01_light_Olive_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "muzzle_snds_M";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_556x45_Stanag_red";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "I_IR_Grenade";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetHBK_F";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_AAFA_MenSOF_CreateRifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutRifleman;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_MenSOF_CreateRifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutRifleman;
    [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_MenSOF_CreateRiflemanLAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_LAT_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutRiflemanLAT;
    [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_MenSOF_CreateRiflemanAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_AT_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
   [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutRiflemanAT;
    [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_MenSOF_CreateAutorifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_AR_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutAutorifleman;
    [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_MenSOF_CreateMarksman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_M_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutMarksman;
    [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_MenSOF_CreateTeamLeader = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_TL_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
   [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutTeamLeader;
    [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_MenSOF_CreateSquadLeader = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_SL_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutSquadLeader;
    [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_MenSOF_CreateJTAC = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_CTRG_soldier_JTAC_tna_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutJTAC;
    [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
  };

 PZFP_fnc_blufor_AAFA_MenSOF_CreateMedic = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_medic_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutMedic;
    [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_MenSOF_CreateRTO = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_W_RadioOperator_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutRTO;
    [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_MenSOF_CreateAmmoBearer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Soldier_A_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutAmmoBearer;
    [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_MenSOF_CreateDemoSpecialist = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_CTRG_Soldier_Exp_tna_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutDemoSpecialist;
    [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_MenSOF_CreateEngineer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_engineer_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutEngineer;
    [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_MenSOF_CreateSniper = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_sniper_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutSniper;
    [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_MenSOF_CreateSpotter = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_spotter_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutSpotter;
    [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_MenSOF_CreateSergeant = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["C_Marshal_F", _position, [], 0, "CAN_COLLIDE"];
  [_unit] joinSilent _group;
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutSergeant;
    [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_MenSOF_CreateOfficer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_officer_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_AAFA_MenSOF_AddLoadoutOfficer;
    [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_AAFA_Tanks_CreateKuma = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["I_MBT_03_cannon_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Indep_01",1],
   ["HideTurret",selectRandom[0,1],"HideHull",selectRandom[0,1],"showCamonetHull",0,"showCamonetTurret",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_AAFA_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_AAFA_Men_CreateCrewman;
  _commander moveInCommander _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Tanks_CreateNyxRecon = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["I_LT_01_scout_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Indep_01",1],
   ["showTools",selectRandom[0,1],"showCamonetHull",0,"showBags",selectRandom[0,1],"showSLATHull",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _commander = [] call PZFP_fnc_blufor_AAFA_Men_CreateCrewman;
  _commander moveInCommander _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Tanks_CreateNyxAutocannon = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["I_LT_01_cannon_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Indep_01",1],
   ["showTools",selectRandom[0,1],"showCamonetHull",0,"showBags",selectRandom[0,1],"showSLATHull",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _commander = [] call PZFP_fnc_blufor_AAFA_Men_CreateCrewman;
  _commander moveInGunner _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Tanks_CreateNyxAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["I_LT_01_AT_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Indep_01",1],
   ["showTools",selectRandom[0,1],"showCamonetHull",0,"showBags",selectRandom[0,1],"showSLATHull",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_AAFA_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _commander = [] call PZFP_fnc_blufor_AAFA_Men_CreateCrewman;
  _commander moveInGunner _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Turrets_CreateHMG = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_HMG_02_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Turrets_CreateHMGTripod = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_HMG_02_high_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Turrets_CreateAA = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_Static_AA_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_AAFA_Turrets_CreateAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_Static_AT_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_AAFA_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDFAF_AddLoadoutFighterPilot = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "hgun_PDW2000_F";
  _unit addPrimaryWeaponItem "optic_Holosight_smg_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_9x21_Yellow_Mag";

  _unit forceAddUniform "U_I_pilotCoveralls";

  _unit addItemToUniform "FirstAidKit";
  for "_i" from 1 to 2 do {_unit addItemToUniform "30Rnd_9x21_Mag";};
  _unit addItemToUniform "I_IR_Grenade";
  _unit addItemToUniform "SmokeShellBlue";
  _unit addItemToUniform "SmokeShellOrange";
  _unit addItemToUniform "SmokeShellPurple";
  _unit addItemToUniform "SmokeShell";
  for "_i" from 1 to 2 do {_unit addItemToUniform "Chemlight_yellow";};
  _unit addHeadgear "H_PilotHelmetFighter_I";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
 };

 PZFP_fnc_blufor_LDFAF_Pilots_CreateFighterPilot = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_Fighter_Pilot_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDFAF_AddLoadoutFighterPilot;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };

  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };
 
 PZFP_fnc_blufor_LDFAF_Planes_CreateGryphon = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_Plane_Fighter_04_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["CamoGrey",1], 
   true
  ] call BIS_fnc_initVehicle;
  [_vehicle, [0, "#(argb,8,8,3)color(0.1,0.1,0.1,1)"]] remoteExec ['setObjectTexture',0,true];
  [_vehicle, ["clan", "\a3\UI_F_Enoch\Data\CfgMarkers\Livonia_CA.paa"]] remoteExec ['setObjectTexture',0,true];

  private _pilot = [] call PZFP_fnc_blufor_LDFAF_Pilots_CreateFighterPilot;
  _pilot moveInDriver _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_APCs_CreateOdyniec = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_APC_tracked_03_cannon_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["EAF",1], 
   ["HideTurret",selectRandom[0,1],"HideHull",selectRandom[0,1],"showCamonetHull",0,"showCamonetTurret",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_LDF_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_LDF_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  private _commander = [] call PZFP_fnc_blufor_LDF_Men_CreateCrewman;
  _commander moveInCommander _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Artillery_CreateSandstorm = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_MBT_01_mlrs_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Olive",1], 
   ["showCamonetTurret",0,"showCamonetHull",0]
  ] call BIS_fnc_initVehicle;
  [_vehicle, [0, "a3\soft_f_enoch\truck_02\data\truck_02_repair_eaf_co.paa"]] remoteExec ['setObjectTexture',0,true];

  private _driver = [] call PZFP_fnc_blufor_LDF_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_LDF_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Artillery_CreateZamak = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Truck_02_MRL_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["EAF",1], 
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Cars_CreateOffroad = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Offroad_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["EAF",1], 
   ["HideDoor1",0,"HideDoor2",0,"HideDoor3",0,"HideBackpacks",1,"HideBumper1",1,"HideBumper2",0,"HideConstruction",0,"hidePolice",1,"HideServices",1,"BeaconsStart",0,"BeaconsServicesStart",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Cars_CreateOffroadMG = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_G_Offroad_01_armed_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["EAF",1], 
   ["Hide_Shield",0,"Hide_Rail",0,"HideDoor1",0,"HideDoor2",0,"HideDoor3",1,"HideBackpacks",1,"HideBumper1",1,"HideBumper2",0,"HideConstruction",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Cars_CreateOffroadAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["B_G_Offroad_01_AT_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["EAF",1], 
   ["HideDoor1",0,"HideDoor2",0,"HideDoor3",0,"HideBackpacks",1,"HideBumper1",1,"HideBumper2",0,"HideConstruction",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

  PZFP_fnc_blufor_LDF_Cars_CreateOffroadCovered = {
   private _cursorPos = getMousePosition;
   private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
   _vehicle = createVehicle ["I_E_Offroad_01_covered_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["EAF",1], 
   ["hidePolice",1,"HideServices",1,"HideCover",0,"StartBeaconLight",0,"HideRoofRack",0,"HideLoudSpeakers",1,"HideAntennas",0,"HideBeacon",1,"HideSpotlight",0,"HideDoor3",0,"OpenDoor3",0,"HideDoor1",0,"HideDoor2",0,"HideBackpacks",1,"HideBumper1",1,"HideBumper2",0,"HideConstruction",0,"BeaconsStart",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Cars_CreateOffroadComms = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Offroad_01_comms_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["EAF",1], 
   ["hidePolice",1,"HideServices",1,"HideCover",0,"StartBeaconLight",0,"HideRoofRack",0,"HideLoudSpeakers",1,"HideAntennas",0,"HideBeacon",1,"HideSpotlight",0,"HideDoor3",0,"OpenDoor3",0,"HideDoor1",0,"HideDoor2",0,"HideBackpacks",1,"HideBumper1",1,"HideBumper2",0,"HideConstruction",0,"BeaconsStart",0]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Cars_CreateVanTransport = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Van_02_transport_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["LDF",1], 
   ["Door_1_source",0,"Door_2_source",0,"Door_3_source",0,"Door_4_source",0,"Hide_Door_1_source",0,"Hide_Door_2_source",0,"Hide_Door_3_source",0,"Hide_Door_4_source",0,"lights_em_hide",0,"ladder_hide",0,"spare_tyre_holder_hide",0,"spare_tyre_hide",0,"reflective_tape_hide",1,"roof_rack_hide",0,"LED_lights_hide",0,"sidesteps_hide",1,"rearsteps_hide",0,"side_protective_frame_hide",0,"front_protective_frame_hide",0,"beacon_front_hide",1,"beacon_rear_hide",1]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Cars_CreateVanCargo = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Van_02_vehicle_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["LDF",1], 
   ["Door_1_source",0,"Door_2_source",0,"Door_3_source",0,"Door_4_source",0,"Hide_Door_1_source",0,"Hide_Door_2_source",0,"Hide_Door_3_source",0,"Hide_Door_4_source",0,"lights_em_hide",0,"ladder_hide",0,"spare_tyre_holder_hide",0,"spare_tyre_hide",0,"reflective_tape_hide",1,"roof_rack_hide",0,"LED_lights_hide",0,"sidesteps_hide",1,"rearsteps_hide",0,"side_protective_frame_hide",0,"front_protective_frame_hide",0,"beacon_front_hide",1,"beacon_rear_hide",1]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
  };

 PZFP_fnc_blufor_LDF_Cars_CreateVanAmbulance = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Van_02_medevac_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["LDF",1], 
   ["Door_1_source",0,"Door_2_source",0,"Door_3_source",0,"Door_4_source",0,"Hide_Door_1_source",0,"Hide_Door_2_source",0,"Hide_Door_3_source",0,"Hide_Door_4_source",0,"lights_em_hide",0,"ladder_hide",0,"spare_tyre_holder_hide",0,"spare_tyre_hide",0,"reflective_tape_hide",1,"roof_rack_hide",0,"LED_lights_hide",0,"sidesteps_hide",1,"rearsteps_hide",0,"side_protective_frame_hide",0,"front_protective_frame_hide",0,"beacon_front_hide",1,"beacon_rear_hide",1]
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_LDF_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
  };

 PZFP_fnc_blufor_LDF_Cars_CreateZamakTransport = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Truck_02_transport_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["EAF",1], 
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Cars_CreateZamakTransportCovered = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Truck_02_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["EAF",1], 
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Cars_CreateZamakAmmo = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Truck_02_ammo_F",_position,[],0,"NONE"];
  [
    _vehicle,
    ["EAF",1], 
    true
  ] call BIS_fnc_initVehicle;
  
    private _driver = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
    _driver moveInDriver _vehicle;
    crew _vehicle join createGroup [west, true];

    getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Cars_CreateZamakFuel = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Truck_02_fuel_F",_position,[],0,"NONE"];
  [
    _vehicle,
    ["EAF",1], 
    true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Cars_CreateZamakRepair = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Truck_02_box_F",_position,[],0,"NONE"];
  [
    _vehicle,
    ["EAF",1], 
    true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Cars_CreateZamakMedical = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Truck_02_medical_F",_position,[],0,"NONE"];
  [
    _vehicle,
    ["EAF",1], 
    true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Drones_CreatePelican = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["I_E_UAV_06_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["EAF",1], 
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Drones_CreatePelicanDropper = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["I_E_UAV_06_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["EAF",1], 
   true
  ] call BIS_fnc_initVehicle;
  [_vehicle] call PZFP_fnc_vehicleCleanup;

  private _grenade1 = createSimpleObject ["GrenadeHand", position _vehicle];
  _grenade1 attachTo [_vehicle, [0.085, 0.085, -0.21]];
  private _grenade2 = createSimpleObject ["GrenadeHand", position _vehicle];
  _grenade2 attachTo [_vehicle, [0.085, -0.085, -0.21]];
  private _grenade3 = createSimpleObject ["GrenadeHand", position _vehicle];
  _grenade3 attachTo [_vehicle, [-0.085, 0.085, -0.21]];
  private _grenade4 = createSimpleObject ["GrenadeHand", position _vehicle];
  _grenade4 attachTo [_vehicle, [-0.085, -0.085, -0.21]];
  _vehicle addWeaponTurret ["BombDemine_01_F", [-1]];
  _vehicle addMagazineTurret ["PylonRack_4Rnd_BombDemine_01_F", [-1]];
  _vehicle setVariable ["grenadeObjects", [_grenade1, _grenade2, _grenade3, _grenade4]];
  
  _vehicle addEventHandler ["Fired", {
	  params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
    deleteVehicle _projectile;
    private _drone = vehicle _gunner;

    private _grenadeammo = magazinesAmmo _drone select 0 select 1;
    if (count magazinesAmmo _unit == 0) then {
     _grenadeammo = 0;
    };

    private _grenades = _drone getVariable ["grenadeObjects", []];
    private _grenade = _grenades select (_grenadeammo);
    [_grenade, true] remoteExec ['hideObjectGlobal',0,true];

    private _payload = "GrenadeHand" createVehicle position _grenade;
    _payload setVelocity velocity _drone vectorMultiply 1.2;
  }];

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Drones_CreatePelicanDropperMortar = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["I_E_UAV_06_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["EAF",1], 
   true
  ] call BIS_fnc_initVehicle;
  [_vehicle] call PZFP_fnc_vehicleCleanup;

  private _grenade1 = createSimpleObject ["Sh_82mm_AMOS", position _vehicle];
  _grenade1 attachTo [_vehicle, [0.085, 0.085, -0.18]];
  _grenade1 setVectorDirAndUp [[0,0,1],[0,1,0]];
  private _grenade2 = createSimpleObject ["Sh_82mm_AMOS", position _vehicle];
  _grenade2 attachTo [_vehicle, [0.085, -0.085, -0.18]];
  _grenade2 setVectorDirAndUp [[0,0,1],[0,1,0]];
  private _grenade3 = createSimpleObject ["Sh_82mm_AMOS", position _vehicle];
  _grenade3 attachTo [_vehicle, [-0.085, 0.085, -0.18]];
  _grenade3 setVectorDirAndUp [[0,0,1],[0,1,0]];
  private _grenade4 = createSimpleObject ["Sh_82mm_AMOS", position _vehicle];
  _grenade4 attachTo [_vehicle, [-0.085, -0.085, -0.18]];
  _grenade4 setVectorDirAndUp [[0,0,1],[0,1,0]];
  _vehicle addWeaponTurret ["BombDemine_01_F", [-1]];
  _vehicle addMagazineTurret ["PylonRack_4Rnd_BombDemine_01_F", [-1]];
  _vehicle setVariable ["grenadeObjects", [_grenade1, _grenade2, _grenade3, _grenade4]];
  
  _vehicle addEventHandler ["Fired", {
	  params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
    deleteVehicle _projectile;
    private _drone = vehicle _gunner;

    private _grenadeammo = magazinesAmmo _drone select 0 select 1;
    if (count magazinesAmmo _unit == 0) then {
     _grenadeammo = 0;
    };

    private _grenades = _drone getVariable ["grenadeObjects", []];
    private _grenade = _grenades select (_grenadeammo);
    [_grenade, true] remoteExec ['hideObjectGlobal',0,true];

    private _payload = "Sh_82mm_AMOS" createVehicle ((position _grenade) vectorAdd [0,0,-1]);
    _payload setVectorDirAndUp [vectorDir _grenade, vectorUp _grenade];
    _payload setVelocity velocity _drone vectorMultiply 1.2;
  }];

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Drones_CreatePelicanCharge = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["I_E_UAV_06_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["EAF",1], 
   true
  ] call BIS_fnc_initVehicle;
  [_vehicle] call PZFP_fnc_vehicleCleanup;

  private _bomb = createSimpleObject ["ATMine_Range_Ammo", position _vehicle];
  _bomb attachTo [_vehicle, [0, 0.0, -0.21]];
  _bomb setVectorDirAndUp [vectorDir _bomb, vectorUp _bomb vectorMultiply -1];
  _vehicle setVariable ["bomb", _bomb];

  _vehicle addWeaponTurret ["BombDemine_01_F", [-1]];
  _vehicle addMagazineTurret ["PylonRack_4Rnd_BombDemine_01_F", [-1]];
  _drone setVariable ["fired", 0];

  _vehicle addEventHandler ["Fired", {
	  params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
    deleteVehicle _projectile;
    private _drone = vehicle _gunner;
    private _bomb = _drone getVariable ["bomb", objNull];
    detach _bomb;
    deleteVehicle _bomb;
    private _charge = createVehicle ["DemoCharge_Remote_Ammo", position _drone, [], 0, "NONE"];
    _charge setDamage 1;
    _drone setVariable ["fired", 1];
  }];

  _vehicle addEventHandler ["Killed", {
    params ["_unit", "_killer", "_instigator"];
    if (_unit getVariable ["fired", 0] != 1) then {
      private _bomb = _unit getVariable ["bomb", objNull];
      detach _bomb;
      deleteVehicle _bomb;
      private _charge = createVehicle ["DemoCharge_Remote_Ammo", position _unit, [], 0, "NONE"];
      _charge setDamage 1;
      _unit setVariable ["fired", 1];
    };
  }];

  _vehicle addEventhandler ["Deleted", {
   params ["_vehicle"];
   {
    deleteVehicle _x;
   } forEach (attachedObjects _vehicle);
  }];

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Drones_CreatePelicanMedical = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["I_E_UAV_06_medical_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["EAF",1], 
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Drones_CreateDarter = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["I_E_UAV_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Green",1], 
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Helicopters_CreateCzapla = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Heli_light_03_unarmed_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["EAF",1], 
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_LDF_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_LDF_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Helicopters_CreateCzaplaArmed = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Heli_light_03_dynamicLoadout_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["EAF",1], 
   true
  ] call BIS_fnc_initVehicle;

  private _pilot = [] call PZFP_fnc_blufor_LDF_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  private _copilot = [] call PZFP_fnc_blufor_LDF_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  crew _vehicle join createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Men_AddLoadoutRifleman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ico_01_black_f";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_E_Uniform_01_F";
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetHBK_headset_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_LDF_Men_AddLoadoutRiflemanLAT = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ico_01_black_f";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addWeapon "launch_MRAWS_green_rail_F";
  _unit addSecondaryWeaponItem "MRAWS_HEAT_F";

  _unit forceAddUniform "U_I_E_Uniform_01_F";
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";
  _unit addBackpack "B_Carryall_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "MRAWS_HEAT_F";};
  _unit addHeadgear "H_HelmetHBK_headset_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
 };
 
 PZFP_fnc_blufor_LDF_Men_AddLoadoutRiflemanAT = {
  params ["_unit"];
  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ico_01_black_f";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addWeapon "launch_NLAW_F";

  _unit forceAddUniform "U_I_E_Uniform_01_F";
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  for "_i" from 1 to 2 do {_unit addItemToVest "NLAW_F";};
  _unit addHeadgear "H_HelmetHBK_headset_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_LDF_Men_AddLoadoutAutorifleman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "LMG_Mk200_black_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ico_01_black_f";
  _unit addPrimaryWeaponItem "200Rnd_65x39_cased_Box_Red";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_E_Uniform_01_F";
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToVest "200Rnd_65x39_cased_Box_Red";
  _unit addItemToVest "200Rnd_65x39_cased_Box_Tracer_Red";
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetHBK_headset_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_LDF_Men_AddLoadoutMarksman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_Mark_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_sos";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_E_Uniform_01_F";
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetHBK_headset_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";  
 };

 PZFP_fnc_blufor_LDF_Men_AddLoadoutTeamLeader = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_GL_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ico_01_black_f";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addPrimaryWeaponItem "1Rnd_HE_Grenade_shell";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_E_Uniform_01_F";
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 5 do {_unit addItemToVest "1Rnd_HE_Grenade_shell";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "UGL_FlareWhite_F";
  _unit addItemToVest "1Rnd_Smoke_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeRed_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeGreen_Grenade_shell";
  _unit addItemToVest "UGL_FlareWhite_Illumination_F";
  _unit addHeadgear "H_HelmetHBK_headset_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";  
 };

 PZFP_fnc_blufor_LDF_Men_AddLoadoutSquadLeader = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ico_01_black_f";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_E_Uniform_01_F";
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";
  _unit addBackpack "B_AssaultPack_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetHBK_headset_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_LDF_Men_AddLoadoutAmmoBearer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ico_01_black_f";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_E_Uniform_01_F";
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";
  _unit addBackpack "B_Carryall_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  for "_i" from 1 to 10 do {_unit addItemToBackpack "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 3 do {_unit addItemToBackpack "200Rnd_65x39_cased_box_Red";};
  for "_i" from 1 to 7 do {_unit addItemToBackpack "1Rnd_HE_Grenade_shell";};
  _unit addHeadgear "H_HelmetHBK_headset_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_LDF_Men_AddLoadoutMedic = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ico_01_black_f";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_E_Uniform_01_F";
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";
  _unit addBackpack "B_Carryall_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToBackpack "Medikit";
  for "_i" from 1 to 5 do {_unit addItemToBackpack "FirstAidKit";};
  _unit addHeadgear "H_HelmetHBK_headset_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_LDF_Men_AddLoadoutRTO = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ico_01_black_f";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_E_Uniform_01_F";
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";
  _unit addBackpack "B_RadioBag_01_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetHBK_headset_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_LDF_Men_AddLoadoutSergeant = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ico_01_black_f";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_E_Uniform_01_F";
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetHBK_headset_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_LDF_Men_AddLoadoutOfficer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ico_01_black_f";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_E_Uniform_01_F";
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetHBK_headset_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_LDF_Men_AddLoadoutCrewman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;
  
  _unit addWeapon "SMG_03C_black";
  _unit addPrimaryWeaponItem "50Rnd_570x28_SMG_03";

  _unit forceAddUniform "U_I_E_Uniform_01_shortsleeve_F";
  _unit addVest "V_CarrierRigKBT_01_EAF_F";
  
  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 2 do {_unit addItemToVest "50Rnd_570x28_SMG_03";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetCrew_I_E";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
 };

 PZFP_fnc_blufor_LDF_Men_AddLoadoutExplosiveSpecialist = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ico_01_black_f";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_E_Uniform_01_F";
  _unit addVest "V_CarrierRigKBT_01_heavy_EAF_F";
  _unit addBackpack "B_Carryall_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "DemoCharge_Remote_Mag";};
  _unit addHeadgear "H_HelmetHBK_chops_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_LDF_Men_AddLoadoutSurvivor = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit forceAddUniform "U_I_E_Uniform_01_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
 };

 PZFP_fnc_blufor_LDF_Men_AddLoadoutHelicopterPilot = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "SMG_02_F";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "optic_Holosight_smg_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_9x21_Mag_SMG_02";

  _unit forceAddUniform "U_I_E_Uniform_01_shortsleeve_F";
  _unit addVest "V_CarrierRigKBT_01_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 2 do {_unit addItemToVest "30Rnd_9x21_Mag_SMG_02";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_PilotHelmetHeli_I_E";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_LDF_Men_AddLoadoutHelicopterCrew = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "SMG_02_F";
  _unit addPrimaryWeaponItem "acc_flashlight";
  _unit addPrimaryWeaponItem "optic_Holosight_smg_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_9x21_Mag_SMG_02";

  _unit forceAddUniform "U_I_E_Uniform_01_shortsleeve_F";
  _unit addVest "V_CarrierRigKBT_01_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 2 do {_unit addItemToVest "30Rnd_9x21_Mag_SMG_02";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_CrewHelmetHeli_I_E";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGoggles_INDEP";
 };
 
 PZFP_fnc_blufor_LDF_Men_AddLoadoutMineSpecialist = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ico_01_black_f";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_E_Uniform_01_F";
  _unit addVest "V_CarrierRigKBT_01_heavy_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToBackpack "MineDetector";
  for "_i" from 1 to 4 do {_unit addItemToBackpack "APERSMine_Range_Mag";};
  _unit addHeadgear "H_HelmetHBK_chops_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_LDF_Men_AddLoadoutUAVOperator = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ico_01_black_f";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";

  _unit forceAddUniform "U_I_E_Uniform_01_F";
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";
  _unit addBackpack "B_UAV_01_backpack_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetHBK_headset_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "B_UAVTerminal";
  _unit linkItem "NVGoggles_INDEP";
 };

 PZFP_fnc_blufor_LDF_Men_CreateRifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutRifleman;
   [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Men_CreateRiflemanLAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_LAT2_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutRiflemanLAT;
   [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Men_CreateRiflemanAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_AT_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutRiflemanAT;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Men_CreateAutorifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_AR_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutAutorifleman;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Men_CreateMarksman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_M_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutMarksman;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Men_CreateTeamLeader = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_TL_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutTeamLeader;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Men_CreateSquadLeader = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_SL_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutSquadLeader;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Men_CreateAmmoBearer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_A_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutAmmoBearer;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Men_CreateMedic = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_medic_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutMedic;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Men_CreateRTO = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_W_RadioOperator_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutRTO;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Men_CreateSergeant = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["C_Marshal_F", _position, [], 0, "CAN_COLLIDE"];
  [_unit] joinSilent _group;
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutSergeant;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Men_CreateOfficer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_officer_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutOfficer;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Men_CreateCrewman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_crew_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutCrewman;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Men_CreateExplosiveSpecialist = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_exp_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutExplosiveSpecialist;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Men_CreateSurvivor = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Survivor_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutSurvivor;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Men_CreateHelicopterPilot = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_HeliPilot_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutHelicopterPilot;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Men_CreateHelicopterCrew = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_HeliCrew_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutHelicopterCrew;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Men_CreateMineSpecialist = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_exp_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutMineSpecialist;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Men_CreateUAVOperator = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_UAV_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutUAVOperator;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutRifleman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "muzzle_snds_65_TI_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addHandgunItem "muzzle_snds_LP_pistol";
  _unit addHandgunItem "optic_MRD_black";

  _unit forceAddUniform "U_I_CombatUniform";
  [_unit, [0, "a3\characters_f_enoch\Uniforms\Data\I_L_Uniform_01_Deserter_2_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "I_E_IR_Grenade";  
  _unit addHeadgear "H_HelmetHBK_ear_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGogglesB_grn_F";
 };

 PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutRiflemanLAT = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "muzzle_snds_65_TI_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addHandgunItem "muzzle_snds_LP_pistol";
  _unit addHandgunItem "optic_MRD_black";
  _unit addWeapon "launch_MRAWS_green_rail_F";
  _unit addSecondaryWeaponItem "MRAWS_HEAT_F";

  _unit forceAddUniform "U_I_CombatUniform";
  [_unit, [0, "a3\characters_f_enoch\Uniforms\Data\I_L_Uniform_01_Deserter_2_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";
  _unit addBackpack "B_Carryall_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "I_E_IR_Grenade";  
  for "_i" from 1 to 2 do {_unit addItemToBackpack "MRAWS_HEAT_F";};
  _unit addHeadgear "H_HelmetHBK_ear_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGogglesB_grn_F";
 };

 PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutRiflemanAT = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "muzzle_snds_65_TI_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addHandgunItem "muzzle_snds_LP_pistol";
  _unit addHandgunItem "optic_MRD_black";
  _unit addWeapon "launch_NLAW_F";
  _unit addMagazine "NLAW_F";

  _unit forceAddUniform "U_I_CombatUniform";
  [_unit, [0, "a3\characters_f_enoch\Uniforms\Data\I_L_Uniform_01_Deserter_2_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";
  _unit addBackpack "B_Carryall_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "I_E_IR_Grenade";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "NLAW_F";};
  _unit addHeadgear "H_HelmetHBK_ear_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGogglesB_grn_F";
 };

 PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutAutorifleman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "LMG_Mk200_black_F";
  _unit addPrimaryWeaponItem "muzzle_snds_65_TI_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_blk_F";
  _unit addPrimaryWeaponItem "200Rnd_65x39_cased_Box";
  _unit addPrimaryWeaponItem "item_bipod_01_F_blk";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addHandgunItem "muzzle_snds_LP_pistol";
  _unit addHandgunItem "optic_MRD_black";

  _unit forceAddUniform "U_I_CombatUniform";
  [_unit, [0, "a3\characters_f_enoch\Uniforms\Data\I_L_Uniform_01_Deserter_2_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 2 do {_unit addItemToVest "200Rnd_65x39_cased_Box";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  _unit addItemToVest "HandGrenade";
  _unit addItemToVest "SmokeShell";
  _unit addHeadgear "H_HelmetHBK_ear_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGogglesB_grn_F";
 };

 PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutMarksman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "srifle_DMR_03_F";
  _unit addPrimaryWeaponItem "muzzle_snds_B";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_DMS";
  _unit addPrimaryWeaponItem "20Rnd_762x51_Mag";
  _unit addPrimaryWeaponItem "bipod_01_F_blk";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addHandgunItem "muzzle_snds_LP_pistol";
  _unit addHandgunItem "optic_MRD_black";

  _unit forceAddUniform "U_I_CombatUniform";
  [_unit, [0, "a3\characters_f_enoch\Uniforms\Data\I_L_Uniform_01_Deserter_2_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "20Rnd_762x51_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "I_E_IR_Grenade";  
  _unit addHeadgear "H_HelmetHBK_ear_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGogglesB_grn_F";
 };

 PZFP_fnc_LDF_MenSOF_AddLoadoutTeamLeader = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_GL_F";
  _unit addPrimaryWeaponItem "muzzle_snds_65_TI_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addPrimaryWeaponItem "1Rnd_HE_Grenade_shell";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addHandgunItem "muzzle_snds_LP_pistol";
  _unit addHandgunItem "optic_MRD_black";

  _unit forceAddUniform "U_I_CombatUniform";
  [_unit, [0, "a3\characters_f_enoch\Uniforms\Data\I_L_Uniform_01_Deserter_2_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 4 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 5 do {_unit addItemToVest "1Rnd_HE_Grenade_shell";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "UGL_FlareWhite_F";
  _unit addItemToVest "1Rnd_Smoke_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeRed_Grenade_shell";
  _unit addItemToVest "UGL_FlareWhite_Illumination_F";
  _unit addItemToVest "UGL_FlareCIR_F";
  _unit addItemToVest "I_E_IR_Grenade";
  _unit addHeadgear "H_HelmetHBK_ear_F";
  _unit addHeadgear "H_HelmetHBK_ear_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGogglesB_grn_F";
 };

 PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutSquadLeader = {
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "muzzle_snds_65_TI_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addHandgunItem "muzzle_snds_LP_pistol";
  _unit addHandgunItem "optic_MRD_black";

  _unit forceAddUniform "U_I_CombatUniform";
  [_unit, [0, "a3\characters_f_enoch\Uniforms\Data\I_L_Uniform_01_Deserter_2_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";
  _unit addBackpack "B_AssaultPack_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "I_E_IR_Grenade";  
  _unit addHeadgear "H_HelmetHBK_ear_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGogglesB_grn_F";
 };

 PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutJTAC = {
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "muzzle_snds_65_TI_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addHandgunItem "muzzle_snds_LP_pistol";
  _unit addHandgunItem "optic_MRD_black";

  _unit forceAddUniform "U_I_CombatUniform";
  [_unit, [0, "a3\characters_f_enoch\Uniforms\Data\I_L_Uniform_01_Deserter_2_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform "Laserbatteries";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "I_E_IR_Grenade";  
  _unit addHeadgear "H_HelmetHBK_ear_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit addWeapon "Laserdesignator_03";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGogglesB_grn_F";
 };

 PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutMedic = {
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "muzzle_snds_65_TI_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addHandgunItem "muzzle_snds_LP_pistol";
  _unit addHandgunItem "optic_MRD_black";

  _unit forceAddUniform "U_I_CombatUniform";
  [_unit, [0, "a3\characters_f_enoch\Uniforms\Data\I_L_Uniform_01_Deserter_2_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";
  _unit addBackpack "B_AssaultPack_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "I_E_IR_Grenade";
  for "_i" from 1 to 5 do {_unit addItemToBackpack "FirstAidKit";};
  _unit addItemToBackpack "Medikit";
  _unit addHeadgear "H_HelmetHBK_ear_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGogglesB_grn_F";
 };

 PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutRTO = {
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "muzzle_snds_65_TI_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addHandgunItem "muzzle_snds_LP_pistol";
  _unit addHandgunItem "optic_MRD_black";

  _unit forceAddUniform "U_I_CombatUniform";
  [_unit, [0, "a3\characters_f_enoch\Uniforms\Data\I_L_Uniform_01_Deserter_2_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";
  _unit addBackpack "B_RadioBag_01_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "I_E_IR_Grenade";
  _unit addHeadgear "H_HelmetHBK_ear_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGogglesB_grn_F";
 };

 PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutAmmoBearer = {
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "muzzle_snds_65_TI_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addHandgunItem "muzzle_snds_LP_pistol";
  _unit addHandgunItem "optic_MRD_black";

  _unit forceAddUniform "U_I_CombatUniform";
  [_unit, [0, "a3\characters_f_enoch\Uniforms\Data\I_L_Uniform_01_Deserter_2_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";
  _unit addBackpack "B_Carryall_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "I_E_IR_Grenade";
  for "_i" from 1 to 10 do {_unit addItemToBackpack "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 3 do {_unit addItemToBackpack "200Rnd_65x39_cased_Box";};
  for "_i" from 1 to 10 do {_unit addItemToBackpack "1Rnd_HE_Grenade_shell";};
  _unit addHeadgear "H_HelmetHBK_ear_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGogglesB_grn_F";
 };

 PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutDemoSpecialist = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "muzzle_snds_65_TI_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addHandgunItem "muzzle_snds_LP_pistol";
  _unit addHandgunItem "optic_MRD_black";

  _unit forceAddUniform "U_I_CombatUniform";
  [_unit, [0, "a3\characters_f_enoch\Uniforms\Data\I_L_Uniform_01_Deserter_2_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";
  _unit addBackpack "B_AssaultPack_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "I_E_IR_Grenade";
  for "_i" from 1 to 3 do {_unit addItemToBackpack "DemoCharge_Remote_Mag";};
  _unit addHeadgear "H_HelmetHBK_ear_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGogglesB_grn_F";
 };

 PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutEngineer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "muzzle_snds_65_TI_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ERCO_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addHandgunItem "muzzle_snds_LP_pistol";
  _unit addHandgunItem "optic_MRD_black";

  _unit forceAddUniform "U_I_CombatUniform";
  [_unit, [0, "a3\characters_f_enoch\Uniforms\Data\I_L_Uniform_01_Deserter_2_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";
  _unit addBackpack "B_AssaultPack_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "I_E_IR_Grenade";
  _unit addItemToBackpack "ToolKit";
  _unit addHeadgear "H_HelmetHBK_ear_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGogglesB_grn_F";
 };

 PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutSergeant = {
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "muzzle_snds_65_TI_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Holosight_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addHandgunItem "muzzle_snds_LP_pistol";
  _unit addHandgunItem "optic_MRD_black";

  _unit forceAddUniform "U_I_CombatUniform";
  [_unit, [0, "a3\characters_f_enoch\Uniforms\Data\I_L_Uniform_01_Deserter_2_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addHeadgear "H_HelmetHBK_ear_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGogglesB_grn_F";
 };

 PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutOfficer = {
  params ["unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_MSBS65_F";
  _unit addPrimaryWeaponItem "muzzle_snds_65_TI_blk_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Holosight_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_msbs_mag";
  _unit addWeapon "hgun_Pistol_heavy_01_green_F";
  _unit addHandgunItem "11Rnd_45ACP_Mag";
  _unit addHandgunItem "muzzle_snds_LP_pistol";
  _unit addHandgunItem "optic_MRD_black";

  _unit forceAddUniform "U_I_CombatUniform";
  [_unit, [0, "a3\characters_f_enoch\Uniforms\Data\I_L_Uniform_01_Deserter_2_co.paa"]] remoteExec ['setObjectTexture',0,true];
  _unit addVest "V_CarrierRigKBT_01_light_EAF_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToUniform "Wallet_ID";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_msbs_mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "11Rnd_45ACP_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addHeadgear "H_HelmetHBK_ear_F";
  _unit addGoggles "G_Combat_Goggles_tna_F";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "NVGogglesB_grn_F";
 };

 PZFP_fnc_blufor_LDF_MenSOF_CreateRifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutRifleman;
   [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_MenSOF_CreateRiflemanLAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutRiflemanLAT;
   [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_MenSOF_CreateRiflemanAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_LAT_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutRiflemanAT;
   [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_MenSOF_CreateAutorifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_AR_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutAutorifleman;
   [_unit] call PZFP_fnc_blufor_GR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_MenSOF_CreateMarksman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_M_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutMarksman;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_MenSOF_CreateTeamLeader = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_TL_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutTeamLeader;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_MenSOF_CreateSquadLeader = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_soldier_SL_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutSquadLeader;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_MenSOF_CreateJTAC = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_CTRG_Soldier_JTAC_tna_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutJTAC;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_MenSOF_CreateAmmoBearer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_Soldier_A_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutAmmoBearer;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_MenSOF_CreateMedic = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_medic_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutMedic;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_MenSOF_CreateRTO = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_W_RadioOperator_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutRTO;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_MenSOF_CreateDemoSpecialist = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_CTRG_Soldier_Exp_tna_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutDemoSpecialist;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_MenSOF_CreateEngineer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_engineer_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_MenSOF_AddLoadoutEngineer;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_MenSOF_CreateSergeant = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["C_Marshal_F", _position, [], 0, "CAN_COLLIDE"];
  [_unit] joinSilent _group;
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutSergeant;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_MenSOF_CreateOfficer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_officer_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_LDF_Men_AddLoadoutOfficer;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_LDF_Turrets_CreateHMG = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_HMG_02_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Turrets_CreateHMGTripod = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_HMG_02_high_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Turrets_CreateAA = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Static_AA_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_LDF_Turrets_CreateAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Static_AT_F",_position,[],0,"NONE"];

  private _gunner = [] call PZFP_fnc_blufor_LDF_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_StrazLesna_Cars_CreateOffroad = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Offroad_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["ParkRanger",1], 
   ["HideDoor1",0,"HideDoor2",0,"HideDoor3",0,"HideBackpacks",selectRandom[0,1],"HideBumper1",1,"HideBumper2",0,"HideConstruction",selectRandom[0,1],"hidePolice",0,"HideServices",1,"BeaconsStart",0,"BeaconsServicesStart",0]
  ] call BIS_fnc_initVehicle;
  
  private _driver = [] call PZFP_fnc_blufor_StrazLesna_Men_CreateOfficer;
  _driver moveInDriver _vehicle;
  crew _vehicle joinSilent createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_StrazLesna_Cars_CreateOffroadHMG = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_G_Offroad_01_armed_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["ParkRanger",1], 
   ["Hide_Shield",selectRandom[0,1],"Hide_Rail",1,"HideDoor1",0,"HideDoor2",0,"HideDoor3",0,"HideBackpacks",selectRandom[0,1],"HideBumper1",1,"HideBumper2",0,"HideConstruction",selectRandom[0,1],"hidePolice",0,"HideServices",1,"BeaconsStart",0,"BeaconsServicesStart",0]
  ] call BIS_fnc_initVehicle;
  
  private _driver = [] call PZFP_fnc_blufor_StrazLesna_Men_CreateOfficer;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_blufor_StrazLesna_Men_CreateOfficer;
  _gunner moveInGunner _vehicle;
  crew _vehicle joinSilent createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_StrazLesna_Cars_CreateOffroadCovered = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Offroad_01_covered_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["ParkRanger",1], 
   ["hidePolice",0,"HideServices",1,"HideCover",0,"StartBeaconLight",0,"HideRoofRack",1,"HideLoudSpeakers",1,"HideAntennas",1,"HideBeacon",1,"HideSpotlight",1,"HideDoor3",0,"OpenDoor3",0,"HideDoor1",0,"HideDoor2",0,"HideBackpacks",1,"HideBumper1",1,"HideBumper2",0,"HideConstruction",0,"BeaconsStart",0]
  ] call BIS_fnc_initVehicle;
  
  private _driver = [] call PZFP_fnc_blufor_StrazLesna_Men_CreateOfficer;
  _driver moveInDriver _vehicle;
  crew _vehicle joinSilent createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_StrazLesna_Cars_CreateOffroadComms = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_E_Offroad_01_comms_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["ParkRanger",1], 
   ["hidePolice",1,"HideServices",1,"HideCover",0,"StartBeaconLight",0,"HideRoofRack",0,"HideLoudSpeakers",1,"HideAntennas",0,"HideBeacon",0,"HideSpotlight",0,"HideDoor3",0,"OpenDoor3",0,"HideDoor1",0,"HideDoor2",0,"HideBackpacks",selectRandom[0,1],"HideBumper1",1,"HideBumper2",0,"HideConstruction",0,"BeaconsStart",0]
  ] call BIS_fnc_initVehicle;
  
  private _driver = [] call PZFP_fnc_blufor_StrazLesna_Men_CreateOfficer;
  _driver moveInDriver _vehicle;
  crew _vehicle joinSilent createGroup [west, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_blufor_StrazLesna_Men_AddLoadoutOfficer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "hgun_Pistol_heavy_02_F";
  _unit addHandgunItem "6Rnd_45ACP_Cylinder";
  _unit addHandgunItem "acc_flashlight_pistol";

  _unit forceAddUniform selectRandom ["U_BG_Guerrilla_6_1","U_BG_Guerilla2_3","U_I_L_Uniform_01_deserter_F"];
  _unit addVest "V_TacVest_blk_POLICE";

  _unit addWeapon "Binocular";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform selectRandom ["MobilePhone", "SmartPhone"];
  for "_i" from 1 to 6 do {_unit addItemToVest "6Rnd_45ACP_Cylinder";};
  _unit addHeadgear selectRandom ["H_Cap_Police", "H_BoonieHat_mgrn", "", "H_Cap_blk", "H_Cap_grn", "H_BoonieHat_oli", "H_BoonieHat"];

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
 };

 PZFP_fnc_blufor_StrazLesna_Men_AddLoadoutOfficerShotgun = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "sgun_HunterShotgun_01_F";
  _unit addPrimaryWeaponItem "2Rnd_12Gauge_Pellets";

  _unit forceAddUniform selectRandom ["U_BG_Guerrilla_6_1","U_BG_Guerilla2_3","U_I_L_Uniform_01_deserter_F"];
  _unit addVest "V_TacVest_blk_POLICE";

  _unit addWeapon "Binocular";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform selectRandom ["MobilePhone", "SmartPhone"];
  for "_i" from 1 to 5 do {_unit addItemToVest "2Rnd_12Gauge_Slug";};
  for "_i" from 1 to 5 do {_unit addItemToVest "2Rnd_12Gauge_Pellets";};
  _unit addHeadgear selectRandom ["H_Cap_Police", "H_BoonieHat_mgrn", "", "H_Cap_blk", "H_Cap_grn", "H_BoonieHat_oli", "H_BoonieHat"];

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
 };

 PZFP_fnc_blufor_StrazLesna_Men_AddLoadoutOfficerRifle = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "srifle_DMR_06_hunter_F";
  _unit addPrimaryWeaponItem "optic_KHS_old";
  _unit addPrimaryWeaponItem "10Rnd_Mk14_762x51_Mag";

  _unit forceAddUniform selectRandom ["U_BG_Guerrilla_6_1","U_BG_Guerilla2_3","U_I_L_Uniform_01_deserter_F"];
  _unit addVest "V_TacVest_blk_POLICE";

  _unit addWeapon "Binocular";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Wallet_ID";
  _unit addItemToUniform selectRandom ["MobilePhone", "SmartPhone"];
  for "_i" from 1 to 4 do {_unit addItemToVest "10Rnd_Mk14_762x51_Mag";};
  _unit addHeadgear selectRandom ["H_Cap_Police", "H_BoonieHat_mgrn", "", "H_Cap_blk", "H_Cap_grn", "H_BoonieHat_oli", "H_BoonieHat"];

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
 };

 PZFP_fnc_blufor_StrazLesna_Men_CreateOfficer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_officer_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_StrazLesna_Men_AddLoadoutOfficer;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_StrazLesna_Men_CreateOfficerShotgun = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_officer_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_StrazLesna_Men_AddLoadoutOfficerShotgun;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_blufor_StrazLesna_Men_CreateOfficerRifle = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [west, true];
  private _unit = _group createUnit ["B_officer_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_blufor_StrazLesna_Men_AddLoadoutOfficerRifle;
    [_unit] call PZFP_fnc_blufor_PL_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };




  comment "------------------------------------------OPFOR-----------------------------------------------";


  
 PZFP_fnc_opfor_IRAF_Drones_CreateFenghuang = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_T_UAV_04_CAS_F",_position,[],0,"NONE"];

  createVehicleCrew _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRAF_MaintenanceCrew_AddLoadoutRepairSpecialist = {
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  _unit addVest "V_Safety_yellow_F";
  _unit addHeadgear "H_Cap_marshal";

  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
 };

 PZFP_fnc_opfor_IRAF_MaintenanceCrew_CreateRepairSpecialist = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  private _unit = _group createUnit ["O_Soldier_repair_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_opfor_IRAF_MaintenanceCrew_AddLoadoutRepairSpecialist;
    [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRAF_Pilots_AddLoadoutFighterPilot = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "hgun_Pistol_01_F";
  _unit addHandgunItem "10Rnd_9x21_Mag";

  _unit forceAddUniform "U_O_PilotCoveralls";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_green";
  _unit addItemToUniform "O_IR_Grenade";
  _unit addItemToUniform "SmokeShellGreen";
  _unit addItemToUniform "SmokeShellRed";
  _unit addItemToUniform "SmokeShell";
  for "_i" from 1 to 2 do {_unit addItemToUniform "MiniGrenade";};
  _unit addHeadgear "H_PilotHelmetFighter_O";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS"; 
 };

 PZFP_fnc_opfor_IRAF_Pilots_AddLoadoutTransportPilot = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "hgun_Pistol_01_F";
  _unit addHandgunItem "10Rnd_9x21_Mag";

  _unit forceAddUniform "U_O_PilotCoveralls";
  _unit addBackpack "B_Parachute";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_green";
  _unit addItemToUniform "O_IR_Grenade";
  _unit addItemToUniform "SmokeShellGreen";
  _unit addItemToUniform "SmokeShellRed";
  _unit addItemToUniform "SmokeShell";
  for "_i" from 1 to 2 do {_unit addItemToUniform "MiniGrenade";};
  _unit addHeadgear "H_PilotHelmetFighter_O";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS"; 
 };

 PZFP_fnc_opfor_IRAF_Pilots_CreateFighterPilot = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  private _unit = _group createUnit ["O_Fighter_Pilot_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_opfor_IRAF_Pilots_AddLoadoutFighterPilot;
    [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRAF_Pilots_CreateTransportPilot = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  private _unit = _group createUnit ["O_Pilot_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_opfor_IRAF_Pilots_AddLoadoutTransportPilot;
    [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRAF_Planes_CreateNeophron = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_Plane_CAS_02_dynamicLoadout_F",_position,[],0,"NONE"];
  
  _pilot = [] call PZFP_fnc_opfor_IRAF_Pilots_CreateFighterPilot;
  _pilot moveInDriver _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRAF_Planes_CreateShikra = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_Plane_Fighter_02_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["CamoAridHex",1], 
   true
  ] call BIS_fnc_initVehicle;

  _pilot = [] call PZFP_fnc_opfor_IRAF_Pilots_CreateFighterPilot;
  _pilot moveInDriver _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_AntiAir_CreateTigris = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_APC_Tracked_02_AA_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Hex",1], 
   ["showTracks",selectRandom[0,1],"showCamonetHull",0,"showCamonetTurret",0,"showSLATHull",0]
  ] call BIS_fnc_initVehicle;

  _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  _gunner = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  _commander = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _commander moveInCommander _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_AntiAir_CreateKamysh = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;

  private _vehicle = createVehicle ["O_APC_Tracked_02_cannon_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Hex",1], 
   [["showTracks",selectRandom[0,1],"showCamonetHull",0,"showBags",0,"showSLATHull",1]]
  ] call BIS_fnc_initVehicle;
  [_vehicle, ["HideTurret",1]] remoteExec ['animate',0,true];
  [_vehicle, [[0],true]] remoteExec ['lockTurret',0,true];
  [_vehicle, [[0,0],true]] remoteExec ['lockTurret',0,true];
  [_vehicle] call PZFP_fnc_vehicleCleanup;

  private _vehicle2 = createVehicle ["O_SAM_System_04_F",_position,[],0,"NONE"];
  [
   _vehicle2,
   ["Hex",1],
   true
  ] call BIS_fnc_initVehicle;
  [_vehicle2, [0, ""]] remoteExec ['setObjectTexture',0,true];
  [_vehicle2, [2, ""]] remoteExec ['setObjectTexture',0,true];
  [_vehicle2, [3, ""]] remoteExec ['setObjectTexture',0,true];
  _vehicle2 attachTo [_vehicle, [0,0,-0.2133]];

  comment "make it ammo-dependent";
  {_x addEventHandler ["Killed", {
    params ["_unit", "_killer", "_instigator"];
     private _explosion = createVehicle ["ammo_Missile_Cruise_01", position _unit, [], 0, "NONE"];
     private _explosion2 = createVehicle ['ammo_Bomb_SDB', position _unit, [], 0, 'CAN_COLLIDE']; 
     private _explosion3 = createVehicle ['Bo_GBU12_LGB', position _unit, [], 0, 'CAN_COLLIDE']; 
     _explosion setDamage 1;
     _explosion2 setDamage 1;
     _explosion3 setDamage 1;
     {
      if ((_x isKindOf 'Man') or (_x isKindOf 'Air') or (_x isKindOf 'Ship') or (_x isKindOf 'Car') or (_x isKindOf 'Tank') or (_x isKindOf 'Static') or (_x isKindOf 'Turret') or (_x isKindOf 'Motorcycle')) then {
       _x setDamage 1;
      }; 
     } forEach nearestObjects [_unit, [], 10]; 
  }];} forEach [_vehicle, _vehicle2];

  _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  createVehicleCrew _vehicle2;

  [crew _vehicle, crew _vehicle2] joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle, _vehicle2], true];
 };

 PZFP_fnc_opfor_IRGF_APCs_CreateKamysh = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_APC_Tracked_02_cannon_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Hex",1], 
   ["showTracks",selectRandom[0,1],"showCamonetHull",0,"showBags",0,"showSLATHull",0]
  ] call BIS_fnc_initVehicle;

  _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  _gunner = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  _commander = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _commander moveInCommander _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_APCs_CreateMarid = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_APC_Wheeled_02_rcws_v2_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Hex",1], 
   ["showBags",0,"showCanisters",selectRandom[0,1],"showTools",selectRandom[0,1],"showCamonetHull",0,"showSLATHull",0]
  ] call BIS_fnc_initVehicle;

  _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  _gunner = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_APCs_CreateMaridAutocannon = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_APC_Wheeled_02_rcws_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Hex",1], 
   ["showBags",0,"showCanisters",selectRandom[0,1],"showTools",selectRandom[0,1],"showCamonetHull",0,"showSLATHull",0]
  ] call BIS_fnc_initVehicle;
  [_vehicle, ["hideTurret",1]] remoteExec ['animate',0,true];
  [_vehicle, [[0],true]] remoteExec ['lockTurret',0,true];
  [_vehicle] call PZFP_fnc_vehicleCleanup;

  private _vehicle2 = "I_APC_Wheeled_03_cannon_F" createVehicle _position;      
  [_vehicle2, [0, ""]] remoteExec ['setObjectTexture',0,true];      
  [_vehicle2, [1, ""]] remoteExec ['setObjectTexture',0,true];      
  [_vehicle2, [2, "a3\armor_f_beta\apc_tracked_02\data\rcws30_opfor_co.paa"]] remoteExec ['setObjectTexture',0,true];      
  [_vehicle2, [3, ""]] remoteExec ['setObjectTexture',0,true];      
  [_vehicle2, [4, ""]] remoteExec ['setObjectTexture',0,true];      
  _vehicle2 attachTo [_vehicle, [-0.1261,-0.9185,0.02]];      
  [ _vehicle2, true]  remoteExec ['lockDriver',0,true];      
  [ _vehicle2, 0]  remoteExec ['setFuel',0,true];      
  [ _vehicle2, true]  remoteExec ['lockCargo',0,true]; 

  _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  _gunner = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _gunner moveInGunner _vehicle2;
  _commander = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _commander moveInCommander _vehicle2;
  [_driver, _gunner, _commander] joinSilent createGroup [east, true];
  group _vehicle addVehicle _vehicle;
  group _vehicle addVehicle _vehicle2;
  group _vehicle setBehaviour "AWARE";

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle, _vehicle2], true];
 };

 PZFP_fnc_opfor_IRGF_Artillery_CreateSochor = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_MBT_02_arty_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Hex",1], 
   ["showBags",0,"showCanisters",selectRandom[0,1],"showTools",selectRandom[0,1],"showCamonetHull",0,"showSLATHull",0]
  ] call BIS_fnc_initVehicle;

  _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  _gunner = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  _commander = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _commander moveInCommander _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Artillery_CreateZamak = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_Truck_02_MRL_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Indep",1],
   true
  ] call BIS_fnc_initVehicle;
  [_vehicle, [0,"a3\soft_f_beta\Truck_02\data\truck_02_kab_OPFOR_CO.paa"]] remoteExec ['setObjectTexture',0,true]; 
  [_vehicle, [2,'a3\soft_f_gamma\Truck_02\Data\Truck_02_MRL_OPFOR_CO.paa']] remoteExec ['setObjectTexture',0,true];

  _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  _gunner = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Boats_CreateAssaultBoat = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_Boat_Transport_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Hex",1],
   true
  ] call BIS_fnc_initVehicle;

  _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Boats_CreateRescueBoat = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_Lifeboat",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Rescue",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Boats_CreateRHIB = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["I_C_Boat_Transport_02_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Black",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Cars_CreateIfrit = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_MRAP_02_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Hex",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Cars_CreateIfritHMG = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_MRAP_02_hmg_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Hex",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Cars_CreateIfritGMG = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_MRAP_02_gmg_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Hex",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  private _gunner = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Cars_CreateZamakTransport = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_Truck_02_transport_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Cars_CreateZamakTransportCovered = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_Truck_02_covered_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Cars_CreateZamakRepair = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_Truck_02_box_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Cars_CreateZamakFuel = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_Truck_02_fuel_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Cars_CreateZamakAmmo = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_Truck_02_ammo_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Cars_CreateZamakMedical = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_Truck_02_medical_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   true
  ] call BIS_fnc_initVehicle;

  private _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _driver moveInDriver _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Drones_CreateJinaah = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_UAV_06_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   ["lights_em_hide",0,"LED_lights_hide",1,"Inventory_door",0]
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Drones_CreateJinaahMedical = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_UAV_06_medical_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   ["lights_em_hide",0,"LED_lights_hide",1,"Inventory_door",0]
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Drones_CreateTayran = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_UAV_01_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;
  crew _vehicle join createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Helicopters_CreateTaru = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_Heli_Transport_04_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   true
  ] call BIS_fnc_initVehicle;

  _pilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  _copilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  _loadmaster = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterCrew;
  _loadmaster moveInTurret [_vehicle, [1]];
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Helicopters_CreateTaruTransport = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_Heli_Transport_04_covered_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   true
  ] call BIS_fnc_initVehicle;

  _pilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  _copilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  _loadmaster = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterCrew;
  _loadmaster moveInTurret [_vehicle, [1]];
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Helicopters_CreateTaruRepair = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_Heli_Transport_04_repair_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   true
  ] call BIS_fnc_initVehicle;

  _pilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  _copilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  _loadmaster = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterCrew;
  _loadmaster moveInTurret [_vehicle, [1]];
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Helicopters_CreateTaruFuel = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_Heli_Transport_04_fuel_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   true
  ] call BIS_fnc_initVehicle;

  _pilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  _copilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  _loadmaster = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterCrew;
  _loadmaster moveInTurret [_vehicle, [1]];
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Helicopters_CreateTaruAmmo = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_Heli_Transport_04_ammo_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   true
  ] call BIS_fnc_initVehicle;

  _pilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  _copilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  _loadmaster = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterCrew;
  _loadmaster moveInTurret [_vehicle, [1]];
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Helicopters_CreateTaruMedical = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_Heli_Transport_04_medevac_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   true
  ] call BIS_fnc_initVehicle;

  _pilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  _copilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  _loadmaster = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterCrew;
  _loadmaster moveInTurret [_vehicle, [1]];
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Helicopters_CreateTaruCargo = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_Heli_Transport_04_box_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   true
  ] call BIS_fnc_initVehicle;

  _pilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  _copilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  _loadmaster = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterCrew;
  _loadmaster moveInTurret [_vehicle, [1]];
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Helicopters_CreateKajman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_Heli_Attack_02_dynamicloadout_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   true
  ] call BIS_fnc_initVehicle;

  _pilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  _copilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Helicopters_CreateOrca = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_Heli_Light_02_unarmed_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   true
  ] call BIS_fnc_initVehicle;

  _pilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  _copilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Helicopters_CreateOrcaArmed = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _vehicle = createVehicle ["O_Heli_Light_02_dynamicloadout_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Opfor",1],
   true
  ] call BIS_fnc_initVehicle;

  _pilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _pilot moveInDriver _vehicle;
  _copilot = [] call PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot;
  _copilot moveInTurret [_vehicle, [0]];
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutRifleman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Katiba_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Arco_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_green";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  [_unit, ""] call BIS_fnc_setUnitInsignia;
  _unit addVest "V_HarnessO_brn";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_green";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetO_ocamo";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "O_NVGoggles_hex_F";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutLAT = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Katiba_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Arco_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_green";
  _unit addWeapon "launch_RPG7_F";
  _unit addSecondaryWeaponItem "RPG7_F";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  [_unit, ""] call BIS_fnc_setUnitInsignia;
  _unit addVest "V_HarnessO_brn";
  _unit addBackpack "B_TacticalPack_ocamo";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_green";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "RPG7_F";};
  _unit addHeadgear "H_HelmetO_ocamo";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "O_NVGoggles_hex_F";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutAT = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Katiba_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Arco_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_green";
  _unit addWeapon "launch_O_Vorona_brown_F";
  _unit addSecondaryWeaponItem "Vorona_HEAT";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  [_unit, ""] call BIS_fnc_setUnitInsignia;
  _unit addVest "V_HarnessO_brn";
  _unit addBackpack "B_TacticalPack_ocamo";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_green";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "Vorona_HEAT";};
  _unit addHeadgear "H_HelmetO_ocamo";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "O_NVGoggles_hex_F";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutAutorifleman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "LMG_Zafir_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Arco_blk_F";
  _unit addPrimaryWeaponItem "150Rnd_762x54_Box";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  [_unit, ""] call BIS_fnc_setUnitInsignia;
  _unit addVest "V_HarnessO_brn";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  _unit addItemToVest "150Rnd_762x54_Box";
  _unit addItemToVest "150Rnd_762x54_Box_Tracer";
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetO_ocamo";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "O_NVGoggles_hex_F";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutMarksman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "srifle_DMR_01_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_DMS";
  _unit addPrimaryWeaponItem "10Rnd_762x54_Mag";
  _unit addWeapon "hgun_Pistol_01_F";
  _unit addHandgunItem "10Rnd_9x21_Mag";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  [_unit, ""] call BIS_fnc_setUnitInsignia;
  _unit addVest "V_HarnessO_brn";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 6 do {_unit addItemToVest "10Rnd_762x54_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "10Rnd_9x21_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetO_ocamo";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "O_NVGoggles_hex_F";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutTeamLeader = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Katiba_GL_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Arco_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_green";
  _unit addPrimaryWeaponItem "1Rnd_HE_Grenade_shell";
  _unit addWeapon "hgun_Pistol_01_F";
  _unit addHandgunItem "10Rnd_9x21_Mag";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  [_unit, ""] call BIS_fnc_setUnitInsignia;
  _unit addVest "V_HarnessO_brn";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_green";};
  for "_i" from 1 to 5 do {_unit addItemToVest "1Rnd_HE_Grenade_shell";};
  _unit addItemToVest "UGL_FlareWhite_F";
  _unit addItemToVest "1Rnd_Smoke_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeRed_Grenade_shell";
  _unit addItemToVest "1Rnd_SmokeGreen_Grenade_shell";
  _unit addItemToVest "UGL_FlareWhite_Illumination_F";
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addHeadgear "H_HelmetO_ocamo";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "O_NVGoggles_hex_F";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutSquadLeader = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Katiba_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Arco_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_green";
  _unit addWeapon "hgun_Pistol_01_F";
  _unit addHandgunItem "10Rnd_9x21_Mag";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  [_unit, ""] call BIS_fnc_setUnitInsignia;
  _unit addVest "V_HarnessO_brn";
  _unit addBackpack "B_FieldPack_ocamo";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_green";};
  for "_i" from 1 to 2 do {_unit addItemToVest "10Rnd_9x21_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetO_ocamo";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "O_NVGoggles_hex_F";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutAmmoBearer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Katiba_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Arco_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_green";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  [_unit, ""] call BIS_fnc_setUnitInsignia;
  _unit addVest "V_HarnessO_brn";
  _unit addBackpack "B_TacticalPack_ocamo";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_green";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  for "_i" from 1 to 10 do {_unit addItemToBackpack "30Rnd_65x39_caseless_green";};
  for "_i" from 1 to 2 do {_unit addItemToBackpack "150Rnd_762x51_Box";};
  for "_i" from 1 to 10 do {_unit addItemToBackpack "1Rnd_HE_Grenade_shell";};
  _unit addHeadgear "H_HelmetO_ocamo";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "O_NVGoggles_hex_F";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutMedic = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Katiba_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Arco_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_green";
  _unit addWeapon "hgun_Pistol_01_F";
  _unit addHandgunItem "10Rnd_9x21_Mag";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  [_unit, ""] call BIS_fnc_setUnitInsignia;
  _unit addVest "V_HarnessO_brn";
  _unit addBackpack "B_TacticalPack_ocamo";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_green";};
  for "_i" from 1 to 2 do {_unit addItemToVest "10Rnd_9x21_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetO_ocamo";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "O_NVGoggles_hex_F";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutRTO = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Katiba_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Arco_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_green";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  [_unit, ""] call BIS_fnc_setUnitInsignia;
  _unit addVest "V_HarnessO_brn";
  _unit addBackpack "B_RadioBag_01_hex_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_green";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetO_ocamo";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "O_NVGoggles_hex_F";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutSergeant = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Katiba_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Arco_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_green";
  _unit addWeapon "hgun_Pistol_01_F";
  _unit addHandgunItem "10Rnd_9x21_Mag";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  [_unit, ""] call BIS_fnc_setUnitInsignia;
  _unit addVest "V_HarnessO_brn";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_green";};
  for "_i" from 1 to 2 do {_unit addItemToVest "10Rnd_9x21_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetO_ocamo";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "O_NVGoggles_hex_F";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutOfficer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Katiba_C_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_ACO_grn";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_green";
  _unit addWeapon "hgun_Pistol_01_F";
  _unit addHandgunItem "10Rnd_9x21_Mag";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  [_unit, ""] call BIS_fnc_setUnitInsignia;
  _unit addVest "V_HarnessO_brn";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_green";};
  for "_i" from 1 to 2 do {_unit addItemToVest "10Rnd_9x21_Mag";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetO_ocamo";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "O_NVGoggles_hex_F";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutCrewman = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Katiba_C_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_green";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  _unit addVest "V_BandollierB_cbr";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 4 do {_unit addItemToVest "30Rnd_65x39_caseless_green";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_Tank_black_F";
  _unit addGoggles "G_Combat";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutEngineer = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Katiba_C_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Arco_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_green";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  [_unit, ""] call BIS_fnc_setUnitInsignia;
  _unit addVest "V_HarnessO_brn";
  _unit addBackpack "B_FieldPack_ocamo";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_green";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToBackpack "Toolkit";
  _unit addHeadgear "H_HelmetO_ocamo";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "O_NVGoggles_hex_F";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutExplosiveSpecialist = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Katiba_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Arco_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_green";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  [_unit, ""] call BIS_fnc_setUnitInsignia;
  _unit addVest "V_HarnessO_brn";
  _unit addBackPack "B_TacticalPack_ocamo";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_green";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  for "_i" from 1 to 2 do {_unit addItemToBackpack "DemoCharge_Remote_Mag";};
  _unit addHeadgear "H_HelmetO_ocamo";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "O_NVGoggles_hex_F";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutHelicopterPilot = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Katiba_F";
  _unit addPrimaryWeaponItem "optic_ACO_grn";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_green";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  _unit addVest "V_TacVest_brn";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 4 do {_unit addItemToVest "30Rnd_65x39_caseless_green";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "O_IR_Grenade";
  _unit addHeadgear "H_PilotHelmetHeli_O";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "O_NVGoggles_hex_F";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutHelicopterCrew = {
  params ["_unit"];
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Katiba_F";
  _unit addPrimaryWeaponItem "optic_ACO_grn";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_green";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  _unit addVest "V_TacVest_brn";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 4 do {_unit addItemToVest "30Rnd_65x39_caseless_green";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addItemToVest "O_IR_Grenade";
  _unit addHeadgear "H_CrewHelmetHeli_O";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "ItemGPS";
  _unit linkItem "O_NVGoggles_hex_F";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutMineSpecialist = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Katiba_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Arco_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_green";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  [_unit, ""] call BIS_fnc_setUnitInsignia;
  _unit addVest "V_HarnessO_brn";
  _unit addBackpack "B_FieldPack_ocamo";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_green";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  for "_i" from 1 to 5 do {_unit addItemToBackpack "APERSMine_Range_Mag";};
  for "_i" from 1 to 5 do {_unit addItemToBackpack "APERSTripMine_Wire_Mag";};
  _unit addHeadgear "H_HelmetO_ocamo";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "O_NVGoggles_hex_F";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutSurvivor = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  [_unit, ""] call BIS_fnc_setUnitInsignia;

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
 };

 PZFP_fnc_opfor_IRGF_Men_AddLoadoutUAVOperator = {
  params ["_unit"];
  removeAllWeapons _unit;
  removeAllItems _unit;
  removeAllAssignedItems _unit;
  removeUniform _unit;
  removeVest _unit;
  removeBackpack _unit;
  removeHeadgear _unit;
  removeGoggles _unit;

  _unit addWeapon "arifle_Katiba_F";
  _unit addPrimaryWeaponItem "acc_pointer_IR";
  _unit addPrimaryWeaponItem "optic_Arco_blk_F";
  _unit addPrimaryWeaponItem "30Rnd_65x39_caseless_green";

  _unit forceAddUniform "U_O_officer_noInsignia_hex_F";
  [_unit, ""] call BIS_fnc_setUnitInsignia;
  _unit addVest "V_HarnessO_brn";
  _unit addBackpack "O_UAV_01_backpack_F";

  _unit addItemToUniform "FirstAidKit";
  _unit addItemToUniform "Chemlight_yellow";
  for "_i" from 1 to 6 do {_unit addItemToVest "30Rnd_65x39_caseless_green";};
  for "_i" from 1 to 2 do {_unit addItemToVest "HandGrenade";};
  _unit addItemToVest "SmokeShell";
  _unit addItemToVest "SmokeShellRed";
  _unit addItemToVest "SmokeShellGreen";
  _unit addHeadgear "H_HelmetO_ocamo";
  _unit addGoggles "G_Combat";

  _unit linkItem "ItemMap";
  _unit linkItem "ItemCompass";
  _unit linkItem "ItemWatch";
  _unit linkItem "ItemRadio";
  _unit linkItem "O_NVGoggles_hex_F";
 };

 PZFP_fnc_opfor_IRGF_Men_CreateCrewman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  private _unit = _group createUnit ["O_crew_F", _position, [], 0, "CAN_COLLIDE"];
  _group setBehaviour "SAFE";
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then { doStop _unit; };
  [_unit] spawn {
    params ["_unit"];
    sleep 0.1;
    [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutCrewman;
    [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateRifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["O_Soldier_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutRifleman;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateLAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];  
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["O_Soldier_LAT_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutLAT;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true]; 
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["O_Soldier_AT_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutAT;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateAutorifleman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["O_soldier_AR_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutAutorifleman;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateMarksman = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["O_soldier_M_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutMarksman;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateTeamLeader = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["O_soldier_TL_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutTeamLeader;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateSquadLeader = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["O_soldier_SL_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutSquadLeader;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateAmmoBearer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["O_Soldier_A_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutAmmoBearer;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateMedic = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["O_medic_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutMedic;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateRTO = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["B_W_RadioOperator_F", _position, [], 0, "CAN_COLLIDE"];
  [_unit] joinSilent _group;
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutRTO;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateSergeant = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["C_Marshal_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] joinSilent _group;
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutSergeant;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateOfficer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["O_officer_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutOfficer;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateEngineer = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["O_engineer_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutEngineer;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateExplosiveSpecialist = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["O_Soldier_EXP_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutExplosiveSpecialist;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["O_helipilot_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutHelicopterPilot;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateHelicopterCrew = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["O_helicrew_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutHelicopterCrew;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateMineSpecialist = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["O_Soldier_mine_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutMineSpecialist;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateSurvivor = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["O_Survivor_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutSurvivor;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Men_CreateUAVOperator = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  private _group = createGroup [east, true];
  _group setBehaviour "SAFE";
  private _unit = _group createUnit ["O_soldier_UAV_F", _position, [], 0, "CAN_COLLIDE"];
  if ((missionNamespace getVariable ["PZFP_AIStopEnabled", true])) then {
   doStop _unit;
  };
  [_unit] spawn {
   params ["_unit"];
   sleep 0.1;
   [_unit] call PZFP_fnc_opfor_IRGF_Men_AddLoadoutUAVOperator;
   [_unit] call PZFP_fnc_opfor_IR_AddIdentity;
  };
  getAssignedCuratorLogic player addCuratorEditableObjects [[_unit], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Tanks_CreateVarsuk = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_MBT_02_cannon_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Hex",1], 
   ["showCamonetHull",0,"showCamonetTurret",0,"showLog",1]
  ] call BIS_fnc_initVehicle;

  _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  _gunner = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  _commander = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _commander moveInCommander _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Tanks_CreateAngara = {
  private _cursorPos = getMousePosition;
  _vehicle = createVehicle ["O_MBT_04_cannon_F",_position,[],0,"NONE"];
  [
	 _vehicle,
   ["Hex",1], 
   ["showCamonetHull",0,"showCamonetTurret",0]
  ] call BIS_fnc_initVehicle;

  _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  _gunner = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  _commander = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _commander moveInCommander _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Tanks_CreateAngaraUP = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_MBT_04_command_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["Hex",1], 
   ["showCamonetHull",0,"showCamonetTurret",0]
  ] call BIS_fnc_initVehicle;

  _driver = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _driver moveInDriver _vehicle;
  _gunner = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _gunner moveInGunner _vehicle;
  _commander = [] call PZFP_fnc_opfor_IRGF_Men_CreateCrewman;
  _commander moveInCommander _vehicle;
  crew _vehicle joinSilent createGroup [east, true];

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
  _unit
 };

 PZFP_fnc_opfor_IRGF_Turrets_CreateHMG = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_HMG_01_F",_position,[],0,"NONE"];
  
  _gunner = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;
  
  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Turrets_CreateHMGTripod = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_HMG_01_high_F",_position,[],0,"NONE"];
  
  _gunner = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Turrets_CreateGMG = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_GMG_01_F",_position,[],0,"NONE"];
  
  _gunner = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Turrets_CreateGMGTripod = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_GMG_01_high_F",_position,[],0,"NONE"];
  
  _gunner = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Turrets_CreateMortar = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_Mortar_01_F",_position,[],0,"NONE"];
  
  _gunner = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Turrets_CreateRadar = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_Radar_System_02_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["AridHex",1], 
   true
  ] call BIS_fnc_initVehicle;
  
  createVehicleCrew _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Turrets_CreateDesignator = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_Static_Designator_02_F",_position,[],0,"NONE"];

  createVehicleCrew _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Turrets_CreateSAM = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_SAM_System_04_F",_position,[],0,"NONE"];
  [
   _vehicle,
   ["AridHex",1],
   true
  ] call BIS_fnc_initVehicle;

  createVehicleCrew _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Turrets_CreateAA = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_Static_AA_F",_position,[],0,"NONE"];

  _gunner = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };

 PZFP_fnc_opfor_IRGF_Turrets_CreateAT = {
  private _cursorPos = getMousePosition;
  private _position = [_cursorPos] call PZFP_fnc_findCursorPosition;
  _vehicle = createVehicle ["O_Static_AT_F",_position,[],0,"NONE"];

  _gunner = [] call PZFP_fnc_opfor_IRGF_Men_CreateRifleman;
  _gunner moveInGunner _vehicle;

  getAssignedCuratorLogic player addCuratorEditableObjects [[_vehicle], true];
 };


 PZFP_fnc_rebuildZeusTree = {
  disableSerialization;
  private _display = findDisplay 312;
  if (isNull _display) exitWith {};

  curatorCamera camCommand "maxPitch 89"; 
  curatorCamera camCommand "minPitch -89"; 

  missionNamespace setVariable ["PZFP_moduleScripts", []];

  private _curator = getAssignedCuratorLogic player;
  private _maindisplay = findDisplay 312;
  private _control = _maindisplay displayCtrl 280;
  private _blufor = _maindisplay displayCtrl 270;
  private _opfor = _maindisplay displayCtrl 271;
  private _indep = _maindisplay displayCtrl 272;
  private _civ = _maindisplay displayCtrl 273;

  [] call PZFP_fnc_addTreeEventhandler;
  [] call PZFP_fnc_declutterTrees;

  PZFP_bluforDividerSpace = [_blufor, "", [1,1,1,0]] call PZFP_fnc_addCategory;
  PZFP_bluforTitle = [_blufor, "PZFP Factions", [0,0.3,0.7,1]] call PZFP_fnc_addCategory;
  PZFP_bluforDivider = [_blufor, "--------------------------------------------", [0,0.3,0.7,1]] call PZFP_fnc_addCategory;

  PZFP_blufor_USAF = [_blufor, "United States Air Force", [1,1,1,1]] call PZFP_fnc_addCategory;

  PZFP_blufor_USAF_Drones = [_blufor, PZFP_blufor_USAF, "Drones", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USAF_Drones_Greyhawk = [_blufor, PZFP_blufor_USAF, PZFP_blufor_USAF_Drones, "MQ-4A Greyhawk", "PZFP_fnc_blufor_USAF_Drones_CreateGreyhawk", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USAF_Pilots = [_blufor, PZFP_blufor_USAF, "Pilots", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USAF_Pilots_FighterPilot = [_blufor, PZFP_blufor_USAF, PZFP_blufor_USAF_Pilots, "Fighter Pilot", "PZFP_fnc_blufor_USAF_Pilots_CreateFighterPilot", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USAF_Pilots_TransportPilot = [_blufor, PZFP_blufor_USAF, PZFP_blufor_USAF_Pilots, "Transport Pilot", "PZFP_fnc_blufor_USAF_Pilots_CreateTransportPilot", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USAF_Planes = [_blufor, PZFP_blufor_USAF, "Planes", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USAF_Planes_Wipeout = [_blufor, PZFP_blufor_USAF, PZFP_blufor_USAF_Planes, "A-164 Wipeout", "PZFP_fnc_blufor_USAF_Planes_CreateWipeout", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USAF_Planes_VTOL = [_blufor, PZFP_blufor_USAF, PZFP_blufor_USAF_Planes, "V-44/X Blackfish", "PZFP_fnc_blufor_USAF_Planes_CreateVTOL", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USAF_Planes_VTOLArmed = [_blufor, PZFP_blufor_USAF, PZFP_blufor_USAF_Planes, "V-44/X Blackfish (Gunship)", "PZFP_fnc_blufor_USAF_Planes_CreateVTOLArmed", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USAF_Planes_VTOLVehicle = [_blufor, PZFP_blufor_USAF, PZFP_blufor_USAF_Planes, "V-44/X Blackfish (Vehicle Transport)", "PZFP_fnc_blufor_USAF_Planes_CreateVTOLVehicle", [1,1,1,1]] call PZFP_fnc_addModule;


  PZFP_blufor_USA = [_blufor, "United States Army", [1,1,1,1]] call PZFP_fnc_addCategory;

  PZFP_blufor_USA_AntiAir = [_blufor, PZFP_blufor_USA, "Anti-Air", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USA_AntiAir_IFV6 = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_AntiAir, "IFV-6A Cheetah", "PZFP_fnc_blufor_USA_AntiAir_CreateIFV6", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_AntiAir_Marshall = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_AntiAir, "Marshall (AA)", "PZFP_fnc_blufor_USA_AntiAir_CreateMarshall", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USA_APC = [_blufor, PZFP_blufor_USA, "APCs", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USA_APC_AMV7MarshallMG = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_APC, "AMV-7 Marshall (MG)", "PZFP_fnc_blufor_USA_APC_CreateAMV7MarshallMG", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_APC_AMV7Marshall = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_APC, "AMV-7 Marshall", "PZFP_fnc_blufor_USA_APC_CreateAMV7Marshall", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_APC_CRV6Bobcat = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_APC, "CRV-6 Bobcat", "PZFP_fnc_blufor_USA_APC_CreateCRV6Bobcat", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_APC_IFV6cPanther = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_APC, "IFV-6c Panther", "PZFP_fnc_blufor_USA_APC_CreateIFV6cPanther", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USA_Artillery = [_blufor, PZFP_blufor_USA, "Artillery", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USA_Artillery_Scorcher = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Artillery, "M4 Scorcher", "PZFP_fnc_blufor_USA_Artillery_CreateScorcher", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Artillery_Sandstorm = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Artillery, "M5 Sandstorm", "PZFP_fnc_blufor_USA_Artillery_CreateSandstorm", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USA_Boats = [_blufor, PZFP_blufor_USA, "Boats", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USA_Boats_AssaultBoat = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Boats, "Assault Boat", "PZFP_fnc_blufor_USA_Boats_CreateAssaultBoat", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Boats_RescueBoat = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Boats, "Rescue Boat", "PZFP_fnc_blufor_USA_Boats_CreateRescueBoat", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Boats_RHIB = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Boats, "Rigid Hull Boat", "PZFP_fnc_blufor_USA_Boats_CreateRHIB", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USA_Cars = [_blufor, PZFP_blufor_USA, "Cars", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USA_Cars_HEMTT = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Cars, "HEMTT", "PZFP_fnc_blufor_USA_Cars_CreateHEMTT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Cars_HEMTTAmmo = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Cars, "HEMTT (Ammo)", "PZFP_fnc_blufor_USA_Cars_CreateHEMTTAmmo", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Cars_HEMTTBox = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Cars, "HEMTT (Box)", "PZFP_fnc_blufor_USA_Cars_CreateHEMTTBox", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Cars_HEMTTCargo = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Cars, "HEMTT (Cargo)", "PZFP_fnc_blufor_USA_Cars_CreateHEMTTCargo", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Cars_HEMTTFlatbed = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Cars, "HEMTT (Flatbed)", "PZFP_fnc_blufor_USA_Cars_CreateHEMTTFlatbed", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Cars_HEMTTFuel = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Cars, "HEMTT (Fuel)", "PZFP_fnc_blufor_USA_Cars_CreateHEMTTFuel", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Cars_HEMTTMedical = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Cars, "HEMTT (MEDEVAC)", "PZFP_fnc_blufor_USA_Cars_CreateHEMTTMedical", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Cars_HEMTTRepair = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Cars, "HEMTT (Repair)", "PZFP_fnc_blufor_USA_Cars_CreateHEMTTRepair", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Cars_HEMTTTransport = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Cars, "HEMTT Transport", "PZFP_fnc_blufor_USA_Cars_CreateHEMTTTransport", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Cars_HEMTTTransportCovered = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Cars, "HEMTT Transport (Covered)", "PZFP_fnc_blufor_USA_Cars_CreateHEMTTCovered", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Cars_Hunter = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Cars, "Hunter", "PZFP_fnc_blufor_USA_Cars_CreateHunter", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Cars_HunterHMG = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Cars, "Hunter (HMG)", "PZFP_fnc_blufor_USA_Cars_CreateHunterHMG", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Cars_Hunter = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Cars, "Hunter (GMG)", "PZFP_fnc_blufor_USA_Cars_CreateHunterGMG", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USA_Drones = [_blufor, PZFP_blufor_USA, "Drones", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USA_Drones_Pelican = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Drones, "AL-6 Pelican", "PZFP_fnc_blufor_USA_Drones_CreatePelican", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Drones_PelicanMedical = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Drones, "AL-6 Pelican (Medical)", "PZFP_fnc_blufor_USA_Drones_CreatePelicanMedical", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Drones_Darter = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Drones, "AR-2 Darter", "PZFP_fnc_blufor_USA_Drones_CreateDarter", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Drones_Pelter = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Drones, "ED-1D Pelter (Demining)", "PZFP_fnc_blufor_USA_Drones_CreatePelter", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Drones_Roller = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Drones, "ED-1E Pelter (Science)", "PZFP_fnc_blufor_USA_Drones_CreateRoller", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Drones_Stomper = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Drones, "UGV Stomper", "PZFP_fnc_blufor_USA_Drones_CreateStomper", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Drones_StomperMG = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Drones, "UGV Stomper (Armed)", "PZFP_fnc_blufor_USA_Drones_CreateStomperMG", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USA_Helicopters = [_blufor, PZFP_blufor_USA, "Helicopters", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USA_Helicopters_Pawnee = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Helicopters, "AH-9 Pawnee", "PZFP_fnc_blufor_USA_Helicopters_CreatePawnee", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Helicopters_Blackfoot = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Helicopters, "AH-99 Blackfoot", "PZFP_fnc_blufor_USA_Helicopters_CreateBlackfoot", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Helicopters_Huron = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Helicopters, "CH-67 Huron", "PZFP_fnc_blufor_USA_Helicopters_CreateHuron", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Helicopters_HuronArmed = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Helicopters, "CH-67 Huron (Armed)", "PZFP_fnc_blufor_USA_Helicopters_CreateHuronArmed", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Helicopters_Hummingbird = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Helicopters, "MH-9 Hummingbird", "PZFP_fnc_blufor_USA_Helicopters_CreateHummingbird", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Helicopters_Ghosthawk = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Helicopters, "UH-80 Ghost Hawk", "PZFP_fnc_blufor_USA_Helicopters_CreateGhosthawk", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Helicopters_GhosthawkStub = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Helicopters, "UH-80 Ghost Hawk (Stub Wings)", "PZFP_fnc_blufor_USA_Helicopters_CreateGhosthawkStub", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USA_Men = [_blufor, PZFP_blufor_USA, "Men", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USA_Men_Rifleman = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Rifleman", "PZFP_fnc_blufor_USA_Men_CreateRifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_LightAT = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Rifleman (Light AT)", "PZFP_fnc_blufor_USA_Men_CreateLAT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_AT = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Rifleman (AT)", "PZFP_fnc_blufor_USA_Men_CreateAT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_Autorifleman = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Autorifleman", "PZFP_fnc_blufor_USA_Men_CreateAutorifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_Marksman = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Marksman", "PZFP_fnc_blufor_USA_Men_CreateMarksman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_MachineGunner = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Machine Gunner", "PZFP_fnc_blufor_USA_Men_CreateMachineGunner", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_TeamLeader = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Team Leader", "PZFP_fnc_blufor_USA_Men_CreateTeamLeader", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_SquadLeader = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Squad Leader", "PZFP_fnc_blufor_USA_Men_CreateSquadLeader", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_AmmoBearer = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Ammo Bearer", "PZFP_fnc_blufor_USA_Men_CreateAmmoBearer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_Medic = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Medic", "PZFP_fnc_blufor_USA_Men_CreateMedic", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_RTO = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Radio-Telephone Operator", "PZFP_fnc_blufor_USA_Men_CreateRTO", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_Sergeant = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Sergeant", "PZFP_fnc_blufor_USA_Men_CreateSergeant", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_Officer = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Officer", "PZFP_fnc_blufor_USA_Men_CreateOfficer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_Crewman = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Crewman", "PZFP_fnc_blufor_USA_Men_CreateCrewman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_ExplosiveSpecialist = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Explosive Specialist", "PZFP_fnc_blufor_USA_Men_CreateExplosiveSpecialist", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_Survivor = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Survivor", "PZFP_fnc_blufor_USA_Men_CreateSurvivor", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_HelicopterPilot = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Helicopter Pilot", "PZFP_fnc_blufor_USA_Men_CreateHelicopterPilot", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_HelicopterCrew = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Helicopter Crew", "PZFP_fnc_blufor_USA_Men_CreateHelicopterCrew", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_MineSpecialist = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "Mine Specialist", "PZFP_fnc_blufor_USA_Men_CreateMineSpecialist", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Men_UAVOperator = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Men, "UAV Operator", "PZFP_fnc_blufor_USA_Men_CreateUAVOperator", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USA_MenSF = [_blufor, PZFP_blufor_USA, "Men (Special Forces)", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USA_MenSF_Rifleman = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_MenSF, "Rifleman", "PZFP_fnc_blufor_USA_MenSF_CreateRifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_MenSF_RiflemanLAT = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_MenSF, "Rifleman (LAT)", "PZFP_fnc_blufor_USA_MenSF_CreateRiflemanLAT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_MenSF_RiflemanAT = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_MenSF, "Rifleman (AT)", "PZFP_fnc_blufor_USA_MenSF_CreateRiflemanAT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_MenSF_Autorifleman = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_MenSF, "Autorifleman", "PZFP_fnc_blufor_USA_MenSF_CreateAutorifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_MenSF_Marksman = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_MenSF, "Marksman", "PZFP_fnc_blufor_USA_MenSF_CreateMarksman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_MenSF_TeamLeader = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_MenSF, "Team Leader", "PZFP_fnc_blufor_USA_MenSF_CreateTeamLeader", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_MenSF_SquadLeader = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_MenSF, "Squad Leader", "PZFP_fnc_blufor_USA_MenSF_CreateSquadLeader", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_MenSF_JTAC = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_MenSF, "JTAC", "PZFP_fnc_blufor_USA_MenSF_CreateJTAC", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_MenSF_Medic = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_MenSF, "Medic", "PZFP_fnc_blufor_USA_MenSF_CreateMedic", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_MenSF_RTO = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_MenSF, "Radio-Telephone Operator", "PZFP_fnc_blufor_USA_MenSF_CreateRTO", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_MenSF_AmmoBearer = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_MenSF, "Ammo Bearer", "PZFP_fnc_blufor_USA_MenSF_CreateAmmoBearer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_MenSF_DemoSpecialist = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_MenSF, "Demolitions Specialist", "PZFP_fnc_blufor_USA_MenSF_CreateDemoSpecialist", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_MenSF_Engineer = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_MenSF, "Engineer", "PZFP_fnc_blufor_USA_MenSF_CreateEngineer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_MenSF_Sniper = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_MenSF, "Sniper", "PZFP_fnc_blufor_USA_MenSF_CreateSniper", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_MenSF_Spotter = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_MenSF, "Spotter", "PZFP_fnc_blufor_USA_MenSF_CreateSpotter", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_MenSF_Sergeant = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_MenSF, "Sergeant", "PZFP_fnc_blufor_USA_MenSF_CreateSergeant", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_MenSF_Officer = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_MenSF, "Officer", "PZFP_fnc_blufor_USA_MenSF_CreateOfficer", [1,1,1,1]] call PZFP_fnc_addModule;
  
  PZFP_blufor_USA_MenSFAB = [_blufor, PZFP_blufor_USA, "Men (Airborne)", [1,1,1,1]] call PZFP_fnc_addSubCategory;

  PZFP_blufor_USA_Tanks = [_blufor, PZFP_blufor_USA, "Tanks", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USA_Tanks_Slammer = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Tanks, "M2A1 Slammer", "PZFP_fnc_blufor_USA_Tanks_CreateSquadLeaderammer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Tanks_SlammerUp = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Tanks, "M2A4 Slammer (Urban Kit)", "PZFP_fnc_blufor_USA_Tanks_CreateSquadLeaderammerUp", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USA_TankDestroyers = [_blufor, PZFP_blufor_USA, "Tank Destroyers", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USA_TanksDestroyers_Rhino = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_TankDestroyers, "Rhino MGS", "PZFP_fnc_blufor_USA_TankDestroyers_CreateRhino", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_TanksDestroyers_RhinoUp = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_TankDestroyers, "Rhino MGS (Urban Kit)", "PZFP_fnc_blufor_USA_TankDestroyers_CreateRhinoUP", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USA_Turrets = [_blufor, PZFP_blufor_USA, "Turrets", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USA_Turrets_Radar = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Turrets, "AN/MPQ-105 Radar", "PZFP_fnc_blufor_USA_Turrets_CreateRadar", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Turrets_Defender = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Turrets, "MIM-145 Defender", "PZFP_fnc_blufor_USA_Turrets_CreateSAM", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Turrets_HMGTripod = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Turrets, "Mk30 HMG", "PZFP_fnc_blufor_USA_Turrets_CreateHMGTripod", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Turrets_HMGRaised = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Turrets, "Mk30 HMG (Raised)", "PZFP_fnc_blufor_USA_Turrets_CreateHMGRaised", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Turrets_HMGAuto = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Turrets, "Mk30A HMG", "PZFP_fnc_blufor_USA_Turrets_CreateHMGAuto", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Turrets_GMGTripod = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Turrets, "Mk32 GMG", "PZFP_fnc_blufor_USA_Turrets_CreateGMGTripod", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Turrets_GMGRaised = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Turrets, "Mk32 GMG (Raised)", "PZFP_fnc_blufor_USA_Turrets_CreateGMGRaised", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Turrets_GMGAuto = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Turrets, "Mk32A GMG", "PZFP_fnc_blufor_USA_Turrets_CreateGMGAuto", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Turrets_Praetorian = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Turrets, "Praetorian 1C", "PZFP_fnc_blufor_USA_Turrets_CreatePraetorian", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Turrets_Mortar = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Turrets, "Mk6 Mortar", "PZFP_fnc_blufor_USA_Turrets_CreateMortar", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Turrets_Designator = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Turrets, "Remote Designator", "PZFP_fnc_blufor_USA_Turrets_CreateDesignator", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Turrets_AA = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Turrets, "Static Launcher (AA)", "PZFP_fnc_blufor_USA_Turrets_CreateAA", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USA_Turrets_AT = [_blufor, PZFP_blufor_USA, PZFP_blufor_USA_Turrets, "Static Launcher (AT)", "PZFP_fnc_blufor_USA_Turrets_CreateAT", [1,1,1,1]] call PZFP_fnc_addModule;


  PZFP_blufor_USN = [_blufor, "United States Navy", [1,1,1,1]] call PZFP_fnc_addCategory;

  PZFP_blufor_USN_Boats = [_blufor, PZFP_blufor_USN, "Boats", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USN_Boats_AssaultBoat = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_Boats, "Assault Boat", "PZFP_fnc_blufor_USN_Boats_CreateAssaultBoat", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_Boats_RescueBoat = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_Boats, "Rescue Boat", "PZFP_fnc_blufor_USN_Boats_CreateRescueBoat", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_Boats_RHIB = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_Boats, "Rigid Hull Boat", "PZFP_fnc_blufor_USN_Boats_CreateRHIB", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_Boats_PatrolBoat = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_Boats, "Patrol Boat (Minigun)", "PZFP_fnc_blufor_USN_Boats_CreatePatrolBoat", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USN_Drones = [_blufor, PZFP_blufor_USN, "Drones", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USN_Drones_Sentinel = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_Drones, "UCAV Sentinel", "PZFP_fnc_blufor_USN_Drones_CreateSentinel", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USN_Men = [_blufor, PZFP_blufor_USN, "Men", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USN_Men_Rifleman = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_Men, "Rifleman", "PZFP_fnc_blufor_USN_Men_CreateRifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_Men_RiflemanUnarmed = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_Men, "Rifleman (Unarmed)", "PZFP_fnc_blufor_USN_Men_CreateRiflemanUnarmed", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_Men_ShipCrew = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_Men, "Ship Crew", "PZFP_fnc_blufor_USN_Men_CreateShipCrew", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USN_MenSOFFrogmen = [_blufor, PZFP_blufor_USN, "Men (Frogmen)", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USN_MenSOFFrogmen_Rifleman = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_MenSOFFrogmen, "Rifleman", "PZFP_fnc_blufor_USN_MenSOFFrogmen_CreateRifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_MenSOFFrogmen_ExplosiveSpecialist = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_MenSOFFrogmen, "Explosive Specialist", "PZFP_fnc_blufor_USN_MenSOFFrogmen_CreateExplosiveSpecialist", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_MenSOFFrogmen_TeamLeader = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_MenSOFFrogmen, "Team Leader", "PZFP_fnc_blufor_USN_MenSOFFrogmen_CreateTeamLeader", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USN_MenSOFRaiders = [_blufor, PZFP_blufor_USN, "Men (Naval Raiders)", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USN_MenSOFRaiders_Rifleman = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_MenSOFRaiders, "Rifleman", "PZFP_fnc_blufor_USN_MenSOFRaiders_CreateRifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_MenSOFRaiders_TeamLeader = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_MenSOFRaiders, "Team Leader", "PZFP_fnc_blufor_USN_MenSOFRaiders_CreateTeamLeader", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_MenSOFRaiders_ExplosiveSpecialist = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_MenSOFRaiders, "Explosive Specialist", "PZFP_fnc_blufor_USN_MenSOFRaiders_CreateExplosiveSpecialist", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_MenSOFRaiders_Medic = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_MenSOFRaiders, "Medic", "PZFP_fnc_blufor_USN_MenSOFRaiders_CreateMedic", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_MenSOFRaiders_RTO = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_MenSOFRaiders, "Radio-Telephone Operator", "PZFP_fnc_blufor_USN_MenSOFRaiders_CreateRTO", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USN_Pilots = [_blufor, PZFP_blufor_USN, "Pilots", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USN_Pilots_FighterPilot = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_Pilots, "Fighter Pilot", "PZFP_fnc_blufor_USN_Pilots_CreateFighterPilot", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_Pilots_TransportPilot = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_Pilots, "Transport Pilot", "PZFP_fnc_blufor_USN_Pilots_CreateTransportPilot", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USN_Planes = [_blufor, PZFP_blufor_USN, "Planes", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USN_Planes_Wasp = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_Planes, "F/A-181 Black Wasp II", "PZFP_fnc_blufor_USN_Planes_CreateBlackWasp", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_Planes_VTOL = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_Planes, "V-44/X Blackfish", "PZFP_fnc_blufor_USN_Planes_CreateVTOL", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_Planes_VTOLArmed = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_Planes, "V-44/X Blackfish (Gunship)", "PZFP_fnc_blufor_USN_Planes_CreateVTOLArmed", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_Planes_VTOLVehicle = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_Planes, "V-44/X Blackfish (Vehicle Transport)", "PZFP_fnc_blufor_USN_Planes_CreateVTOLVehicle", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_USN_StaticWeapons = [_blufor, PZFP_blufor_USN, "Static Weapons", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_USN_StaticWeapons_Centurion = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_StaticWeapons, "Mk21 Centurion", "PZFP_fnc_blufor_USN_Turrets_CreateCenturion", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_StaticWeapons_VLS = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_StaticWeapons, "Mk41 VLS", "PZFP_fnc_blufor_USN_Turrets_CreateVLS", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_StaticWeapons_Hammer = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_StaticWeapons, "Mk45 Hammer", "PZFP_fnc_blufor_USN_Turrets_CreateHammer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_StaticWeapons_Spartan = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_StaticWeapons, "Mk49 Spartan", "PZFP_fnc_blufor_USN_Turrets_CreateSpartan", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_USN_StaticWeapons_Praetorian = [_blufor, PZFP_blufor_USN, PZFP_blufor_USN_StaticWeapons, "Praetorian 1C", "PZFP_fnc_blufor_USN_Turrets_CreatePraetorian", [1,1,1,1]] call PZFP_fnc_addModule;


  PZFP_blufor_BA = [_blufor, "British Army", [1,1,1,1]] call PZFP_fnc_addCategory;

  PZFP_blufor_BA_AntiAir = [_blufor, PZFP_blufor_BA, "Anti-Air", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_BA_AntiAir_IFV6 = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_AntiAir, "IFV-6A Cheetah", "PZFP_fnc_blufor_BA_AntiAir_CreateIFV6", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_BA_APC = [_blufor, PZFP_blufor_BA, "APCs", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_BA_APC_CRV6Bobcat = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_APC, "CRV-6 Bobcat", "PZFP_fnc_blufor_BA_APC_CreateCRV6Bobcat", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_APC_vehicle2 = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_APC, "AFV-4 Gorgon", "PZFP_fnc_blufor_BA_APC_CreateGorgon", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_APC_IFV6cPanther = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_APC, "IFV-6c Panther", "PZFP_fnc_blufor_BA_APC_CreateIFV6cPanther", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_BA_Artillery = [_blufor, PZFP_blufor_BA, "Artillery", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_BA_Artillery_Scorcher = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Artillery, "M4 Scorcher", "PZFP_fnc_blufor_BA_Artillery_CreateScorcher", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Artillery_Sandstorm = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Artillery, "M5 Sandstorm", "PZFP_fnc_blufor_BA_Artillery_CreateSandstorm", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_BA_Boats = [_blufor, PZFP_blufor_BA, "Boats", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_BA_Boats_AssaultBoat = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Boats, "Assault Boat", "PZFP_fnc_blufor_BA_Boats_CreateAssaultBoat", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Boats_RescueBoat = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Boats, "Rescue Boat", "PZFP_fnc_blufor_BA_Boats_CreateRescueBoat", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Boats_RHIB = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Boats, "Rigid Hull Boat", "PZFP_fnc_blufor_BA_Boats_CreateRHIB", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_BA_Cars = [_blufor, PZFP_blufor_BA, "Cars", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_BA_Cars_HEMTT = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Cars, "HEMTT", "PZFP_fnc_blufor_BA_Cars_CreateHEMTT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Cars_HEMTTAmmo = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Cars, "HEMTT (Ammo)", "PZFP_fnc_blufor_BA_Cars_CreateHEMTTAmmo", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Cars_HEMTTBox = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Cars, "HEMTT (Box)", "PZFP_fnc_blufor_BA_Cars_CreateHEMTTBox", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Cars_HEMTTCargo = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Cars, "HEMTT (Cargo)", "PZFP_fnc_blufor_BA_Cars_CreateHEMTTCargo", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Cars_HEMTTFlatbed = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Cars, "HEMTT (Flatbed)", "PZFP_fnc_blufor_BA_Cars_CreateHEMTTFlatbed", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Cars_HEMTTFuel = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Cars, "HEMTT (Fuel)", "PZFP_fnc_blufor_BA_Cars_CreateHEMTTFuel", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Cars_HEMTTMedical = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Cars, "HEMTT (MEDEVAC)", "PZFP_fnc_blufor_BA_Cars_CreateHEMTTMedical", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Cars_HEMTTRepair = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Cars, "HEMTT (Repair)", "PZFP_fnc_blufor_BA_Cars_CreateHEMTTRepair", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Cars_HEMTTTransport = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Cars, "HEMTT Transport", "PZFP_fnc_blufor_BA_Cars_CreateHEMTTTransport", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Cars_HEMTTTransportCovered = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Cars, "HEMTT Transport (Covered)", "PZFP_fnc_blufor_BA_Cars_CreateHEMTTCovered", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Cars_Strider = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Cars, "Strider", "PZFP_fnc_blufor_BA_Cars_Strider", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Cars_StriderHMG = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Cars, "Strider (HMG)", "PZFP_fnc_blufor_BA_Cars_CreateStriderHMG", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Cars_StriderGMG = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Cars, "Strider (GMG)", "PZFP_fnc_blufor_BA_Cars_CreateStriderGMG", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_BA_Drones = [_blufor, PZFP_blufor_BA, "Drones", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_BA_Drones_Pelican = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Drones, "AL-6 Pelican", "PZFP_fnc_blufor_BA_Drones_CreatePelican", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Drones_PelicanMedical = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Drones, "AL-6 Pelican (Medical)", "PZFP_fnc_blufor_BA_Drones_CreatePelicanMedical", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Drones_Darter = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Drones, "AR-2 Darter", "PZFP_fnc_blufor_BA_Drones_CreateDarter", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Drones_Pelter = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Drones, "ED-1D Pelter (Demining)", "PZFP_fnc_blufor_BA_Drones_CreatePelter", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Drones_Roller = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Drones, "ED-1E Pelter (Science)", "PZFP_fnc_blufor_BA_Drones_CreateRoller", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Drones_Stomper = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Drones, "UGV Stomper", "PZFP_fnc_blufor_BA_Drones_CreateStomper", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Drones_StomperMG = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Drones, "UGV Stomper (Armed)", "PZFP_fnc_blufor_BA_Drones_CreateStomperMG", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_BA_Helicopters = [_blufor, PZFP_blufor_BA, "Helicopters", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_BA_Helicopters_Blackfoot = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Helicopters, "AH-99 Blackfoot", "PZFP_fnc_blufor_BA_Helicopters_CreateBlackfoot", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Helicopters_Huron = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Helicopters, "CH-67 Huron", "PZFP_fnc_blufor_BA_Helicopters_CreateHuron", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Helicopters_HuronArmed = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Helicopters, "CH-67 Huron (Armed)", "PZFP_fnc_blufor_BA_Helicopters_CreateHuronArmed", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Helicopters_Ghosthawk = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Helicopters, "UH-80 Ghost Hawk", "PZFP_fnc_blufor_BA_Helicopters_CreateGhosthawk", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Helicopters_GhosthawkStub = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Helicopters, "UH-80 Ghost Hawk (Stub Wings)", "PZFP_fnc_blufor_BA_Helicopters_CreateGhosthawkStub", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_BA_Men = [_blufor, PZFP_blufor_BA, "Men", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_BA_Men_Rifleman = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Rifleman", "PZFP_fnc_blufor_BA_Men_CreateRifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_LightAT = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Rifleman (Light AT)", "PZFP_fnc_blufor_BA_Men_CreateLAT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_AT = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Rifleman (AT)", "PZFP_fnc_blufor_BA_Men_CreateAT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_Autorifleman = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Autorifleman", "PZFP_fnc_blufor_BA_Men_CreateAutorifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_Marksman = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Marksman", "PZFP_fnc_blufor_BA_Men_CreateMarksman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_MachineGunner = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Machine Gunner", "PZFP_fnc_blufor_BA_Men_CreateMachineGunner", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_TeamLeader = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Team Leader", "PZFP_fnc_blufor_BA_Men_CreateTeamLeader", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_SquadLeader = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Squad Leader", "PZFP_fnc_blufor_BA_Men_CreateSquadLeader", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_AmmoBearer = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Ammo Bearer", "PZFP_fnc_blufor_BA_Men_CreateAmmoBearer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_Medic = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Medic", "PZFP_fnc_blufor_BA_Men_CreateMedic", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_RTO = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Radio-Telephone Operator", "PZFP_fnc_blufor_BA_Men_CreateRTO", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_Sergeant = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Sergeant", "PZFP_fnc_blufor_BA_Men_CreateSergeant", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_Officer = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Officer", "PZFP_fnc_blufor_BA_Men_CreateOfficer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_Crewman = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Crewman", "PZFP_fnc_blufor_BA_Men_CreateCrewman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_ExplosiveSpecialist = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Explosive Specialist", "PZFP_fnc_blufor_BA_Men_CreateExplosiveSpecialist", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_Survivor = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Survivor", "PZFP_fnc_blufor_BA_Men_CreateSurvivor", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_HelicopterPilot = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Helicopter Pilot", "PZFP_fnc_blufor_BA_Men_CreateHelicopterPilot", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_HelicopterCrew = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Helicopter Crew", "PZFP_fnc_blufor_BA_Men_CreateHelicopterCrew", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_MineSpecialist = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "Mine Specialist", "PZFP_fnc_blufor_BA_Men_CreateMineSpecialist", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Men_UAVOperator = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Men, "UAV Operator", "PZFP_fnc_blufor_BA_Men_CreateUAVOperator", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_BA_Turrets = [_blufor, PZFP_blufor_BA, "Turrets", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_BA_Turrets_Radar = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Turrets, "AN/MPQ-105 Radar", "PZFP_fnc_blufor_BA_Turrets_CreateRadar", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Turrets_Defender = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Turrets, "MIM-145 Defender", "PZFP_fnc_blufor_BA_Turrets_CreateSAM", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Turrets_HMGTripod = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Turrets, "Mk30 HMG", "PZFP_fnc_blufor_BA_Turrets_CreateHMGTripod", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Turrets_HMGRaised = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Turrets, "Mk30 HMG (Raised)", "PZFP_fnc_blufor_BA_Turrets_CreateHMGRaised", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Turrets_HMGAuto = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Turrets, "Mk30A HMG", "PZFP_fnc_blufor_BA_Turrets_CreateHMGAuto", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Turrets_GMGTripod = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Turrets, "Mk32 GMG", "PZFP_fnc_blufor_BA_Turrets_CreateGMGTripod", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Turrets_GMGRaised = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Turrets, "Mk32 GMG (Raised)", "PZFP_fnc_blufor_BA_Turrets_CreateGMGRaised", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Turrets_GMGAuto = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Turrets, "Mk32A GMG", "PZFP_fnc_blufor_BA_Turrets_CreateGMGAuto", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Turrets_Praetorian = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Turrets, "Praetorian 1C", "PZFP_fnc_blufor_BA_Turrets_CreatePraetorian", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Turrets_Mortar = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Turrets, "Mk6 Mortar", "PZFP_fnc_blufor_BA_Turrets_CreateMortar", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Turrets_Designator = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Turrets, "Remote Designator", "PZFP_fnc_blufor_BA_Turrets_CreateDesignator", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Turrets_AA = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Turrets, "Static Launcher (AA)", "PZFP_fnc_blufor_BA_Turrets_CreateAA", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_BA_Turrets_AT = [_blufor, PZFP_blufor_BA, PZFP_blufor_BA_Turrets, "Static Launcher (AT)", "PZFP_fnc_blufor_BA_Turrets_CreateAT", [1,1,1,1]] call PZFP_fnc_addModule;

  
  PZFP_blufor_AAFAF = [_blufor, "Altis Armed Forces Air Force", [1,1,1,1]] call PZFP_fnc_addCategory;

  PZFP_blufor_AAFAF_Pilots = [_blufor, PZFP_blufor_AAFAF, "Pilots", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_AAFAF_Pilots_FighterPilot = [_blufor, PZFP_blufor_AAFAF, PZFP_blufor_AAFAF_Pilots, "Fighter Pilot", "PZFP_fnc_blufor_AAFAF_Pilots_CreateFighterPilot", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_AAFAF_Planes = [_blufor, PZFP_blufor_AAFAF, "Planes", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_AAFAF_Planes_Buzzard = [_blufor, PZFP_blufor_AAFAF, PZFP_blufor_AAFAF_Planes, "A-143 Buzzard", "PZFP_fnc_blufor_AAFAF_Planes_CreateBuzzard", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFAF_Planes_Gryphon = [_blufor, PZFP_blufor_AAFAF, PZFP_blufor_AAFAF_Planes, "A-149 Gryphon", "PZFP_fnc_blufor_AAFAF_Planes_CreateGryphon", [1,1,1,1]] call PZFP_fnc_addModule;


  PZFP_blufor_AAFA = [_blufor, "Altis Armed Forces Land Forces", [1,1,1,1]] call PZFP_fnc_addCategory;

  PZFP_blufor_AAFA_AA = [_blufor, PZFP_blufor_AAFA, "Anti-Air", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_AAFA_AA_Nyx = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_AA, "AWC 302 Nyx (Anti-Air)", "PZFP_fnc_blufor_AAFA_AntiAir_CreateNyx", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_AAFA_APC = [_blufor, PZFP_blufor_AAFA, "APCs", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_AAFA_APC_vehicle2 = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_APC, "AFV-4 Gorgon", "PZFP_fnc_blufor_AAFA_APC_CreateGorgon", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_APC_Mora = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_APC, "FV-720 Mora", "PZFP_fnc_blufor_AAFA_APC_CreateMora", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_AAFA_Artillery = [_blufor, PZFP_blufor_AAFA, "Artillery", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_AAFA_Artillery_Zamak = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Artillery, "Zamak MLRS", "PZFP_fnc_blufor_AAFA_Artillery_CreateZamak", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_AAFA_Boats = [_blufor, PZFP_blufor_AAFA, "Boats", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_AAFA_Boats_AssaultBoat = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Boats, "Assault Boat", "PZFP_fnc_blufor_AAFA_Boats_CreateAssaultBoat", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Boats_RescueBoat = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Boats, "Rescue Boat", "PZFP_fnc_blufor_AAFA_Boats_CreateRescueBoat", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Boats_RHIB = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Boats, "Rigid Hull Boat", "PZFP_fnc_blufor_AAFA_Boats_CreateRHIB", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_AAFA_Cars = [_blufor, PZFP_blufor_AAFA, "Cars", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_AAFA_Cars_Strider = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Cars, "Strider", "PZFP_fnc_blufor_AAFA_Cars_CreateStrider", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Cars_StriderHMG = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Cars, "Strider (HMG)", "PZFP_fnc_blufor_AAFA_Cars_CreateStriderHMG", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Cars_StriderHNG = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Cars, "Strider (GMG)", "PZFP_fnc_blufor_AAFA_Cars_CreateStriderGMG", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Cars_ZamakAmmo = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Cars, "Zamak (Ammo)", "PZFP_fnc_blufor_AAFA_Cars_CreateZamakAmmo", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Cars_ZamakFuel = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Cars, "Zamak (Fuel)", "PZFP_fnc_blufor_AAFA_Cars_CreateZamakFuel", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Cars_ZamakMedical = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Cars, "Zamak (MEDEVAC)", "PZFP_fnc_blufor_AAFA_Cars_CreateZamakMedical", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Cars_ZamakRepair = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Cars, "Zamak (Repair)", "PZFP_fnc_blufor_AAFA_Cars_CreateZamakRepair", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Cars_ZamakTransport = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Cars, "Zamak Transport", "PZFP_fnc_blufor_AAFA_Cars_CreateZamakTransport", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Cars_ZamakTransportCovered = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Cars, "Zamak Transport (Covered)", "PZFP_fnc_blufor_AAFA_Cars_CreateZamakCovered", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_AAFA_Drones = [_blufor, PZFP_blufor_AAFA, "Drones", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_AAFA_Drones_Pelican = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Drones, "Pelican", "PZFP_fnc_blufor_AAFA_Drones_CreatePelican", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Drones_PelicanMedical = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Drones, "Pelican Medical", "PZFP_fnc_blufor_AAFA_Drones_CreatePelicanMedical", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Drones_Darter = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Drones, "Darter", "PZFP_fnc_blufor_AAFA_Drones_CreateDarter", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Drones_Pelter = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Drones, "Pelter", "PZFP_fnc_blufor_AAFA_Drones_CreatePelter", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Drones_Roller = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Drones, "Roller", "PZFP_fnc_blufor_AAFA_Drones_CreateRoller", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_AAFA_Helicopters = [_blufor, PZFP_blufor_AAFA, "Helicopters", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_AAFA_Helicopters_Mohawk = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Helicopters, "CH-49 Mohawk", "PZFP_fnc_blufor_AAFA_Helicopters_CreateMohawk", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Helicopters_Hellcat = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Helicopters, "WY-55 Hellcat", "PZFP_fnc_blufor_AAFA_Helicopters_CreateHellcat", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Helicopters_HellcatArmed = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Helicopters, "WY-55 Hellcat (Armed)", "PZFP_fnc_blufor_AAFA_Helicopters_CreateHellcatArmed", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Helicopters_Hummingbird = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Helicopters, "MH-9 Hummingbird", "PZFP_fnc_blufor_AAFA_Helicopters_CreateHummingbird", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Helicopters_Pawnee = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Helicopters, "AH-9 Pawnee", "PZFP_fnc_blufor_AAFA_Helicopters_CreatePawnee", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_AAFA_Men = [_blufor, PZFP_blufor_AAFA, "Men", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_AAFA_Men_Rifleman = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "Rifleman", "PZFP_fnc_blufor_AAFA_Men_CreateRifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Men_LightAT = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "Rifleman (Light AT)", "PZFP_fnc_blufor_AAFA_Men_CreateLAT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Men_AT = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "Rifleman (AT)", "PZFP_fnc_blufor_AAFA_Men_CreateAT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Men_Autorifleman = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "Autorifleman", "PZFP_fnc_blufor_AAFA_Men_CreateAutorifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Men_Marksman = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "Marksman", "PZFP_fnc_blufor_AAFA_Men_CreateMarksman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Men_TeamLeader = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "Team Leader", "PZFP_fnc_blufor_AAFA_Men_CreateTeamLeader", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Men_SquadLeader = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "Squad Leader", "PZFP_fnc_blufor_AAFA_Men_CreateSquadLeader", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Men_AmmoBearer = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "Ammo Bearer", "PZFP_fnc_blufor_AAFA_Men_CreateAmmoBearer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Men_Medic = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "Medic", "PZFP_fnc_blufor_AAFA_Men_CreateMedic", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Men_RTO = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "Radio-Telephone Operator", "PZFP_fnc_blufor_AAFA_Men_CreateRTO", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Men_Sergeant = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "Sergeant", "PZFP_fnc_blufor_AAFA_Men_CreateSergeant", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Men_Officer = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "Officer", "PZFP_fnc_blufor_AAFA_Men_CreateOfficer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Men_Crewman = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "Crewman", "PZFP_fnc_blufor_AAFA_Men_CreateCrewman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Men_ExplosiveSpecialist = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "Explosive Specialist", "PZFP_fnc_blufor_AAFA_Men_CreateExplosiveSpecialist", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Men_Survivor = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "Survivor", "PZFP_fnc_blufor_AAFA_Men_CreateSurvivor", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Men_HelicopterPilot = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "Helicopter Pilot", "PZFP_fnc_blufor_AAFA_Men_CreateHelicopterPilot", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Men_HelicopterCrew = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "Helicopter Crew", "PZFP_fnc_blufor_AAFA_Men_CreateHelicopterCrew", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Men_MineSpecialist = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "Mine Specialist", "PZFP_fnc_blufor_AAFA_Men_CreateMineSpecialist", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Men_UAVOperator = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Men, "UAV Operator", "PZFP_fnc_blufor_AAFA_Men_CreateUAVOperator", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_AAFA_MenSOF = [_blufor, PZFP_blufor_AAFA, "Men (Special Operations)", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_AAFA_MenSOF_Rifleman = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_MenSOF, "Rifleman", "PZFP_fnc_blufor_AAFA_MenSOF_CreateRifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_MenSOF_RiflemanLAT = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_MenSOF, "Rifleman (LAT)", "PZFP_fnc_blufor_AAFA_MenSOF_CreateRiflemanLAT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_MenSOF_RiflemanAT = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_MenSOF, "Rifleman (AT)", "PZFP_fnc_blufor_AAFA_MenSOF_CreateRiflemanAT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_MenSOF_Autorifleman = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_MenSOF, "Autorifleman", "PZFP_fnc_blufor_AAFA_MenSOF_CreateAutorifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_MenSOF_Marksman = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_MenSOF, "Marksman", "PZFP_fnc_blufor_AAFA_MenSOF_CreateMarksman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_MenSOF_TeamLeader = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_MenSOF, "Team Leader", "PZFP_fnc_blufor_AAFA_MenSOF_CreateTeamLeader", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_MenSOF_SquadLeader = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_MenSOF, "Squad Leader", "PZFP_fnc_blufor_AAFA_MenSOF_CreateSquadLeader", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_MenSOF_JTAC = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_MenSOF, "JTAC", "PZFP_fnc_blufor_AAFA_MenSOF_CreateJTAC", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_MenSOF_Medic = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_MenSOF, "Medic", "PZFP_fnc_blufor_AAFA_MenSOF_CreateMedic", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_MenSOF_RTO = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_MenSOF, "Radio-Telephone Operator", "PZFP_fnc_blufor_AAFA_MenSOF_CreateRTO", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_MenSOF_AmmoBearer = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_MenSOF, "Ammo Bearer", "PZFP_fnc_blufor_AAFA_MenSOF_CreateAmmoBearer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_MenSOF_DemoSpecialist = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_MenSOF, "Demolitions Specialist", "PZFP_fnc_blufor_AAFA_MenSOF_CreateDemoSpecialist", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_MenSOF_Engineer = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_MenSOF, "Engineer", "PZFP_fnc_blufor_AAFA_MenSOF_CreateEngineer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_MenSOF_Sniper = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_MenSOF, "Sniper", "PZFP_fnc_blufor_AAFA_MenSOF_CreateSniper", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_MenSOF_Spotter = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_MenSOF, "Spotter", "PZFP_fnc_blufor_AAFA_MenSOF_CreateSpotter", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_MenSOF_Sergeant = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_MenSOF, "Sergeant", "PZFP_fnc_blufor_AAFA_MenSOF_CreateSergeant", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_MenSOF_Officer = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_MenSOF, "Officer", "PZFP_fnc_blufor_AAFA_MenSOF_CreateOfficer", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_AAFA_Tanks = [_blufor, PZFP_blufor_AAFA, "Tanks", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_AAFA_Tanks_Kuma = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Tanks, "MBT-52 Kuma", "PZFP_fnc_blufor_AAFA_Tanks_CreateKuma", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Tanks_NyxRecon = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Tanks, "AWC 302 Nyx (Recon)", "PZFP_fnc_blufor_AAFA_Tanks_CreateNyxRecon", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Tanks_NyxAutocannon = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Tanks, "AWC 302 Nyx (Autocannon)", "PZFP_fnc_blufor_AAFA_Tanks_CreateNyxAutocannon", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Tanks_NyxAT = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Tanks, "AWC 302 Nyx (Anti-Tank)", "PZFP_fnc_blufor_AAFA_Tanks_CreateNyxAT", [1,1,1,1]] call PZFP_fnc_addModule;
  
  PZFP_blufor_AAFA_Turrets = [_blufor, PZFP_blufor_AAFA, "Turrets", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_AAFA_Turrets_HMG = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Turrets, "M2 HMG", "PZFP_fnc_blufor_AAFA_Turrets_CreateHMG", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Turrets_HMGTripod = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Turrets, "M2 HMG (Raised)", "PZFP_fnc_blufor_AAFA_Turrets_CreateHMGTripod", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Turrets_AA = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Turrets, "Static Launcher (AA)", "PZFP_fnc_blufor_AAFA_Turrets_CreateAA", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_AAFA_Turrets_AT = [_blufor, PZFP_blufor_AAFA, PZFP_blufor_AAFA_Turrets, "Static Launcher (AT)", "PZFP_fnc_blufor_AAFA_Turrets_CreateAT", [1,1,1,1]] call PZFP_fnc_addModule;
 

  PZFP_blufor_LDFAF = [_blufor, "Livonian Defense Force Air Force", [1,1,1,1]] call PZFP_fnc_addCategory;

  PZFP_blufor_LDFAF_Pilots = [_blufor, PZFP_blufor_LDFAF, "Pilots", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_LDFAF_Pilots_FighterPilot = [_blufor, PZFP_blufor_LDFAF, PZFP_blufor_LDFAF_Pilots, "Fighter Pilot", "PZFP_fnc_blufor_LDFAF_Pilots_CreateFighterPilot", [1,1,1,1]] call PZFP_fnc_addModule;
  
  PZFP_blufor_LDFAF_Planes = [_blufor, PZFP_blufor_LDFAF, "Planes", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_LDFAF_Planes_Gryphon = [_blufor, PZFP_blufor_LDFAF, PZFP_blufor_LDFAF_Planes, "A-149 Gryphon", "PZFP_fnc_blufor_LDFAF_Planes_CreateGryphon", [1,1,1,1]] call PZFP_fnc_addModule;


  PZFP_blufor_LDF = [_blufor, "Livonian Defense Force Army", [1,1,1,1]] call PZFP_fnc_addCategory;

  PZFP_blufor_LDF_Artillery = [_blufor, PZFP_blufor_LDF, "Artillery", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_LDF_Artillery_Sandstorm = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Artillery, "M5 Sandstorm MLRS", "PZFP_fnc_blufor_LDF_Artillery_CreateSandstorm", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Artillery_Zamak = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Artillery, "Zamak MLRS", "PZFP_fnc_blufor_LDF_Artillery_CreateZamak", [1,1,1,1]] call PZFP_fnc_addModule;
  
  PZFP_blufor_LDF_Cars = [_blufor, PZFP_blufor_LDF, "Cars", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_LDF_Cars_Offroad = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Cars, "Offroad", "PZFP_fnc_blufor_LDF_Cars_CreateOffroad", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Cars_OffroadMG = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Cars, "Offroad (HMG)", "PZFP_fnc_blufor_LDF_Cars_CreateOffroadMG", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Cars_OffroadAT = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Cars, "Offroad (AT)", "PZFP_fnc_blufor_LDF_Cars_CreateOffroadAT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Cars_OffroadCovered = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Cars, "Offroad (Covered)", "PZFP_fnc_blufor_LDF_Cars_CreateOffroadCovered", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Cars_OffroadComms = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Cars, "Offroad (Comms)", "PZFP_fnc_blufor_LDF_Cars_CreateOffroadComms", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Cars_VanTransport = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Cars, "Van Transport", "PZFP_fnc_blufor_LDF_Cars_CreateVanTransport", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Cars_VanCargo = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Cars, "Van Cargo", "PZFP_fnc_blufor_LDF_Cars_CreateVanCargo", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Cars_VanAmbulance = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Cars, "Van Ambulance", "PZFP_fnc_blufor_LDF_Cars_CreateVanAmbulance", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Cars_ZamakTransport = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Cars, "Zamak Transport", "PZFP_fnc_blufor_LDF_Cars_CreateZamakTransport", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Cars_ZamakTransportCovered = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Cars, "Zamak Transport (Covered)", "PZFP_fnc_blufor_LDF_Cars_CreateZamakTransportCovered", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Cars_ZamakAmmo = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Cars, "Zamak Ammo", "PZFP_fnc_blufor_LDF_Cars_CreateZamakAmmo", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Cars_ZamakFuel = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Cars, "Zamak Fuel", "PZFP_fnc_blufor_LDF_Cars_CreateZamakFuel", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Cars_ZamakRepair = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Cars, "Zamak Repair", "PZFP_fnc_blufor_LDF_Cars_CreateZamakRepair", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Cars_ZamakMedical = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Cars, "Zamak Medical", "PZFP_fnc_blufor_LDF_Cars_CreateZamakMedical", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_LDF_Drones = [_blufor, PZFP_blufor_LDF, "Drones", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_LDF_Drones_Pelican = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Drones, "AL-6 Pelican", "PZFP_fnc_blufor_LDF_Drones_CreatePelican", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Drones_PelicanDropper = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Drones, "AL-6 Pelican (Grenade Dropper)", "PZFP_fnc_blufor_LDF_Drones_CreatePelicanDropper", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Drones_PelicanDropperMortar = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Drones, "AL-6 Pelican (Mortar Dropper)", "PZFP_fnc_blufor_LDF_Drones_CreatePelicanDropperMortar", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Drones_PelicanCharge = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Drones, "AL-6 Pelican (Charge)", "PZFP_fnc_blufor_LDF_Drones_CreatePelicanCharge", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Drones_PelicanMedical = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Drones, "AL-6 Pelican (Medical)", "PZFP_fnc_blufor_LDF_Drones_CreatePelicanMedical", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Drones_Darter = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Drones, "AR-2 Darter", "PZFP_fnc_blufor_LDF_Drones_CreateDarter", [1,1,1,1]] call PZFP_fnc_addModule;
  comment "they should have a lot more drones theyre basically ukranian";

  PZFP_blufor_LDF_Helicopters = [_blufor, PZFP_blufor_LDF, "Helicopters", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_LDF_Helicopters_Czapla = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Helicopters, "WY-55 Czapla", "PZFP_fnc_blufor_LDF_Helicopters_CreateCzapla", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Helicopters_CzaplaArmed = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Helicopters, "WY-55 Czapla (Armed)", "PZFP_fnc_blufor_LDF_Helicopters_CreateCzaplaArmed", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_LDF_Men = [_blufor, PZFP_blufor_LDF, "Men", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_LDF_Men_Rifleman = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "Rifleman", "PZFP_fnc_blufor_LDF_Men_CreateRifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Men_LightAT = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "Rifleman (Light AT)", "PZFP_fnc_blufor_LDF_Men_CreateRiflemanLAT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Men_AT = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "Rifleman (AT)", "PZFP_fnc_blufor_LDF_Men_CreateRiflemanAT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Men_Autorifleman = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "Autorifleman", "PZFP_fnc_blufor_LDF_Men_CreateAutorifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Men_Marksman = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "Marksman", "PZFP_fnc_blufor_LDF_Men_CreateMarksman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Men_TeamLeader = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "Team Leader", "PZFP_fnc_blufor_LDF_Men_CreateTeamLeader", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Men_SquadLeader = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "Squad Leader", "PZFP_fnc_blufor_LDF_Men_CreateSquadLeader", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Men_AmmoBearer = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "Ammo Bearer", "PZFP_fnc_blufor_LDF_Men_CreateAmmoBearer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Men_Medic = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "Medic", "PZFP_fnc_blufor_LDF_Men_CreateMedic", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Men_RTO = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "Radio-Telephone Operator", "PZFP_fnc_blufor_LDF_Men_CreateRTO", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Men_Sergeant = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "Sergeant", "PZFP_fnc_blufor_LDF_Men_CreateSergeant", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Men_Officer = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "Officer", "PZFP_fnc_blufor_LDF_Men_CreateOfficer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Men_Crewman = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "Crewman", "PZFP_fnc_blufor_LDF_Men_CreateCrewman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Men_ExplosiveSpecialist = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "Explosive Specialist", "PZFP_fnc_blufor_LDF_Men_CreateExplosiveSpecialist", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Men_Survivor = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "Survivor", "PZFP_fnc_blufor_LDF_Men_CreateSurvivor", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Men_HelicopterPilot = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "Helicopter Pilot", "PZFP_fnc_blufor_LDF_Men_CreateHelicopterPilot", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Men_HelicopterCrew = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "Helicopter Crew", "PZFP_fnc_blufor_LDF_Men_CreateHelicopterCrew", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Men_MineSpecialist = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "Mine Specialist", "PZFP_fnc_blufor_LDF_Men_CreateMineSpecialist", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Men_UAVOperator = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Men, "UAV Operator", "PZFP_fnc_blufor_LDF_Men_CreateUAVOperator", [1,1,1,1]] call PZFP_fnc_addModule;
  
  PZFP_blufor_LDF_MenSOF = [_blufor, PZFP_blufor_LDF, "Men (SOF)", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_LDF_MenSOF_Rifleman = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_MenSOF, "Rifleman", "PZFP_fnc_blufor_LDF_MenSOF_CreateRifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_MenSOF_RiflemanLAT = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_MenSOF, "Rifleman (LAT)", "PZFP_fnc_blufor_LDF_MenSOF_CreateRiflemanLAT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_MenSOF_RiflemanAT = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_MenSOF, "Rifleman (AT)", "PZFP_fnc_blufor_LDF_MenSOF_CreateRiflemanAT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_MenSOF_Autorifleman = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_MenSOF, "Autorifleman", "PZFP_fnc_blufor_LDF_MenSOF_CreateAutorifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_MenSOF_Marksman = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_MenSOF, "Marksman", "PZFP_fnc_blufor_LDF_MenSOF_CreateMarksman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_MenSOF_TeamLeader = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_MenSOF, "Team Leader", "PZFP_fnc_blufor_LDF_MenSOF_CreateTeamLeader", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_MenSOF_SquadLeader = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_MenSOF, "Squad Leader", "PZFP_fnc_blufor_LDF_MenSOF_CreateSquadLeader", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_MenSOF_JTAC = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_MenSOF, "JTAC", "PZFP_fnc_blufor_LDF_MenSOF_CreateJTAC", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_MenSOF_Medic = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_MenSOF, "Medic", "PZFP_fnc_blufor_LDF_MenSOF_CreateMedic", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_MenSOF_RTO = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_MenSOF, "Radio-Telephone Operator", "PZFP_fnc_blufor_LDF_MenSOF_CreateRTO", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_MenSOF_AmmoBearer = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_MenSOF, "Ammo Bearer", "PZFP_fnc_blufor_LDF_MenSOF_CreateAmmoBearer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_MenSOF_DemoSpecialist = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_MenSOF, "Demolitions Specialist", "PZFP_fnc_blufor_LDF_MenSOF_CreateDemoSpecialist", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_MenSOF_Engineer = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_MenSOF, "Engineer", "PZFP_fnc_blufor_LDF_MenSOF_CreateEngineer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_MenSOF_Sergeant = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_MenSOF, "Sergeant", "PZFP_fnc_blufor_LDF_MenSOF_CreateSergeant", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_MenSOF_Officer = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_MenSOF, "Officer", "PZFP_fnc_blufor_LDF_MenSOF_CreateOfficer", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_blufor_LDF_Turrets = [_blufor, PZFP_blufor_LDF, "Turrets", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_LDF_Turrets_HMG = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Turrets, "M2 HMG", "PZFP_fnc_blufor_LDF_Turrets_CreateHMG", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Turrets_HMGTripod = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Turrets, "M2 HMG (Raised)", "PZFP_fnc_blufor_LDF_Turrets_CreateHMGTripod", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Turrets_AA = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Turrets, "Static Launcher (AA)", "PZFP_fnc_blufor_LDF_Turrets_CreateAA", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_LDF_Turrets_AT = [_blufor, PZFP_blufor_LDF, PZFP_blufor_LDF_Turrets, "Static Launcher (AT)", "PZFP_fnc_blufor_LDF_Turrets_CreateAT", [1,1,1,1]] call PZFP_fnc_addModule;
  
  PZFP_blufor_StrazLesna = [_blufor, "Straż Leśną Livonia", [1,1,1,1]] call PZFP_fnc_addCategory;

  PZFP_blufor_StrazLesna_Cars = [_blufor, PZFP_blufor_StrazLesna, "Cars", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_StrazLesna_Cars_Offroad = [_blufor, PZFP_blufor_StrazLesna, PZFP_blufor_StrazLesna_Cars, "Offroad", "PZFP_fnc_blufor_StrazLesna_Cars_CreateOffroad", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_StrazLesna_Cars_OffroadHMG = [_blufor, PZFP_blufor_StrazLesna, PZFP_blufor_StrazLesna_Cars, "Offroad (HMG)", "PZFP_fnc_blufor_StrazLesna_Cars_CreateOffroadHMG", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_StrazLesna_Cars_OffroadCovered = [_blufor, PZFP_blufor_StrazLesna, PZFP_blufor_StrazLesna_Cars, "Offroad (Covered)", "PZFP_fnc_blufor_StrazLesna_Cars_CreateOffroadCovered", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_StrazLesna_Cars_OffroadComms = [_blufor, PZFP_blufor_StrazLesna, PZFP_blufor_StrazLesna_Cars, "Offroad (Comms)", "PZFP_fnc_blufor_StrazLesna_Cars_CreateOffroadComms", [1,1,1,1]] call PZFP_fnc_addModule;
  
  PZFP_blufor_StrazLesna_Men = [_blufor, PZFP_blufor_StrazLesna, "Officers", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_blufor_StrazLesna_Men_Officer = [_blufor, PZFP_blufor_StrazLesna, PZFP_blufor_StrazLesna_Men, "Officer", "PZFP_fnc_blufor_StrazLesna_Men_CreateOfficer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_StrazLesna_Men_OfficerShotgun = [_blufor, PZFP_blufor_StrazLesna, PZFP_blufor_StrazLesna_Men, "Officer (Shotgun)", "PZFP_fnc_blufor_StrazLesna_Men_CreateOfficerShotgun", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_blufor_StrazLesna_Men_OfficerRifle = [_blufor, PZFP_blufor_StrazLesna, PZFP_blufor_StrazLesna_Men, "Officer (Rifle)", "PZFP_fnc_blufor_StrazLesna_Men_CreateOfficerRifle", [1,1,1,1]] call PZFP_fnc_addModule;
  
  
  PZFP_opforDividerSpace = [_opfor, "", [1,1,1,0]] call PZFP_fnc_addCategory;
  PZFP_opforTitle = [_opfor, "PZFP Factions", [0.7,0.3,0,1]] call PZFP_fnc_addCategory;
  PZFP_opforDivider = [_opfor, "--------------------------------------------", [0.7,0.3,0,1]] call PZFP_fnc_addCategory;

  PZFP_opfor_IRAF = [_opfor, "Islamic Republic of Iran Air Force", [1,1,1,1]] call PZFP_fnc_addCategory;

  PZFP_opfor_IRAF_Drones = [_opfor, PZFP_opfor_IRAF, "Drones", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_opfor_IRAF_Drones_Fenghuang = [_opfor, PZFP_opfor_IRAF, PZFP_opfor_IRAF_Drones, "KH-3A Fenghuang", "PZFP_fnc_opfor_IRAF_Drones_CreateFenghuang", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_opfor_IRAF_MaintenanceCrew = [_opfor, PZFP_opfor_IRAF, "Maintenance Crew", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_opfor_IRAF_MaintenanceCrew_RepairSpecialist = [_opfor, PZFP_opfor_IRAF, PZFP_opfor_IRAF_MaintenanceCrew, "Repair Specialist", "PZFP_fnc_opfor_IRAF_MaintenanceCrew_CreateRepairSpecialist", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_opfor_IRAF_Pilots = [_opfor, PZFP_opfor_IRAF, "Pilots", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_opfor_IRAF_Pilots_FighterPilot = [_opfor, PZFP_opfor_IRAF, PZFP_opfor_IRAF_Pilots, "Fighter Pilot", "PZFP_fnc_opfor_IRAF_Pilots_CreateFighterPilot", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRAF_Pilots_TransportPilot = [_opfor, PZFP_opfor_IRAF, PZFP_opfor_IRAF_Pilots, "Transport Pilot", "PZFP_fnc_opfor_IRAF_Pilots_CreateTransportPilot", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_opfor_IRAF_Planes = [_opfor, PZFP_opfor_IRAF, "Planes", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_opfor_IRAF_Planes_Neophron = [_opfor, PZFP_opfor_IRAF, PZFP_opfor_IRAF_Planes, "To-199 Neophron", "PZFP_fnc_opfor_IRAF_Planes_CreateNeophron", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRAF_Planes_Shikra = [_opfor, PZFP_opfor_IRAF, PZFP_opfor_IRAF_Planes, "To-201 Shikra", "PZFP_fnc_opfor_IRAF_Planes_CreateShikra", [1,1,1,1]] call PZFP_fnc_addModule;



  PZFP_opfor_IRGF = [_opfor, "Islamic Republic of Iran Ground Forces", [1,1,1,1]] call PZFP_fnc_addCategory;

  PZFP_opfor_IRGF_AntiAir = [_opfor, PZFP_opfor_IRGF, "Anti-Air", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_opfor_IRGF_AntiAir_Tigris = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_AntiAir, "ZSU-39 Tigiris", "PZFP_fnc_opfor_IRGF_AntiAir_CreateTigris", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_AntiAir_Kamysh = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_AntiAir, "BTR-K Kamysh (AA)", "PZFP_fnc_opfor_IRGF_AntiAir_CreateKamysh", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_opfor_IRGF_APCs = [_opfor, PZFP_opfor_IRGF, "APCs", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_opfor_IRGF_APCs_Kamysh = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_APCs, "BTR-K Kamysh", "PZFP_fnc_opfor_IRGF_APCs_CreateKamysh", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_APCs_Marid = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_APCs, "MSE-3 Marid", "PZFP_fnc_opfor_IRGF_APCs_CreateMarid", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_APCs_MaridAutocannon = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_APCs, "MSE-3 Marid (Autocannon)", "PZFP_fnc_opfor_IRGF_APCs_CreateMaridAutocannon", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_opfor_IRGF_Artillery = [_opfor, PZFP_opfor_IRGF, "Artillery", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_opfor_IRGF_Artillery_Sochor = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Artillery, "2S9 Sochor", "PZFP_fnc_opfor_IRGF_Artillery_CreateSochor", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Artillery_Zamak = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Artillery, "Zamak MLRS", "PZFP_fnc_opfor_IRGF_Artillery_CreateZamak", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_opfor_IRGF_Cars = [_opfor, PZFP_opfor_IRGF, "Cars", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_opfor_IRGF_Cars_Ifrit = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Cars, "Ifrit","PZFP_fnc_opfor_IRGF_Cars_CreateIfrit", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Cars_IfritHMG = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Cars, "Ifrit (HMG)","PZFP_fnc_opfor_IRGF_Cars_CreateIfritHMG", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Cars_IfritGMG = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Cars, "Ifrit (GMG)","PZFP_fnc_opfor_IRGF_Cars_CreateIfritGMG", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Cars_ZamakTransport = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Cars, "Zamak Transport", "PZFP_fnc_opfor_IRGF_Cars_CreateZamakTransport", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Cars_ZamakTransportCovered = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Cars, "Zamak Transport (Covered)", "PZFP_fnc_opfor_IRGF_Cars_CreateZamakTransportCovered", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Cars_ZamakRepair = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Cars, "Zamak (Repair)", "PZFP_fnc_opfor_IRGF_Cars_CreateZamakRepair", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Cars_ZamakFuel = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Cars, "Zamak (Fuel)", "PZFP_fnc_opfor_IRGF_Cars_CreateZamakFuel", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Cars_ZamakAmmo = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Cars, "Zamak (Ammo)", "PZFP_fnc_opfor_IRGF_Cars_CreateZamakAmmo", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Cars_ZamakMedical = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Cars, "Zamak (Medical)", "PZFP_fnc_opfor_IRGF_Cars_CreateZamakMedical", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_opfor_IRGF_Drones = [_opfor, PZFP_opfor_IRGF, "Drones", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_opfor_IRGF_Drones_Jinaah = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Drones, "AL-6 Jinaah", "PZFP_fnc_opfor_IRGF_Drones_CreateJinaah", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Drones_JinaahMedical = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Drones, "AL-6 Jinaah (Medical)", "PZFP_fnc_opfor_IRGF_Drones_CreateJinaahMedical", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Drones_Tayran = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Drones, "AR-2 Tayran", "PZFP_fnc_opfor_IRGF_Drones_CreateTayran", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_opfor_IRGF_Helicopters = [_opfor, PZFP_opfor_IRGF, "Helicopters", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_opfor_IRGF_Helicopters_Taru = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Helicopters, "Mi-29 Taru", "PZFP_fnc_opfor_IRGF_Helicopters_CreateTaru", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Helicopters_TaruTransport = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Helicopters, "Mi-29 Taru (Transport)", "PZFP_fnc_opfor_IRGF_Helicopters_CreateTaruTransport", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Helicopters_TaruRepair = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Helicopters, "Mi-29 Taru (Repair)", "PZFP_fnc_opfor_IRGF_Helicopters_CreateTaruRepair", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Helicopters_TaruFuel = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Helicopters, "Mi-29 Taru (Fuel)", "PZFP_fnc_opfor_IRGF_Helicopters_CreateTaruFuel", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Helicopters_TaruAmmo = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Helicopters, "Mi-29 Taru (Ammo)", "PZFP_fnc_opfor_IRGF_Helicopters_CreateTaruAmmo", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Helicopters_TaruMedical = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Helicopters, "Mi-29 Taru (Medical)", "PZFP_fnc_opfor_IRGF_Helicopters_CreateTaruMedical", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Helicopters_TaruCargo = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Helicopters, "Mi-29 Taru (Cargo)", "PZFP_fnc_opfor_IRGF_Helicopters_CreateTaruCargo", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Helicopters_Kajman = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Helicopters, "Mi-48 Kajman", "PZFP_fnc_opfor_IRGF_Helicopters_CreateKajman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Helicopters_Orca = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Helicopters, "PO-30 Orca", "PZFP_fnc_opfor_IRGF_Helicopters_CreateOrca", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Helicopters_OrcaArmed = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Helicopters, "PO-30 Orca (Armed)", "PZFP_fnc_opfor_IRGF_Helicopters_CreateOrcaArmed", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_opfor_IRGF_Men = [_opfor, PZFP_opfor_IRGF, "Men", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_opfor_IRGF_Men_Rifleman = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "Rifleman", "PZFP_fnc_opfor_IRGF_Men_CreateRifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Men_LightAT = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "Rifleman (Light AT)", "PZFP_fnc_opfor_IRGF_Men_CreateLAT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Men_AT = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "Rifleman (AT)", "PZFP_fnc_opfor_IRGF_Men_CreateAT", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Men_Autorifleman = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "Autorifleman", "PZFP_fnc_opfor_IRGF_Men_CreateAutorifleman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Men_Marksman = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "Marksman", "PZFP_fnc_opfor_IRGF_Men_CreateMarksman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Men_TeamLeader = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "Team Leader", "PZFP_fnc_opfor_IRGF_Men_CreateTeamLeader", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Men_SquadLeader = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "Squad Leader", "PZFP_fnc_opfor_IRGF_Men_CreateSquadLeader", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Men_AmmoBearer = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "Ammo Bearer", "PZFP_fnc_opfor_IRGF_Men_CreateAmmoBearer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Men_Medic = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "Medic", "PZFP_fnc_opfor_IRGF_Men_CreateMedic", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Men_RTO = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "Radio-Telephone Operator", "PZFP_fnc_opfor_IRGF_Men_CreateRTO", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Men_Sergeant = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "Sergeant", "PZFP_fnc_opfor_IRGF_Men_CreateSergeant", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Men_Officer = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "Officer", "PZFP_fnc_opfor_IRGF_Men_CreateOfficer", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Men_Crewman = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "Crewman", "PZFP_fnc_opfor_IRGF_Men_CreateCrewman", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Men_ExplosiveSpecialist = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "Explosive Specialist", "PZFP_fnc_opfor_IRGF_Men_CreateExplosiveSpecialist", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Men_Survivor = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "Survivor", "PZFP_fnc_opfor_IRGF_Men_CreateSurvivor", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Men_HelicopterPilot = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "Helicopter Pilot", "PZFP_fnc_opfor_IRGF_Men_CreateHelicopterPilot", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Men_HelicopterCrew = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "Helicopter Crew", "PZFP_fnc_opfor_IRGF_Men_CreateHelicopterCrew", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Men_MineSpecialist = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "Mine Specialist", "PZFP_fnc_opfor_IRGF_Men_CreateMineSpecialist", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Men_UAVOperator = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Men, "UAV Operator", "PZFP_fnc_opfor_IRGF_Men_CreateUAVOperator", [1,1,1,1]] call PZFP_fnc_addModule;
  
  PZFP_opfor_IRGF_Tanks = [_opfor, PZFP_opfor_IRGF, "Tanks", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_opfor_IRGF_Tanks_Varsuk = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Tanks, "T-100 Varsuk", "PZFP_fnc_opfor_IRGF_Tanks_CreateVarsuk", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Tanks_Angara = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Tanks, "T-140 Angara", "PZFP_fnc_opfor_IRGF_Tanks_CreateAngara", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Tanks_AngaraUP = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Tanks, "T-140K Angara", "PZFP_fnc_opfor_IRGF_Tanks_CreateAngaraUP", [1,1,1,1]] call PZFP_fnc_addModule;

  PZFP_opfor_IRGF_Turrets = [_opfor, PZFP_opfor_IRGF, "Turrets", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_opfor_IRGF_Turrets_HMG = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Turrets, "Mk30 HMG", "PZFP_fnc_opfor_IRGF_Turrets_CreateHMG", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Turrets_HMGTripod = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Turrets, "Mk30 HMG (Raised Tripod)", "PZFP_fnc_opfor_IRGF_Turrets_CreateHMG", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Turrets_GMG = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Turrets, "Mk32 GMG", "PZFP_fnc_opfor_IRGF_Turrets_CreateGMG", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Turrets_GMGTripod = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Turrets, "Mk32 GMG (Raised Tripod)", "PZFP_fnc_opfor_IRGF_Turrets_CreateGMGTripod", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Turrets_Mortar = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Turrets, "Mk6 Mortar", "PZFP_fnc_opfor_IRGF_Turrets_CreateMortar", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Turrets_Radar = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Turrets, "R-750 Cronus Radar", "PZFP_fnc_opfor_IRGF_Turrets_CreateRadar", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Turrets_Designator = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Turrets, "Remote Designator", "PZFP_fnc_opfor_IRGF_Turrets_CreateDesignator", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Turrets_SAM = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Turrets, "S-750 Rhea", "PZFP_fnc_opfor_IRGF_Turrets_CreateSAM", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Turrets_AA = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Turrets, "Static Titan Launcher (AA)", "PZFP_fnc_opfor_IRGF_Turrets_CreateAA", [1,1,1,1]] call PZFP_fnc_addModule;
  PZFP_opfor_IRGF_Turrets_AT = [_opfor, PZFP_opfor_IRGF, PZFP_opfor_IRGF_Turrets, "Static Titan Launcher (AT)", "PZFP_fnc_opfor_IRGF_Turrets_CreateAT", [1,1,1,1]] call PZFP_fnc_addModule;
  

  PZFP_opfor_IRN = [_opfor, "Iranian Navy", [1,1,1,1]] call PZFP_fnc_addCategory;
  PZFP_opfor_IRN_Frogmen = [_opfor, PZFP_opfor_IRN, "Frogmen", [1,1,1,1]] call PZFP_fnc_addSubCategory;
  PZFP_opfor_IRN_Frogmen_Rifleman = [_opfor, PZFP_opfor_IRN, PZFP_IRN_Frogmen, "Rifleman", "PZFP_fnc_opfor_IRN_Frogmen_CreateRifleman", [1,1,1,1]] call PZFP_fnc_addModule;

  
 };

 PZFP_fnc_mainLoop = {
  [] spawn {
   while { true } do {
	  waitUntil { !isNull (findDisplay 312) };
	  sleep 0.1;

	  [] call PZFP_fnc_rebuildZeusTree;

	  waitUntil {  isNull (findDisplay 312) };
   };
  };
 };

 missionNamespace setVariable ["PZFP_initialized", true];
 systemChat "[PZFP] - PZFP initialized!";
 call BIS_fnc_VRFadeIn;
 [] call PZFP_fnc_mainLoop;
};

[] spawn PZFP_fnc_initialize;
