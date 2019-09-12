
PROGRAM _INIT
	USB.CMD.AutoScan := TRUE;
END_PROGRAM

PROGRAM _CYCLIC

	CASE USB.PAR.state_machine OF
		// -----------------------------------------------------------------------------------------------------------
		// Wait state
		// -----------------------------------------------------------------------------------------------------------
		WAIT:
			// Refresh USB data every X seconds when enabled
			IF USB.CMD.AutoScan = TRUE THEN
				TON_10ms_01(IN:=1, PT:=USB.PAR.refresh_interval);
				// Get new USB data
				IF(TON_10ms_01.Q) THEN
					TON_10ms_01(IN:=0);
					node := 0;
					brsmemset(ADR(usb_data), 0, SIZEOF(usb_data));
					USB.PAR.state_machine := CREATE_NODE_ID_LIST;
				END_IF
			ELSE
				TON_10ms_01(IN:=0);
			END_IF;		
		// -----------------------------------------------------------------------------------------------------------
		// Get USB device list
		// -----------------------------------------------------------------------------------------------------------
		CREATE_NODE_ID_LIST:  
			UsbNodeListGet_0.enable := 1;
			UsbNodeListGet_0.pBuffer := ADR(node_id_buffer);  
			UsbNodeListGet_0.bufferSize := SIZEOF(node_id_buffer);  
			UsbNodeListGet_0.filterInterfaceClass := asusb_CLASS_MASS_STORAGE;  
			UsbNodeListGet_0.filterInterfaceSubClass := 0;  
			UsbNodeListGet_0;
									
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF UsbNodeListGet_0.status = 0 THEN
				USB.PAR.state_machine := READ_DEVICE_DATA;
				// No USB devices found
			ELSIF UsbNodeListGet_0.status = asusbERR_USB_NOTFOUND THEN
				// Unlink old device if it is gone now otherwise wait for next round
				IF(USB.PAR.is_connected) THEN
					USB.PAR.state_machine := UNLINK_DEVICE;
				ELSE
					USB.PAR.state_machine := WAIT;
				END_IF
				// Error
			ELSIF UsbNodeListGet_0.status <> ERR_FUB_BUSY THEN
				USB.PAR.state_machine := ERROR_CASE;
			END_IF;
		// -----------------------------------------------------------------------------------------------------------
		// Get device information
		// -----------------------------------------------------------------------------------------------------------	
		READ_DEVICE_DATA:  				
			UsbNodeGet_0.enable := 1;
			UsbNodeGet_0.nodeId := node_id_buffer[node];  
			UsbNodeGet_0.pBuffer := ADR(usb_data[node]);  
			UsbNodeGet_0.bufferSize := SIZEOF (usb_data[node]);  
			UsbNodeGet_0;
		
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF UsbNodeGet_0.status = 0 THEN
				// Make sure we have enough space to store USB data, proceed with next USB.PAR.state_machine when all devices are detetced
				IF (node = UsbNodeListGet_0.listNodes - 1) OR (node > SIZEOF(usb_data)/SIZEOF(usb_data[0])) THEN
					idx := 0;
					USB.PAR.state_machine := CHECK_DEVICE;
					// Get next USB device
				ELSE
					node := node + 1;
				END_IF;
				// Error
			ELSIF UsbNodeGet_0.status <> ERR_FUB_BUSY THEN
				USB.PAR.state_machine := ERROR_CASE;  (*error occured*)
			END_IF;
		// -----------------------------------------------------------------------------------------------------------
		// Check if device is connected
		// -----------------------------------------------------------------------------------------------------------			
		CHECK_DEVICE:
			// Check if device is already linked
			IF(USB.PAR.is_connected) THEN
				// Device is already linked, return to wait state
				IF(brsmemcmp(ADR(usb_data_linked), ADR(usb_data[idx]), SIZEOF(usb_data[idx])) = 0) THEN
					USB.PAR.state_machine := WAIT;
					// Check next device
				ELSIF(idx < node) THEN
					idx := idx + 1;
					// Unlink device if it is gone
				ELSE
					USB.PAR.state_machine := UNLINK_DEVICE;
				END_IF	
			ELSE
				// Check if B&R dongle should be excluded from list
				IF(USB.PAR.ignore_dongle=TRUE AND usb_data[idx].productId=1001 AND usb_data[idx].vendorId=1615) THEN
					IF(idx < node) THEN
						idx := idx + 1;
					ELSE
						USB.PAR.state_machine := WAIT;						
					END_IF
				ELSE
					USB.PAR.state_machine := LINK_DEVICE;
				END_IF
			END_IF
		// -----------------------------------------------------------------------------------------------------------
		// Link device
		// -----------------------------------------------------------------------------------------------------------			
		LINK_DEVICE:
			// Create device string
			brsstrcpy(ADR(device_param), ADR('/DEVICE='));  		
			brsstrcat(ADR(device_param), ADR(usb_data[node].ifName));  																												
			// Link device
			DevLink_0.enable := 1;
			DevLink_0.pDevice := ADR('USB_DEVICE');  
			DevLink_0.pParam := ADR(device_param);  
			DevLink_0;
		
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF DevLink_0.status = 0 THEN
				brsmemcpy(ADR(usb_data_linked), ADR(usb_data[node]), SIZEOF(usb_data[node]));
				USB.PAR.is_connected := TRUE;
				USB.PAR.state_machine := WAIT;
				// Error
			ELSIF DevLink_0.status <> ERR_FUB_BUSY THEN
				USB.PAR.state_machine := ERROR_CASE;  
			END_IF;										
		// -----------------------------------------------------------------------------------------------------------
		// UnLink device
		// -----------------------------------------------------------------------------------------------------------				
		UNLINK_DEVICE:
			DevUnlink_0.enable := 1;
			DevUnlink_0.handle := DevLink_0.handle;  
			DevUnlink_0;
	
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF DevUnlink_0.status = 0 THEN
				brsmemset(ADR(usb_data_linked), 0, SIZEOF(usb_data_linked));
				USB.PAR.is_connected := FALSE;
				IF(UsbNodeListGet_0.status = asusbERR_USB_NOTFOUND) THEN
					USB.PAR.state_machine := WAIT;
				ELSE
					idx := 0;
					USB.PAR.state_machine := CHECK_DEVICE;
				END_IF
				// Error
			ELSIF DevUnlink_0.status <> ERR_FUB_BUSY THEN
				USB.PAR.state_machine := ERROR_CASE;
			END_IF;
	
		ERROR_CASE:
			// Get more error information
			USB.ERR.no := FileIoGetSysError();

			// Reset error
			IF(USB.CMD.ErrorReset) THEN
				USB.CMD.ErrorReset := FALSE;
				USB.ERR.no := 0;
				brsmemset(ADR(USB.ERR.text), 0, SIZEOF(USB.ERR.text));
				USB.PAR.state_machine := WAIT;
			END_IF
	END_CASE;

END_PROGRAM

PROGRAM _EXIT
	REPEAT
		DevUnlink_0.enable := 1;
		DevUnlink_0.handle := DevLink_0.handle;  
		DevUnlink_0;
		UNTIL DevUnlink_0.status <> ERR_FUB_BUSY
	END_REPEAT;
END_PROGRAM
