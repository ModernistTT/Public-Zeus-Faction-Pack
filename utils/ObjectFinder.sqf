comment "Object Exporter Script";

[this] spawn {
params ["_refObj"];

private _radius = 100;

private _objects = nearestObjects [_refObj, [], _radius];

_objects = _objects select { _x != _refObj };

private _lines = [];
private _index = 0;
private _newline = toString [13,10];

{
    _index = _index + 1;

    private _cls    = typeOf _x;
    private _relPos = _refObj worldToModel (getPosWorld _x);   
    private _rot    = [vectorDir _x, vectorUp _x];   


    private _line = format [
        "_object%1 = createSimpleObject [%2, this modelToWorld %3];%4_object%1 setVectorDirAndUp %5;",
        _index,
        str _cls, 
        str _relPos,  
        _newline,
        str _rot 
    ];

    _lines pushBack _line;

} forEach _objects;

private _exportText = _lines joinString _newline;
copyToClipboard _exportText;

systemChat format ["Exported %1 objects to clipboard.", _index];
hint format ["Exported %1 objects to clipboard.", _index];
};