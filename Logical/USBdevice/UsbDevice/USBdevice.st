PROGRAM _INIT
END_PROGRAM

PROGRAM _CYCLIC

	CASE USB.PAR.state_machine OF
		// -----------------------------------------------------------------------------------------------------------
		// Wait state
		// -----------------------------------------------------------------------------------------------------------
		USB_WAIT:
			// Refresh USB data every X seconds when enabled
			IF USB.CMD.auto_scan = TRUE THEN
				TON_10ms_01(IN:=1, PT:=USB.PAR.refresh_interval);
				// Get new USB data
				IF(TON_10ms_01.Q) THEN
					TON_10ms_01(IN:=0);
					node := 0;
					brsmemset(ADR(usb_data), 0, SIZEOF(usb_data));
					USB.PAR.state_machine := USB_CREATE_NODE_ID_LIST;
				END_IF
			ELSE
				TON_10ms_01(IN:=0);
			END_IF;		
			// Refresh USB data every X seconds when enabled
			IF USB.CMD.error_reset = TRUE THEN
				USB.PAR.state_machine := USB_ERROR;				
			END_IF;		
		// -----------------------------------------------------------------------------------------------------------
		// Get USB device list
		// -----------------------------------------------------------------------------------------------------------
		USB_CREATE_NODE_ID_LIST:  
			UsbNodeListGet_0.enable := 1;
			UsbNodeListGet_0.pBuffer := ADR(node_id_buffer);  
			UsbNodeListGet_0.bufferSize := SIZEOF(node_id_buffer);  
			UsbNodeListGet_0.filterInterfaceClass := asusb_CLASS_MASS_STORAGE;  
			UsbNodeListGet_0.filterInterfaceSubClass := 0;  
			UsbNodeListGet_0;
									
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF UsbNodeListGet_0.status = 0 THEN
				USB.PAR.state_machine := USB_READ_DEVICE_DATA;
				// No USB devices found
			ELSIF UsbNodeListGet_0.status = asusbERR_USB_NOTFOUND THEN
				// Unlink old device if it is gone now otherwise wait for next round
				IF(USB.PAR.is_connected) THEN
					USB.PAR.state_machine := USB_UNLINK_DEVICE;
				ELSE
					USB.PAR.state_machine := USB_WAIT;
				END_IF
				// Error
			ELSIF UsbNodeListGet_0.status <> ERR_FUB_BUSY THEN
				USB.ERR.state := USB.PAR.state_machine;
				USB.ERR.no := UsbNodeListGet_0.status;
				USB.ERR.text := 'error getting device list';
				USB.PAR.state_machine := USB_ERROR;
			END_IF;
		// -----------------------------------------------------------------------------------------------------------
		// Get device information
		// -----------------------------------------------------------------------------------------------------------	
		USB_READ_DEVICE_DATA:  				
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
					USB.PAR.state_machine := USB_CHECK_DEVICE;
					// Get next USB device
				ELSE
					node := node + 1;
				END_IF;
				// Error
			ELSIF UsbNodeGet_0.status <> ERR_FUB_BUSY THEN
				USB.ERR.state := USB.PAR.state_machine;
				USB.ERR.no := UsbNodeGet_0.status;
				USB.ERR.text := 'error getting device data';
				USB.PAR.state_machine := USB_ERROR;
			END_IF;
		// -----------------------------------------------------------------------------------------------------------
		// Check if device is connected
		// -----------------------------------------------------------------------------------------------------------			
		USB_CHECK_DEVICE:
			// Check if device is already linked
			IF(USB.PAR.is_connected) THEN
				// Device is already linked, return to wait state
				IF(brsmemcmp(ADR(usb_data_linked), ADR(usb_data[idx]), SIZEOF(usb_data[idx])) = 0) THEN
					USB.PAR.state_machine := USB_WAIT;
					// Check next device
				ELSIF(idx < node) THEN
					idx := idx + 1;
					// Unlink device if it is gone
				ELSE
					USB.PAR.state_machine := USB_UNLINK_DEVICE;
				END_IF	
			ELSE
				// Check if B&R dongle should be excluded from list
				IF(USB.PAR.ignore_dongle=TRUE AND usb_data[idx].productId=1001 AND usb_data[idx].vendorId=1615) THEN
					IF(idx < node) THEN
						idx := idx + 1;
					ELSE
						USB.PAR.state_machine := USB_WAIT;
					END_IF
				ELSE
					USB.PAR.state_machine := USB_LINK_DEVICE;
				END_IF
			END_IF
		// -----------------------------------------------------------------------------------------------------------
		// Link device
		// -----------------------------------------------------------------------------------------------------------			
		USB_LINK_DEVICE:
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
				USB.PAR.state_machine := USB_WAIT;
				// Error
			ELSIF DevLink_0.status <> ERR_FUB_BUSY THEN
				USB.ERR.state := USB.PAR.state_machine;
				USB.ERR.no := DevLink_0.status;
				USB.ERR.text := 'error linking device';
				USB.PAR.state_machine := USB_ERROR;  
			END_IF;										
		// -----------------------------------------------------------------------------------------------------------
		// UnLink device
		// -----------------------------------------------------------------------------------------------------------				
		USB_UNLINK_DEVICE:
			DevUnlink_0.enable := 1;
			DevUnlink_0.handle := DevLink_0.handle;  
			DevUnlink_0;
	
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF DevUnlink_0.status = 0 THEN
				brsmemset(ADR(usb_data_linked), 0, SIZEOF(usb_data_linked));
				USB.PAR.is_connected := FALSE;
				IF(UsbNodeListGet_0.status = asusbERR_USB_NOTFOUND) THEN
					USB.PAR.state_machine := USB_WAIT;
				ELSE
					idx := 0;
					USB.PAR.state_machine := USB_CHECK_DEVICE;
				END_IF
				// Error
			ELSIF DevUnlink_0.status <> ERR_FUB_BUSY THEN
				USB.ERR.state := USB.PAR.state_machine;
				USB.ERR.no := DevUnlink_0.status;
				USB.ERR.text := 'error unlinking device';
				USB.PAR.state_machine := USB_ERROR;
			END_IF;
		// -----------------------------------------------------------------------------------------------------------
		// Error state
		// -----------------------------------------------------------------------------------------------------------					
		USB_ERROR:
			// Get more error information
			IF(USB.ERR.no = 0) THEN
				USB.ERR.no := FileIoGetSysError();
			END_IF
			USB.ERR.active := TRUE;
			USB.PAR.is_connected := FALSE;
			
			// Unlink device
			DevUnlink_0.enable := 1;
			DevUnlink_0.handle := DevLink_0.handle;  
			DevUnlink_0;

			// Reset error
			IF(USB.CMD.error_reset AND DevUnlink_0.status <> ERR_FUB_BUSY) THEN
				USB.CMD.error_reset := FALSE;
				USB.ERR.active := FALSE;
				USB.ERR.no := 0;
				brsmemset(ADR(USB.ERR.text), 0, SIZEOF(USB.ERR.text));
				USB.PAR.state_machine := USB_WAIT;
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
