
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
		EXP_DIR_COPY,
		EXP_DIR_CREATE,
		EXP_DIR_DELETE,
		EXP_DIR_RENAME
		);
	expERR : 	STRUCT 
		text : STRING[100]; (* Error text *)
		no : UINT; (* Error number *)
		state : expSTATE; (* Error step *)
	END_STRUCT;
	expCMD : 	STRUCT 
		refresh : BOOL; (* Read directory and file names from devices *)
		dir_change : BOOL; (* Change current directory *)
		dir_create : BOOL; (* Create a new directory *)
		copy : BOOL; (* Copy selected item from device a TO device b *)
		copy_all : BOOL; (* Copy all items from device a TO device b	*)
		delete : BOOL; (* Delete selected file *)
		rename : BOOL;
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
		enable_copy_delete : BOOL; (*Enable or disable buttons copy and delete*)
		enable_refresh_create : BOOL; (*Enable or disable buttons refresh and create*)
		double_click_dir_change : USINT; (*Helper variable for double click in item list*)
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
	netSTATE : 
		(
		NET_WAIT, (*Function step: Wait for starting the Function chain*)
		NET_LINK_DEVICE, (*Function step: Link file device*)
		NET_UNLINK_DEVICE, (*Function step: Unlink the File Device from specific path*)
		NET_ERROR (*Function step: Jump to this step in every case of Error occuring in the Function chain*)
		);
	netCMD : 	STRUCT 
		connect : BOOL := TRUE; (*Connect to network share*)
		error_reset : BOOL; (*Reset error*)
	END_STRUCT;
	netPAR : 	STRUCT 
		state_machine : netSTATE; (*State machine*)
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
		state : netSTATE;
		text : STRING[80]; (*Error text*)
		active : BOOL;
	END_STRUCT;
	netMAIN : 	STRUCT 
		CMD : netCMD; (*Command structure*)
		PAR : netPAR; (*Parameter structure*)
		ERR : netERR; (*Error structure*)
	END_STRUCT;
	usbSTATE : 
		(
		USB_WAIT, (*Wait for starting the Function chain*)
		USB_CREATE_NODE_ID_LIST, (*Create a list of Node-IDs from all active USB devices*)
		USB_READ_DEVICE_DATA, (*Read out the specific data from the Node-IDs*)
		USB_CHECK_DEVICE, (*Check file device data*)
		USB_LINK_DEVICE, (*Link file device*)
		USB_UNLINK_DEVICE, (*Unlink the File Device from specific path*)
		USB_ERROR (*Jump to this step in every case of Error occuring in the Function chain*)
		);
	usbCMD : 	STRUCT 
		auto_scan : BOOL := TRUE; (*Scan USB ports automatically*)
		error_reset : BOOL; (*Reset error*)
	END_STRUCT;
	usbPAR : 	STRUCT 
		state_machine : usbSTATE; (*State machine*)
		ignore_dongle : BOOL := TRUE; (*Ignoe B&R license dongle*)
		refresh_interval : UINT := 300; (*Intervall timer for USB device refresh*)
		is_connected : BOOL; (*Shows if a USB stick is connected*)
	END_STRUCT;
	usbERR : 	STRUCT 
		no : UINT; (*Error number*)
		state : usbSTATE;
		text : STRING[80]; (*Error text*)
		active : BOOL;
	END_STRUCT;
	usbMAIN : 	STRUCT 
		CMD : usbCMD; (*Command structure*)
		PAR : usbPAR; (*Parameter structure*)
		ERR : usbERR; (*Error structure*)
	END_STRUCT;
END_TYPE
