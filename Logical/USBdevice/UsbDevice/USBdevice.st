PROGRAM _INIT
END_PROGRAM

PROGRAM _CYCLIC

	CASE state_machine OF
		// -----------------------------------------------------------------------------------------------------------
		// Wait state
		// -----------------------------------------------------------------------------------------------------------
		USB_WAIT:
			// Refresh USB data every X seconds when enabled
			node := 1;
			USB.status := ERR_OK;
			IF USB.CMD.auto_scan = TRUE THEN
				TON_10ms_01(IN:=1, PT:=USB.PAR.refresh_interval);
				// Get new USB data
				IF(TON_10ms_01.Q) THEN
					TON_10ms_01(IN:=0);
					USB.status := ERR_FUB_BUSY;
					brsmemset(ADR(usb_data), 0, SIZEOF(usb_data));
					state_machine := USB_CREATE_NODE_ID_LIST;
				END_IF
			ELSE
				TON_10ms_01(IN:=0);
			END_IF
			// Refresh USB data every X seconds when enabled
			IF USB.CMD.error_reset = TRUE THEN
				state_machine := USB_ERROR;				
			END_IF
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
				state_machine := USB_READ_DEVICE_DATA;
				node := 1;
				// No USB devices found
			ELSIF UsbNodeListGet_0.status = asusbERR_USB_NOTFOUND THEN
				// Unlink old device if it is gone now otherwise wait for next round
				FOR idx:=1 TO USB_MAX_CNT DO
					IF(USB.PAR.is_connected[idx] = TRUE) THEN
						node := 1;
						state_machine := USB_CHECK_LINKED;
						RETURN;
					END_IF
				END_FOR;
				state_machine := USB_WAIT;
				// Error
			ELSIF UsbNodeListGet_0.status <> ERR_FUB_BUSY THEN
				USB.status := UsbNodeListGet_0.status;
				USB.ERR.state := state_machine;
				IF UsbNodeListGet_0.status = asusbERR_BUFSIZE THEN
					USB.ERR.text := 'maximum number of devices reached';
				ELSE
					USB.ERR.text := 'error getting device list';
				END_IF;
				state_machine := USB_ERROR;
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
				// Make sure we have enough space to store USB data, proceed with next state_machine when all devices are detetced
				IF (node = UsbNodeListGet_0.listNodes) OR (node = USB_MAX_CNT) THEN
					node := 1;
					state_machine := USB_CHECK_LINKED;
					// Get next USB device
				ELSE
					node := node + 1;
				END_IF;
				// Error
			ELSIF UsbNodeGet_0.status <> ERR_FUB_BUSY THEN
				USB.status := UsbNodeGet_0.status;
				USB.ERR.state := state_machine;
				USB.ERR.text := 'error getting device data';
				state_machine := USB_ERROR;
			END_IF;
			// -----------------------------------------------------------------------------------------------------------
			// Check if linked device are still present
			// -----------------------------------------------------------------------------------------------------------			
		USB_CHECK_LINKED:
			// Proceed to new devices when last device was checked
			IF(node > USB_MAX_CNT) THEN
				node := 1;
				state_machine := USB_LINK_NEW;
				RETURN;
			END_IF	 
			
			// -----------------------------------------------------------------------------------------------------------
			// Check if device is still active
			is_linked := FALSE;
			FOR idx:=1 TO USB_MAX_CNT DO
				// Compare old and new data
				IF(brsmemcmp(ADR(usb_data_old[node]), ADR(usb_data[idx]), SIZEOF(usb_data[idx])) = 0) AND 
					(USB.PAR.ignore_dongle = FALSE OR (USB.PAR.ignore_dongle = TRUE AND usb_data[idx].productId <> BRproductId AND usb_data[idx].vendorId <> BRvendorId)) THEN
					// Clear data, mark as linked and EXIT loop
					brsmemset(ADR(usb_data[idx]), 0, SIZEOF(usb_data[idx]));
					is_linked := TRUE;
					EXIT;
				END_IF
			END_FOR;

			// -----------------------------------------------------------------------------------------------------------
			// Find next linked device
			IF(is_linked OR usb_data_old[node].interfaceClass = 0) THEN
				IF(node < USB_MAX_CNT) THEN
					node := node + 1;
					WHILE(node < USB_MAX_CNT AND usb_data_old[node].interfaceClass = 0) DO
						node := node + 1;
					END_WHILE;
					IF(node = USB_MAX_CNT AND usb_data_old[node].interfaceClass = 0) THEN
						node := node + 1;
					END_IF
				ELSE
					node := node + 1;
				END_IF
				// Unlink device if it is missing
			ELSE
				state_machine := USB_UNLINK_DEVICE;
			END_IF
			// -----------------------------------------------------------------------------------------------------------
			// Link new devices
			// -----------------------------------------------------------------------------------------------------------			
		USB_LINK_NEW:
			// Return to wait state when last device was checked
			IF(node > USB_MAX_CNT) THEN
				state_machine := USB_WAIT;
				RETURN;
			END_IF	 
			
			// -----------------------------------------------------------------------------------------------------------
			// Find next new device
			IF(usb_data[node].interfaceClass <> 0) THEN
				IF(USB.PAR.ignore_dongle = FALSE OR (usb_data[node].productId <> BRproductId AND usb_data[node].vendorId <> BRvendorId)) THEN
					state_machine := USB_LINK_DEVICE;
					RETURN;
				END_IF
			END_IF
			node := node + 1;
			// -----------------------------------------------------------------------------------------------------------
			// Link device
			// -----------------------------------------------------------------------------------------------------------			
		USB_LINK_DEVICE:
			// Find empty slot
			FOR idx:=1 TO USB_MAX_CNT DO
				IF(usb_data_old[idx].interfaceClass = 0) THEN
					EXIT;
				END_IF
			END_FOR;
			// No more slot available
			IF(idx = USB_MAX_CNT AND usb_data_old[idx].interfaceClass <> 0) THEN
				USB.status := ERR_MAX_DEVICE;
				USB.ERR.state := state_machine;
				USB.ERR.text := 'maximum number of device reached';
				state_machine := USB_ERROR;
				RETURN;
			END_IF
			// Create device string
			brsstrcpy(ADR(device_param), ADR('/DEVICE='));  		
			brsstrcat(ADR(device_param), ADR(usb_data[node].ifName));
			brsstrcpy(ADR(device_name), ADR('USB_DEVICE'));
			brsitoa(idx, ADR(tmpSTR));
			brsstrcat(ADR(device_name), ADR(tmpSTR));
			// Link device
			DevLink_0.enable := 1;
			DevLink_0.pDevice := ADR(device_name);  
			DevLink_0.pParam := ADR(device_param);  
			DevLink_0;
		
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF DevLink_0.status = 0 THEN
				// Store data for new device
				brsmemcpy(ADR(usb_data_old[idx]), ADR(usb_data[node]), SIZEOF(usb_data[node]));
				USB.PAR.is_connected[idx] := TRUE;
				link_handle[idx] := DevLink_0.handle;
				node := node + 1; 				
				state_machine := USB_LINK_NEW;
				// Error
			ELSIF DevLink_0.status <> ERR_FUB_BUSY THEN
				USB.status := DevLink_0.status;
				USB.ERR.state := state_machine;
				USB.ERR.text := 'error linking device';
				state_machine := USB_ERROR;  
			END_IF;										
			// -----------------------------------------------------------------------------------------------------------
			// UnLink device
			// -----------------------------------------------------------------------------------------------------------				
		USB_UNLINK_DEVICE:
			DevUnlink_0.enable := 1;
			DevUnlink_0.handle := link_handle[node];  
			DevUnlink_0;
	
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF DevUnlink_0.status = 0 THEN
				// Clear data 		
				brsmemset(ADR(usb_data_old[node]), 0, SIZEOF(usb_data_old[node]));
				USB.PAR.is_connected[node] := FALSE;
				link_handle[node] := 0;
				// Find next linked device
				WHILE(node < USB_MAX_CNT AND usb_data_old[node].interfaceClass = 0) DO
					node := node + 1;
				END_WHILE;
				IF(node = USB_MAX_CNT AND usb_data_old[node].interfaceClass = 0) THEN
					node := node + 1;
				END_IF
				state_machine := USB_CHECK_LINKED;
				// Error
			ELSIF DevUnlink_0.status <> ERR_FUB_BUSY THEN
				// Clear data 		
				brsmemset(ADR(usb_data_old[node]), 0, SIZEOF(usb_data_old[node]));
				USB.PAR.is_connected[node] := FALSE;
				link_handle[node] := 0;
				
				brsitoa(node, ADR(tmpSTR));
				USB.status := DevUnlink_0.status;
				USB.ERR.state := state_machine;
				USB.ERR.text := 'error unlinking device no ';
				brsstrcat(ADR(USB.ERR.text), ADR(tmpSTR));
				state_machine := USB_ERROR;
			END_IF;
			// -----------------------------------------------------------------------------------------------------------
			// Error state
			// -----------------------------------------------------------------------------------------------------------					
		USB_ERROR:
			// Get more error information
			IF(USB.status = 0) THEN
				USB.status := FileIoGetSysError();
			END_IF
			
			// Unlink device
			IF(USB.ERR.state = USB_LINK_DEVICE) THEN
				DevUnlink_0.enable := 1;
				DevUnlink_0.handle := DevLink_0.handle;  
				DevUnlink_0;
			END_IF

			// Reset error
			IF(USB.CMD.error_reset AND DevUnlink_0.status <> ERR_FUB_BUSY) THEN		
				USB.CMD.error_reset := FALSE;
				brsmemset(ADR(USB.ERR), 0, SIZEOF(USB.ERR));
				state_machine := USB_WAIT;
			END_IF
	END_CASE;

END_PROGRAM

PROGRAM _EXIT
	FOR idx:=1 TO USB_MAX_CNT DO
		REPEAT
			DevUnlink_0.enable := 1;
			DevUnlink_0.handle := link_handle[idx];;  
			DevUnlink_0;
			UNTIL DevUnlink_0.status <> ERR_FUB_BUSY
		END_REPEAT;
	END_FOR;
END_PROGRAM
