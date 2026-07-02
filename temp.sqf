PZFP_fnc_initSoldier_Syn_RiflemanAT = {        
 params ["_unit"];        
 private _uniforms = ["U_I_C_Soldier_Bandit_1_F", "U_I_C_Soldier_Bandit_2_F", "U_I_C_Soldier_Bandit_3_F", "U_I_C_Soldier_Bandit_4_F", "U_I_C_Soldier_Bandit_5_F", "U_BG_Guerilla2_1", "U_I_C_Soldier_Para_1_F"];            
 private _headgear = ["H_Bandanna_gry", "H_Bandanna_cbr", "H_Bandanna_khk", "H_Bandanna_sand", "H_Bandanna_surfer_blk", "H_Bandanna_camo", "H_Cap_oli", "H_Cap_grn", "H_Cap_blk", "H_Shemag_tan", "H_Shemag_olive", ""];        
 private _vests = ["V_TacChestrig_grn_F", "V_TacChestrig_oli_F", "V_TacChestrig_cbr_F"];  
 private _goggles = ["G_Bandanna_Syndikat2", "G_Bandanna_Syndikat1", "", "", "", ""];  
 private _packs = ["B_FieldPack_khk", "B_FieldPack_cbr"] 
        ;
 _unit forceAddUniform selectRandom _uniforms;        
 [_unit,[0, selectRandom _uniformtextures]] remoteExec ['setObjectTexture',0,true];        
 _unit addHeadgear selectRandom _headgear;        
 _unit addVest selectRandom _vests;  
 _unit addGoggles selectRandom _goggles; 
 _unit addBackpack selectRandom _packs; 
       
 _unit addWeapon "arifle_AKM_FL_F";    
 _unit addWeapon "launch_RPG7_F";  
 _unit addPrimaryWeaponItem "30Rnd_762x39_Mag_F";   
 _unit addSecondaryWeaponItem "RPG7_F";   
 _unit  addItemToUniform "FirstAidKit";     
 _unit addItemToUniform "MobilePhone";     
 _unit addItemToUniform "Wallet_ID";       
 _unit addItemToUniform "Chemlight_green";     
 _unit  addItemToUniform "SmokeShell";     
 for "_i" from 1 to 4 do {_unit addItemToVest "30Rnd_762x39_Mag_F"};    
 for "_i" from 1 to 2 do {_unit addItemToBackpack "RPG7_F"};   
 _unit addItemToVest "SmokeShellGreen";     
 _unit addItemToVest "SmokeShellBlue";     
 _unit addItemToVest "HandGrenade";     
 _unit linkItem "ItemMap";     
 _unit linkItem "ItemWatch";       
};        
        
[this] call PZFP_fnc_initSoldier_Syn_RiflemanAT;  
