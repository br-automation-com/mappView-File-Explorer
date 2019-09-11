
PROGRAM _INIT
	(* Insert code here *)
	 
END_PROGRAM

PROGRAM _CYCLIC

	CASE step OF
		// -----------------------------------------------------------------------------------------------------------
		// Wait state
		// -----------------------------------------------------------------------------------------------------------
		WAIT:
			vis_enable_connect := TRUE;
			// --------------------------------------------------------------------------------------------------------------------	
			// Connect to server
			IF(cmdConnectToServer) THEN
				IF(NET_is_linked) THEN
					DevUnlink_0.enable := 0;
					DevUnlink_0;
					step := UNLINK_DEVICE;
				ELSE
					DevLink_0.enable := 0;
					DevLink_0;
					step := LINK_DEVICE;
				END_IF
			END_IF
			// --------------------------------------------------------------------------------------------------------------------	
			// Disconnect from server
			IF(cmdReset) THEN
				IF(NET_is_linked) THEN
					DevUnlink_0.enable := 0;
					DevUnlink_0;
					step := UNLINK_DEVICE;
				ELSE
					cmdReset := FALSE;
				END_IF
			END_IF
			// -----------------------------------------------------------------------------------------------------------
		// Link device
		// -----------------------------------------------------------------------------------------------------------			
		LINK_DEVICE:
			// Create device string
			vis_enable_connect := FALSE;
			brsmemset(ADR(device_param), 0, SIZEOF(device_param));
			IF(brsstrcmp(ADR(NET_server_name), ADR('')) <> 0) THEN
				brsstrcat(ADR(device_param), ADR('/SNAME='));  		
				brsstrcat(ADR(device_param), ADR(NET_server_name));  																												
				brsstrcat(ADR(device_param), ADR(' '));  		
			END_IF
			IF(brsstrcmp(ADR(NET_server_ip), ADR('')) <> 0) THEN
				brsstrcat(ADR(device_param), ADR('/SIP='));  		
				brsstrcat(ADR(device_param), ADR(NET_server_ip));  																												
				brsstrcat(ADR(device_param), ADR(' '));  		
			END_IF
			IF(brsstrcmp(ADR(NET_server_protocol), ADR('')) <> 0) THEN
				brsstrcat(ADR(device_param), ADR('/PROTOCOL='));  		
				brsstrcat(ADR(device_param), ADR(NET_server_protocol));  																												
				brsstrcat(ADR(device_param), ADR(' '));  		
			END_IF
			IF(brsstrcmp(ADR(NET_server_port), ADR('')) <> 0) THEN
				brsstrcat(ADR(device_param), ADR('/PORT='));  		
				brsstrcat(ADR(device_param), ADR(NET_server_port));  																												
				brsstrcat(ADR(device_param), ADR(' '));  		
			END_IF
			IF(brsstrcmp(ADR(NET_server_domain), ADR('')) <> 0) THEN
				brsstrcat(ADR(device_param), ADR('/DOMAIN='));  		
				brsstrcat(ADR(device_param), ADR(NET_server_domain));  																												
				brsstrcat(ADR(device_param), ADR(' '));  		
			END_IF
			IF(brsstrcmp(ADR(NET_server_share), ADR('')) <> 0) THEN
				brsstrcat(ADR(device_param), ADR('/SHARE='));  		
				brsstrcat(ADR(device_param), ADR(NET_server_share));  																												
				brsstrcat(ADR(device_param), ADR(' '));  		
			END_IF
			IF(brsstrcmp(ADR(NET_user_name), ADR('')) <> 0) THEN
				brsstrcat(ADR(device_param), ADR('/USER='));  		
				brsstrcat(ADR(device_param), ADR(NET_user_name));  																												
				brsstrcat(ADR(device_param), ADR(' '));  		
			END_IF
			IF(brsstrcmp(ADR(NET_user_password), ADR('')) <> 0) THEN
				brsstrcat(ADR(device_param), ADR('/PASSWORD='));  		
				brsstrcat(ADR(device_param), ADR(NET_user_password));  																												
				brsstrcat(ADR(device_param), ADR(' '));  		
			END_IF

			// Link device
			DevLink_0.enable := 1;
			DevLink_0.pDevice := ADR('NET_DEVICE');  
			DevLink_0.pParam := ADR(device_param);  
			DevLink_0;
		
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF DevLink_0.status = 0 THEN
				NET_is_linked := TRUE;
				cmdConnectToServer := FALSE;				
				step := WAIT;
			// --------------------------------------------------------------------------------------------------------------------	
			// Abort command
			ELSIF(cmdReset) THEN
				cmdReset := FALSE;
				cmdConnectToServer := FALSE;
				step := WAIT;
				// Error
			ELSIF DevLink_0.status <> ERR_FUB_BUSY THEN
				step := ERROR_CASE;  
			END_IF;										
		// -----------------------------------------------------------------------------------------------------------
		// UnLink device
		// -----------------------------------------------------------------------------------------------------------				
		UNLINK_DEVICE:
			vis_enable_connect := FALSE;
			DevUnlink_0.enable := 1;
			DevUnlink_0.handle := DevLink_0.handle;  
			DevUnlink_0;
	
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF DevUnlink_0.status = 0 THEN
				NET_is_linked := FALSE;
				IF(cmdConnectToServer) THEN
					DevLink_0.enable := 0;
					DevLink_0;
					step := LINK_DEVICE;
				ELSE
					cmdReset := FALSE;
					step := WAIT;
				END_IF					
			// Error
			ELSIF DevUnlink_0.status <> ERR_FUB_BUSY THEN
				cmdReset := FALSE;
				step := ERROR_CASE;
			END_IF;
		ERROR_CASE:
			// Reset commands
			vis_enable_connect := FALSE;
			cmdConnectToServer := FALSE;

			// Get more error information
			error_code := FileIoGetSysError();
			IF(error_code=26228) THEN
				brsstrcpy(ADR(error_text), ADR('connection rejected: check network protocol, username and password'));
			ELSIF(DevLink_0.status = fiERR_DEVICE_ALREADY_EXIST) THEN
				brsstrcpy(ADR(error_text), ADR('device is already connected'));
			END_IF
			
			// Reset error
			IF(cmdReset) THEN
				cmdReset := FALSE;
				error_code := 0;
				brsmemset(ADR(error_text), 0, SIZEOF(error_text));
				step := WAIT;
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

