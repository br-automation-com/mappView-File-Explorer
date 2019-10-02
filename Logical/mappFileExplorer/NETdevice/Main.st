
PROGRAM _INIT
	(* Insert code here *)
	 
END_PROGRAM

PROGRAM _CYCLIC

	CASE NET.PAR.state_machine OF
		// -----------------------------------------------------------------------------------------------------------
		// Wait state
		// -----------------------------------------------------------------------------------------------------------
		NET_WAIT:
			NET.PAR.enable_connect := TRUE;
			// --------------------------------------------------------------------------------------------------------------------	
			// Connect to server
			IF(NET.CMD.connect) THEN
				IF(NET.PAR.is_linked) THEN
					DevUnlink_0.enable := 0;
					DevUnlink_0;
					IF (DevUnlink_0.status = ERR_FUB_ENABLE_FALSE) THEN
						NET.PAR.state_machine := NET_UNLINK_DEVICE;
					END_IF
				ELSE
					DevLink_0.enable := 0;
					DevLink_0;
					IF (DevLink_0.status = ERR_FUB_ENABLE_FALSE) THEN
						NET.PAR.state_machine := NET_LINK_DEVICE;
					END_IF
				END_IF
			END_IF
			// --------------------------------------------------------------------------------------------------------------------	
			// Disconnect from server
			IF(NET.CMD.error_reset) THEN
				IF(NET.PAR.is_linked) THEN
					DevUnlink_0.enable := 0;
					DevUnlink_0;
					NET.PAR.state_machine := NET_UNLINK_DEVICE;
				ELSE
					NET.CMD.error_reset := FALSE;
				END_IF
			END_IF
		// -----------------------------------------------------------------------------------------------------------
		// Link device
		// -----------------------------------------------------------------------------------------------------------			
		NET_LINK_DEVICE:
			// Create device string
			NET.PAR.enable_connect := FALSE;
			brsmemset(ADR(device_param), 0, SIZEOF(device_param));
			IF(brsstrcmp(ADR(NET.PAR.server_name), ADR('')) <> 0) THEN
				brsstrcat(ADR(device_param), ADR('/SNAME='));  		
				brsstrcat(ADR(device_param), ADR(NET.PAR.server_name));  																												
				brsstrcat(ADR(device_param), ADR(' '));  		
			END_IF
			IF(brsstrcmp(ADR(NET.PAR.server_ip), ADR('')) <> 0) THEN
				brsstrcat(ADR(device_param), ADR('/SIP='));  		
				brsstrcat(ADR(device_param), ADR(NET.PAR.server_ip));  																												
				brsstrcat(ADR(device_param), ADR(' '));  		
			END_IF
			IF(brsstrcmp(ADR(NET.PAR.server_protocol), ADR('')) <> 0) THEN
				brsstrcat(ADR(device_param), ADR('/PROTOCOL='));  		
				brsstrcat(ADR(device_param), ADR(NET.PAR.server_protocol));  																												
				brsstrcat(ADR(device_param), ADR(' '));  		
			END_IF
			IF(brsstrcmp(ADR(NET.PAR.server_port), ADR('')) <> 0) THEN
				brsstrcat(ADR(device_param), ADR('/PORT='));  		
				brsstrcat(ADR(device_param), ADR(NET.PAR.server_port));  																												
				brsstrcat(ADR(device_param), ADR(' '));  		
			END_IF
			IF(brsstrcmp(ADR(NET.PAR.server_domain), ADR('')) <> 0) THEN
				brsstrcat(ADR(device_param), ADR('/DOMAIN='));  		
				brsstrcat(ADR(device_param), ADR(NET.PAR.server_domain));  																												
				brsstrcat(ADR(device_param), ADR(' '));  		
			END_IF
			IF(brsstrcmp(ADR(NET.PAR.server_share), ADR('')) <> 0) THEN
				brsstrcat(ADR(device_param), ADR('/SHARE='));  		
				brsstrcat(ADR(device_param), ADR(NET.PAR.server_share));  																												
				brsstrcat(ADR(device_param), ADR(' '));  		
			END_IF
			IF(brsstrcmp(ADR(NET.PAR.user_name), ADR('')) <> 0) THEN
				brsstrcat(ADR(device_param), ADR('/USER='));  		
				brsstrcat(ADR(device_param), ADR(NET.PAR.user_name));  																												
				brsstrcat(ADR(device_param), ADR(' '));  		
			END_IF
			IF(brsstrcmp(ADR(NET.PAR.user_password), ADR('')) <> 0) THEN
				brsstrcat(ADR(device_param), ADR('/PASSWORD='));  		
				brsstrcat(ADR(device_param), ADR(NET.PAR.user_password));  																												
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
				device_handle := DevLink_0.handle;
				NET.PAR.is_linked := TRUE;
				NET.CMD.connect := FALSE;				
				NET.PAR.state_machine := NET_WAIT;
			// --------------------------------------------------------------------------------------------------------------------	
			// Abort command
			ELSIF(NET.CMD.error_reset) THEN
				NET.CMD.error_reset := FALSE;
				NET.CMD.connect := FALSE;
				NET.PAR.state_machine := NET_WAIT;
				// Error
			ELSIF DevLink_0.status <> ERR_FUB_BUSY THEN
				NET.ERR.state := NET.PAR.state_machine;
				NET.ERR.no := DevLink_0.status;
				NET.ERR.text := 'error linking device';
				NET.PAR.state_machine := NET_ERROR;  
			END_IF;										
		// -----------------------------------------------------------------------------------------------------------
		// UnLink device
		// -----------------------------------------------------------------------------------------------------------				
		NET_UNLINK_DEVICE:
			NET.PAR.enable_connect := FALSE;
			DevUnlink_0.enable := 1;
			DevUnlink_0.handle := device_handle;  
			DevUnlink_0;
	
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF DevUnlink_0.status = 0 THEN
				NET.PAR.is_linked := FALSE;
				IF(NET.CMD.connect) THEN
					DevLink_0.enable := 0;
					DevLink_0;
					NET.PAR.state_machine := NET_LINK_DEVICE;
				ELSE
					NET.CMD.error_reset := FALSE;
					NET.PAR.state_machine := NET_WAIT;
				END_IF					
			// Error
			ELSIF DevUnlink_0.status <> ERR_FUB_BUSY THEN
				NET.CMD.error_reset := FALSE;
				NET.ERR.state := NET.PAR.state_machine;
				NET.ERR.no := DevUnlink_0.status;
				NET.ERR.text := 'error unlinking device';
				NET.PAR.state_machine := NET_ERROR;
			END_IF;
		// -----------------------------------------------------------------------------------------------------------
		// Error step
		// -----------------------------------------------------------------------------------------------------------				
		NET_ERROR:
			// Reset commands
			NET.PAR.enable_connect := FALSE;
			NET.CMD.connect := FALSE;

			// Get more error information
			IF(NET.ERR.no = 0) THEN
				NET.ERR.no := FileIoGetSysError();
			END_IF
			NET.ERR.active := TRUE;
			IF(NET.ERR.no=26228) THEN
				brsstrcpy(ADR(NET.ERR.text), ADR('connection rejected: check network protocol, username and password'));
			ELSIF(DevLink_0.status = fiERR_DEVICE_ALREADY_EXIST) THEN
				brsstrcpy(ADR(NET.ERR.text), ADR('device is already connected'));
			END_IF
			
			// Reset error
			IF(NET.CMD.error_reset) THEN
				NET.CMD.error_reset := FALSE;
				NET.ERR.active := FALSE;
				NET.ERR.no := 0;
				brsmemset(ADR(NET.ERR.text), 0, SIZEOF(NET.ERR.text));
				NET.PAR.state_machine := NET_WAIT;
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

