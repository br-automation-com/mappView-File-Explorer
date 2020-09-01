
TYPE
	netSTATE : 
		(
		NET_WAIT, (*Function step: Wait for starting the Function chain*)
		NET_LINK_DEVICE, (*Function step: Link file device*)
		NET_UNLINK_DEVICE, (*Function step: Unlink the File Device from specific path*)
		NET_ERROR (*Function step: Jump to this step in every case of Error occuring in the Function chain*)
		);
	netCMD : 	STRUCT 
		connect : BOOL; (*Connect to network share*)
		disconnect : BOOL; (*Disconnect from network share*)
		error_reset : BOOL; (*Reset error*)
	END_STRUCT;
	netPAR : 	STRUCT 
		server_name : STRING[80]; (*Use server name*)
		server_ip : STRING[80] := '192.168.0.10'; (*or IP address*)
		server_port : STRING[80]; (*Uses default port when empty*)
		server_protocol : STRING[80] := 'cifs'; (*Type of network connection*)
		server_domain : STRING[80]; (*Domain name*)
		server_share : STRING[80] := 'share'; (*Name of the shared folder*)
		user_name : STRING[80] := 'user'; (*User name*)
		user_password : STRING[80] := 'password'; (*User password*)
		enable_connect : BOOL; (*Enable button connect*)
		can_ping : BOOL; (*Indicates that the network share can be pinged*)
		is_linked : BOOL; (*Network share is connected*)
	END_STRUCT;
	netERR : 	STRUCT 
		state : netSTATE;
		text : STRING[80]; (*Error text*)
	END_STRUCT;
	netMAIN : 	STRUCT 
		CMD : netCMD; (*Command structure*)
		PAR : netPAR; (*Parameter structure*)
		ERR : netERR; (*Error structure*)
		status : UINT;
	END_STRUCT;
END_TYPE
