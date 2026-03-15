
comment "Exported from Arsenal by Modernist";

comment "[!] UNIT MUST BE LOCAL [!]";
if (!local this) exitWith {};

comment "Remove existing items";
removeAllWeapons this;
removeAllItems this;
removeAllAssignedItems this;
removeUniform this;
removeVest this;
removeBackpack this;
removeHeadgear this;
removeGoggles this;

comment "Add weapons";
this addWeapon "srifle_DMR_03_woodland_F";
this addPrimaryWeaponItem "muzzle_snds_B_khk_F";
this addPrimaryWeaponItem "optic_AMS";
this addPrimaryWeaponItem "20Rnd_762x51_Mag";
this addPrimaryWeaponItem "bipod_01_F_blk";
this addWeapon "hgun_P07_F";
this addHandgunItem "muzzle_snds_L";
this addHandgunItem "16Rnd_9x21_Mag";

comment "Add containers";
this forceAddUniform "U_B_T_FullGhillie_tna_F";
this addVest "V_Chestrig_rgr";

comment "Add binoculars";
this addMagazine "Laserbatteries";
this addWeapon "Laserdesignator";

comment "Add items to containers";
this addItemToUniform "FirstAidKit";
this addItemToUniform "Chemlight_blue";
this addItemToUniform "Laserbatteries";
for "_i" from 1 to 3 do {this addItemToUniform "20Rnd_762x51_Mag";};
for "_i" from 1 to 2 do {this addItemToVest "16Rnd_9x21_Mag";};
this addItemToVest "APERSTripMine_Wire_Mag";
this addItemToVest "SmokeShellGreen";
this addItemToVest "SmokeShellBlue";
this addItemToVest "SmokeShellOrange";
this addItemToVest "B_IR_Grenade";

comment "Add items";
this linkItem "ItemMap";
this linkItem "ItemCompass";
this linkItem "ItemWatch";
this linkItem "ItemRadio";
this linkItem "ItemGPS";
this linkItem "NVGoggles";

comment "Set identity";
[this,"WhiteHead_11","male02eng"] call BIS_fnc_setIdentity;
