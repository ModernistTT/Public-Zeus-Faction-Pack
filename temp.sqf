PZFP_Enhancements_fnc_initialize = {


	PZFP_Enhancements_fnc_DroneSounds = {
		private _startupbeep = 'a3\sounds_f\arsenal\tools\minedetector_beep_01.wss';

		addMissionEventHandler ["EntityCreated", {
			params ["_entity"];
			private _type = typeOf _entity;
			if (_type in ["B_UAV_01_F", "O_UAV_01_F", "I_UAV_01_F", "C_UAV_01_F",
						"B_UAV_06_F", "O_UAV_06_F", "I_UAV_06_F"]) then {
				_entity addEventHandler ["Engine", {
					params ["_vehicle", "_engineState"];
					playSound3D [
						"a3\sounds_f\arsenal\tools\minedetector_beep_01.wss",
						objNull,
						false,
						getPosASL _vehicle,
						1,
						0.5,
						5
					];
				}];
			};
		}];
	};

	[] call PZFP_Enhancements_fnc_DroneSounds;
};

[] spawn PZFP_Enhancements_fnc_initialize;
deleteVehicle this;