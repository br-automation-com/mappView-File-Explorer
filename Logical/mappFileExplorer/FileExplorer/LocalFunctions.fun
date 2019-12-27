
FUNCTION ReplaceString : BOOL
	VAR_INPUT
		dataSTR : UDINT;
		searchSTR : UDINT;
		replaceSTR : UDINT;
	END_VAR
	VAR
		idx : UDINT;
	END_VAR
END_FUNCTION

FUNCTION IsInstr : BOOL
	VAR_INPUT
		string1 : UDINT;
		string2 : UDINT;
	END_VAR
	VAR
		idx : UDINT;
	END_VAR
END_FUNCTION

FUNCTION FindInMem : UDINT
	VAR_INPUT
		data1 : UDINT;
		len1 : UDINT;
		data2 : UDINT;
		len2 : UDINT;
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
		text : STRING[150];
		EXPL : REFERENCE TO expMAIN;
	END_VAR
END_FUNCTION

FUNCTION InsertRecName : BOOL
	VAR_INPUT
		EXPL : REFERENCE TO expMAIN;
		new_name : STRING[EXPL_ITEM_LENGTH];
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
		path : STRING[EXPL_DIR_PATH_LENGTH];
		target : STRING[EXPL_ITEM_LENGTH];
		return_path : UDINT;
	END_VAR
	VAR
		tmp : STRING[EXPL_ITEM_LENGTH];
	END_VAR
END_FUNCTION

FUNCTION String2DataProvider : BOOL
	VAR_INPUT
		SourceString : UDINT;
		TargetString : UDINT;
	END_VAR
END_FUNCTION
