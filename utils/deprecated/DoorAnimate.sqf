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