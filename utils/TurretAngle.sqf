[player] spawn {
    private _pl = _this select 0;
    while {alive _pl} do {
        private _veh = vehicle _pl;
        if (_veh == _pl) then {
            hintSilent "Turret elevation: Not in a vehicle/turret";
            sleep 0.5;
            continue;
        };

        private _weapon = currentWeapon _veh;
        private _dir = [_veh,_weapon] call BIS_fnc_weaponDirectionRelative;

        private _x = _dir select 0;
        private _y = _dir select 1;
        private _z = _dir select 2;

        private _hMag = sqrt((_x * _x) + (_y * _y));

        private _pitchDeg = _z atan2 _hMag;

        private _pitchRounded = round (_pitchDeg * 100) / 100;
        hintSilent format ["Turret elevation: %1°", _pitchRounded];

        sleep 0.1;
    };
};
