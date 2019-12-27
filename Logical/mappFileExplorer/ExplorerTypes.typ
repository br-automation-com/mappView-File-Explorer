
TYPE
	ClientInfoType : 	STRUCT 
		userId : WSTRING[80];
		isValid : BOOL;
		ipAddress : WSTRING[15];
		languageId : WSTRING[2];
		screenResolution : WSTRING[32];
		slotId : SINT;
	END_STRUCT;
	expSTATE : 
		(
		EXP_WAIT,
		EXP_READ_DIR,
		EXP_READ_DIR_1,
		EXP_READ_DIR_2,
		EXP_READ_DIR_3,
		EXP_DIR_CHANGE,
		EXP_COPY_ALL,
		EXP_FILE_COPY,
		EXP_FILE_DELETE,
		EXP_FILE_RENAME,
		EXP_FILE_VIEW,
		EXP_FILE_DOWNLOAD,
		EXP_FILE_DOWNLOAD_1,
		EXP_FILE_DOWNLOAD_2,
		EXP_FILE_DOWNLOAD_3,
		EXP_FILE_DOWNLOAD_4,
		EXP_FILE_UPLOAD,
		EXP_FILE_UPLOAD_1,
		EXP_FILE_UPLOAD_2,
		EXP_FILE_UPLOAD_3,
		EXP_FILE_UPLOAD_4,
		EXP_DIR_COPY,
		EXP_DIR_CREATE,
		EXP_DIR_DELETE,
		EXP_DIR_RENAME
		);
	expERR : 	STRUCT 
		text : STRING[150]; (* Error text *)
		no : UINT; (* Error number *)
		state : expSTATE; (* Error step *)
	END_STRUCT;
	expCMD : 	STRUCT 
		refresh : BOOL; (* Read directory and file names from devices *)
		dir_change : BOOL; (* Change current directory *)
		dir_create : BOOL; (* Create a new directory *)
		copy : BOOL; (* Copy selected item from device a TO device b *)
		copy_all : BOOL; (* Copy all items from device a TO device b	*)
		view_file : BOOL;
		delete : BOOL; (* Delete selected file *)
		rename : BOOL;
		download : BOOL;
		upload : BOOL;
	END_STRUCT;
	expPAR : 	STRUCT 
		device_active : STRING[40]; (*Active device name *)
		device_list : ARRAY[0..4]OF STRING[40]; (*List of all devices*)
		item_filter : STRING[EXPL_ITEM_LENGTH]; (*Only show files with this extension	*)
		new_name : STRING[EXPL_ITEM_LENGTH]; (*Name for for directory create and rename*)
		dir_path : STRING[EXPL_DIR_PATH_LENGTH]; (*Current directory path	*)
	END_STRUCT;
	expDAT : 	STRUCT 
		item_list : ARRAY[0..EXPL_LIST_NUM]OF STRING[EXPL_ITEM_LENGTH]; (* List with file names	*)
		item_size : ARRAY[0..EXPL_LIST_NUM]OF STRING[EXPL_SIZE_LENGTH]; (* List with file sizes*)
		item_num : UINT; (* Number OF files	*)
	END_STRUCT;
	expVIS : 	STRUCT 
		item_selected : UINT; (*Current selected file *)
		enable_button_set_1 : BOOL; (*Enable or disable buttons copy and delete*)
		enable_button_set_2 : BOOL; (*Enable or disable buttons refresh and create*)
		view_file_path : STRING[EXPL_DIR_PATH_LENGTH]; (*Full path for viewing file*)
		view_file : BOOL; (*Show message box on error*)
		download_file_url : STRING[200]; (*File upload and download url*)
		reload_upload : BOOL;
		double_click_event : USINT; (*Helper variable for double click in item list*)
		device_list : ARRAY[0..4]OF STRING[80]; (* Device name *)
	END_STRUCT;
	expMAIN : 	STRUCT 
		CMD : ARRAY[0..1]OF expCMD; (* Command structure *)
		PAR : ARRAY[0..1]OF expPAR; (* Parameter structure *)
		DAT : ARRAY[0..1]OF expDAT; (*Data structure*)
		VIS : ARRAY[0..1]OF expVIS; (*Visualization structure*)
		ERR : expERR; (* Error structure *)
		status : STRING[50]; (* Actual step	*)
	END_STRUCT;
END_TYPE
