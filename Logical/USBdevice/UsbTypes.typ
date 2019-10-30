
TYPE
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
