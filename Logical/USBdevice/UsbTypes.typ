
TYPE
	usbSTATE : 
		(
		USB_WAIT, (*Wait for starting the Function chain*)
		USB_CREATE_NODE_ID_LIST, (*Create a list of Node-IDs from all active USB devices*)
		USB_READ_DEVICE_DATA, (*Read out the specific data from the Node-IDs*)
		USB_CHECK_LINKED, (*Check if device is still connected*)
		USB_LINK_NEW,
		USB_LINK_DEVICE, (*Link file device*)
		USB_UNLINK_DEVICE, (*Unlink the File Device from specific path*)
		USB_ERROR (*Jump to this step in every case of Error occuring in the Function chain*)
		);
	usbCMD : 	STRUCT 
		auto_scan : BOOL := TRUE; (*Scan USB ports automatically*)
		error_reset : BOOL; (*Reset error*)
	END_STRUCT;
	usbPAR : 	STRUCT 
		ignore_dongle : BOOL := TRUE; (*Ignoe B&R license dongle*)
		refresh_interval : UINT := 300; (*Intervall timer for USB device refresh*)
		is_connected : ARRAY[1..USB_MAX_CNT]OF BOOL; (*Shows if a USB stick is connected*)
	END_STRUCT;
	usbERR : 	STRUCT 
		state : usbSTATE; (*State where the error occured*)
		text : STRING[80]; (*Error text*)
	END_STRUCT;
	usbMAIN : 	STRUCT 
		CMD : usbCMD; (*Command structure*)
		PAR : usbPAR; (*Parameter structure*)
		ERR : usbERR; (*Error structure*)
		status : UINT; (*Current status*)
	END_STRUCT;
END_TYPE
