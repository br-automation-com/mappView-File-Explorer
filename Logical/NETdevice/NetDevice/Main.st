PROGRAM _INIT
END_PROGRAM

PROGRAM _CYCLIC
	// Trigger ping request
	PingTimer.IN := TRUE;
	PingTimer.PT := PING_TIMEOUT;
	PingTimer();
	// Try to ping network share if not connected
	IF((NET.PAR.server_ip <> '' OR NET.PAR.server_name <> '') AND PingTimer.Q) THEN
		// Use IPÜ address
		IF(NET.PAR.server_ip <> '') THEN
			IcmpPing_0(enable := 1, pHost := ADR(NET.PAR.server_ip), timeout := PING_TIMEOUT);
		// Use host name		
		ELSE
			IcmpPing_0(enable := 1, pHost := ADR(NET.PAR.server_name), timeout := PING_TIMEOUT);
		END_IF
		// Ping was OK
		IF(IcmpPing_0.status = ERR_OK) THEN
			PingTimer(IN := FALSE);
			NET.PAR.can_ping := TRUE;
		// Disconnect from share when ping failed
		ELSIF(IcmpPing_0.status <> ERR_FUB_BUSY) THEN
			PingTimer(IN := FALSE);
			NET.PAR.can_ping := FALSE;
			IF(NET.PAR.is_linked) THEN
				NET.CMD.disconnect := TRUE;
			END_IF
		END_IF
	ELSIF(PingTimer.Q) THEN
		PingTimer(IN := FALSE);
	END_IF

	CASE state_machine OF
		// -----------------------------------------------------------------------------------------------------------
		// Wait state
		// -----------------------------------------------------------------------------------------------------------
		NET_WAIT:
			NET.PAR.enable_connect := TRUE;
			NET.status := ERR_OK;
			// --------------------------------------------------------------------------------------------------------------------	
			// Connect to server
			IF(NET.CMD.connect) THEN
				DevLink_0(enable := FALSE);
				IF(NET.PAR.is_linked) THEN
					state_machine := NET_UNLINK_DEVICE;
				ELSE
					state_machine := NET_LINK_DEVICE;
				END_IF
				NET.status := ERR_FUB_BUSY;
			END_IF
			// --------------------------------------------------------------------------------------------------------------------	
			// Disconnect from server
			IF(NET.CMD.disconnect) THEN
				DevUnlink_0.enable := 0;
				DevUnlink_0;
				state_machine := NET_UNLINK_DEVICE;
			END_IF
			// --------------------------------------------------------------------------------------------------------------------	
			// Reset error
			IF(NET.CMD.error_reset) THEN
				NET.CMD.error_reset := FALSE;
				brsmemset(ADR(NET.ERR), 0, SIZEOF(NET.ERR));
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
				NET.PAR.is_linked := TRUE;
				NET.CMD.connect := FALSE;				
				state_machine := NET_WAIT;
			// --------------------------------------------------------------------------------------------------------------------	
			// Abort command
			ELSIF(NET.CMD.error_reset = TRUE OR NET.CMD.disconnect = TRUE) THEN
				IF(DevLink_0.handle = 0) THEN
					DevLink_0(enable := FALSE);
					brsmemset(ADR(NET.CMD), 0, SIZEOF(NET.CMD));
					state_machine := NET_WAIT;
				ELSE				
					state_machine := NET_UNLINK_DEVICE;
				END_IF
			// Error
			ELSIF DevLink_0.status <> ERR_FUB_BUSY THEN
				NET.ERR.state := state_machine;
				NET.ERR.text := 'error linking device';
				NET.status := DevLink_0.status;
				state_machine := NET_ERROR;  
			END_IF;										
		// -----------------------------------------------------------------------------------------------------------
		// UnLink device
		// -----------------------------------------------------------------------------------------------------------				
		NET_UNLINK_DEVICE:
			NET.PAR.enable_connect := FALSE;
			DevUnlink_0.enable := 1;
			DevUnlink_0.handle := DevLink_0.handle;  
			DevUnlink_0;
	
			// --------------------------------------------------------------------------------------------------------------------	
			// Success
			IF DevUnlink_0.status = 0 THEN
				brsmemset(ADR(NET.CMD), 0, SIZEOF(NET.CMD));
				NET.PAR.is_linked := FALSE;
				DevLink_0(enable := FALSE);
				IF(NET.CMD.connect) THEN
					state_machine := NET_LINK_DEVICE;
				ELSE
					state_machine := NET_WAIT;
				END_IF					
			// Error
			ELSIF DevUnlink_0.status <> ERR_FUB_BUSY THEN
				NET.CMD.error_reset := FALSE;
				NET.ERR.state := state_machine;
				NET.ERR.text := 'error unlinking device';
				NET.status := DevUnlink_0.status;
				state_machine := NET_ERROR;
			END_IF;
		// -----------------------------------------------------------------------------------------------------------
		// Error step
		// -----------------------------------------------------------------------------------------------------------				
		NET_ERROR:
			// Reset commands
			NET.PAR.enable_connect := FALSE;
			NET.CMD.connect := FALSE;
			NET.CMD.disconnect := FALSE;

			// Get more error information
			IF(NET.status = 0) THEN
				NET.status := FileIoGetSysError();
			END_IF
			IF(NET.status = 26228) THEN
				brsstrcpy(ADR(NET.ERR.text), ADR('connection rejected: check network protocol, username and password'));
			ELSIF(DevLink_0.status = fiERR_DEVICE_ALREADY_EXIST) THEN
				brsstrcpy(ADR(NET.ERR.text), ADR('device is already connected'));
			END_IF
			
			// Reset error
			IF(NET.CMD.error_reset) THEN
				NET.CMD.error_reset := FALSE;
				brsmemset(ADR(NET.ERR), 0, SIZEOF(NET.ERR));
				DevLink_0(enable := FALSE);
				DevUnlink_0(enable := FALSE);
				state_machine := NET_WAIT;
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

