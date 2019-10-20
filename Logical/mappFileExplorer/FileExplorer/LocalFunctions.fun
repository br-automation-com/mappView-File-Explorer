
FUNCTION IsInstr : BOOL
	VAR_INPUT
		string1 : UDINT;
		string2 : UDINT;
	END_VAR
	VAR
		idx : UDINT;
	END_VAR
END_FUNCTION

{REDUND_ERROR} FUNCTION CreateError : expSTATE (*TODO: Add your comment here*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		nr : UINT;
		side : BOOL;
		step : expSTATE;
		text : STRING[100];
		EXPL : REFERENCE TO expMAIN;
	END_VAR
END_FUNCTION

FUNCTION InsertRecName : BOOL
	VAR_INPUT
		EXPL : REFERENCE TO expMAIN;
		new_name : STRING[MAX_ITEM_SIZE];
		size : STRING[15];
		side : BOOL;
	END_VAR
	VAR
		idx : DINT;
		idy : DINT;
		lSort : DINT;
	END_VAR
END_FUNCTION

FUNCTION WorkingStatus : USINT
	VAR_INPUT
		EXPL : REFERENCE TO expMAIN;
		str : UDINT;
		animation : USINT;
	END_VAR
END_FUNCTION

FUNCTION CreateCompletePath : BOOL
	VAR_INPUT
		path : STRING[DIR_PATH_SIZE];
		target : STRING[MAX_ITEM_SIZE];
		return_path : UDINT;
	END_VAR
	VAR
		tmp : STRING[MAX_ITEM_SIZE];
	END_VAR
END_FUNCTION
