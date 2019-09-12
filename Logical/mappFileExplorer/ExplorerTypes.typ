
TYPE
	ClientInfoType : 	STRUCT 
		userId : WSTRING[80];
		isValid : BOOL;
		ipAddress : WSTRING[15];
		languageId : WSTRING[2];
		screenResolution : WSTRING[32];
		slotId : SINT;
	END_STRUCT;
	expERR : 	STRUCT 
		txt : STRING[100]; (* Error text *)
		nr : UINT; (* Error number *)
		step : USINT; (* Error step *)
	END_STRUCT;
	expCMD : 	STRUCT 
		refresh : BOOL; (* Read directory and file names from devices *)
		dir_change : BOOL; (* Change current directory *)
		dir_create : BOOL; (* Create a new directory *)
		copy : BOOL; (* Copy selected item from device a TO device b *)
		copyall : BOOL; (* Copy all items from device a TO device b	*)
		delete : BOOL; (* Delete selected file *)
	END_STRUCT;
	expPAR : 	STRUCT 
		device_active : STRING[40]; (*Active device name *)
		device_list : ARRAY[0..4]OF STRING[40]; (*List of all devices*)
		item_filter : STRING[4]; (* Only show files with this extension	*)
		dir_name : STRING[MAX_ITEM_SIZE]; (* Directory name for create *)
		dir_path : STRING[DIR_PATH_SIZE]; (* Current directory path	*)
	END_STRUCT;
	expDAT : 	STRUCT 
		item_list : ARRAY[0..ITEM_LIST_NUM]OF STRING[MAX_ITEM_SIZE]; (* List with file names	*)
		item_size : ARRAY[0..ITEM_LIST_NUM]OF STRING[15]; (* List with file names *)
		item_num : UINT; (* Number OF files	*)
	END_STRUCT;
	expVIS : 	STRUCT 
		item_selected : UINT; (*Current selected file *)
		enable_copy_delete : BOOL; (*Enable or disable buttons copy and delete*)
		enable_refresh_create : BOOL; (*Enable or disable buttons refresh and create*)
		double_click_dir_change : USINT; (*Helper variable for double click in item list*)
		device_list : ARRAY[0..4]OF STRING[80]; (* Device name *)
	END_STRUCT;
	expMAIN : 	STRUCT 
		CMD : ARRAY[0..1]OF expCMD; (* Command structure *)
		PAR : ARRAY[0..1]OF expPAR; (* Parameter structure *)
		DAT : ARRAY[0..1]OF expDAT;
		VIS : ARRAY[0..1]OF expVIS;
		ERR : expERR; (* Error structure *)
		status : STRING[50]; (* Actual step	*)
	END_STRUCT;
	netCMD : 	STRUCT 
		Connect : BOOL := TRUE; (*Connect to network share*)
		ErrorReset : BOOL; (*Reset error*)
	END_STRUCT;
	netPAR : 	STRUCT 
		state_machine : USINT; (*State machine*)
		server_name : STRING[80]; (*Use server name*)
		server_ip : STRING[80] := '192.168.0.10'; (*or IP address*)
		server_port : STRING[80]; (*Uses default port when empty*)
		server_protocol : STRING[80] := 'ftp'; (*Type of network connection*)
		server_domain : STRING[80]; (*Domain name*)
		server_share : STRING[80] := 'share'; (*Name of the shared folder*)
		user_name : STRING[80] := 'user'; (*User name*)
		user_password : STRING[80] := 'password'; (*User password*)
		enable_connect : BOOL; (*Enable button connect*)
		is_linked : BOOL; (*Network share is connected*)
	END_STRUCT;
	netERR : 	STRUCT 
		no : UINT; (*Error number*)
		text : STRING[80]; (*Error text*)
	END_STRUCT;
	netMAIN : 	STRUCT 
		CMD : netCMD; (*Command structure*)
		PAR : netPAR; (*Parameter structure*)
		ERR : netERR; (*Error structure*)
	END_STRUCT;
	usbCMD : 	STRUCT 
		AutoScan : BOOL := TRUE; (*Scan USB ports automatically*)
		ErrorReset : BOOL; (*Reset error*)
	END_STRUCT;
	usbPAR : 	STRUCT 
		state_machine : USINT; (*State machine*)
		ignore_dongle : BOOL := TRUE; (*Ignoe B&R license dongle*)
		refresh_interval : UINT := 300; (*Intervall timer for USB device refresh*)
		is_connected : BOOL; (*Shows if a USB stick is connected*)
	END_STRUCT;
	usbERR : 	STRUCT 
		no : UINT; (*Error number*)
		text : STRING[80]; (*Error text*)
	END_STRUCT;
	usbMAIN : 	STRUCT 
		CMD : usbCMD; (*Command structure*)
		PAR : usbPAR; (*Parameter structure*)
		ERR : usbERR; (*Error structure*)
	END_STRUCT;
END_TYPE
