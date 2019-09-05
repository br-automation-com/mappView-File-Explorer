
TYPE
	ClientInfoType : 	STRUCT 
		userId : WSTRING[80];
		isValid : BOOL;
		ipAddress : WSTRING[15];
		languageId : WSTRING[2];
		screenResolution : WSTRING[32];
		slotId : SINT;
	END_STRUCT;
	typERR_EXP : 	STRUCT 
		txt : STRING[100]; (* Error text *)
		nr : UINT; (* Error number *)
		step : USINT; (* Error step *)
	END_STRUCT;
	typCMD_EXP : 	STRUCT 
		refresh : BOOL; (* Read directory and file names from devices *)
		dir_change : BOOL; (* Change current directory *)
		dir_create : BOOL; (* Create a new directory *)
		copy : BOOL; (* Copy selected item from device a TO device b *)
		copyall : BOOL; (* Copy all items from device a TO device b	*)
		delete : BOOL; (* Delete selected file *)
	END_STRUCT;
	typPAR_EXP : 	STRUCT 
		device_active : STRING[40]; (* Device name *)
		device_list : ARRAY[0..4]OF STRING[40]; (* Device name *)
		item_filter : STRING[4]; (* Only show files with this extension	*)
		dir_name : STRING[DIR_PATH_SIZE]; (* Directory name for create *)
		dir_path : STRING[DIR_PATH_SIZE]; (* Current directory path	*)
	END_STRUCT;
	typDAT_EXP : 	STRUCT 
		item_list : ARRAY[0..DAT_LIST_NUM]OF STRING[DAT_ITEM_SIZE]; (* List with file names	*)
		item_size : ARRAY[0..DAT_LIST_NUM]OF STRING[DAT_SIZE_SIZE]; (* List with file names *)
		item_num : UINT; (* Number OF files	*)
	END_STRUCT;
	typVIS_EXP : 	STRUCT 
		item_selected : UINT; (* Current selected file *)
		enable_copy_delete : BOOL; (*Enable or disable buttons copy and delete*)
		double_click_dir_change : USINT;
		device_list : ARRAY[0..4]OF STRING[80]; (* Device name *)
	END_STRUCT;
	typMain_EXP : 	STRUCT 
		CMD : ARRAY[0..1]OF typCMD_EXP; (* Command structure *)
		PAR : ARRAY[0..1]OF typPAR_EXP; (* Parameter structure *)
		DAT : ARRAY[0..1]OF typDAT_EXP;
		VIS : ARRAY[0..1]OF typVIS_EXP;
		ERR : typERR_EXP; (* Error structure *)
		status : STRING[50]; (* Actual step	*)
	END_STRUCT;
END_TYPE
