
//******************************************************************************************************
// Create mappView data provider string
//******************************************************************************************************
FUNCTION String2DataProvider
	brsstrcpy(TargetString, ADR('{"value":"'));
	brsstrcat(TargetString, SourceString);
	brsstrcat(TargetString, ADR('","text":"'));	
	brsstrcat(TargetString, SourceString);
	brsstrcat(TargetString, ADR('"}'));
	String2DataProvider := TRUE;
END_FUNCTION

//******************************************************************************************************
// Raise error function																					
//******************************************************************************************************
FUNCTION CreateError
	// Generate for known errors
	IF (nr = fiERR_NOT_ENOUGH_FREEMEM) THEN
		EXPL.ERR.text := 'not enough memory available on the target device';
	ELSIF (nr = fiERR_FILE_DEVICE) THEN
		EXPL.ERR.text := 'device is not connected';
	ELSIF (nr = fiERR_INVALID_PATH) THEN
		EXPL.ERR.text := 'directory is too long, does not exist or has invalid characters';
	ELSIF (nr = fiERR_DIR_NOT_EXIST) THEN
		EXPL.ERR.text := 'directory does not exist';
	ELSIF (nr = fiERR_FILE_DEVICE) THEN
		EXPL.ERR.text := 'directory path does not exist';
	ELSIF (nr = fiERR_DIR_ALREADY_EXIST) THEN
		EXPL.ERR.text := 'directory or file already exists';
	ELSIF (nr = fiERR_EXIST) THEN
		EXPL.ERR.text := 'error uploading file already exists';
	ELSE 
		EXPL.ERR.text := text;
	END_IF	
	// Convert to error structure																		
	IF (side = 0) THEN
		brsstrcat(ADR(EXPL.ERR.text), ADR(' on side a'));
	ELSE			
		brsstrcat(ADR(EXPL.ERR.text), ADR(' on side b'));
	END_IF
	EXPL.status_no 	:= nr;
	EXPL.ERR.state 	:= step;
	// When error occurs in dir read call dir close before reporting error
	IF (step = EXP_READ_DIR_2) THEN
		CreateError := EXP_READ_DIR_3;
	// When error occurs in file write call file close before reporting error
	ELSIF(step = EXP_FILE_UPLOAD_2) THEN
		CreateError := EXP_FILE_UPLOAD_3;
	ELSE
		// Reset all commands																				
		brsmemset(ADR(EXPL.CMD[side]), 0, SIZEOF(EXPL.CMD[side]));
		brsmemset(ADR(EXPL.CMD[NOT side]), 0, SIZEOF(EXPL.CMD[NOT side]));
		CreateError := EXP_WAIT;
	END_IF
END_FUNCTION

//******************************************************************************************************
// Create complete path string																			
//******************************************************************************************************
FUNCTION CreateCompletePath
	brsmemset(ADR(tmp), 0, EXPL_ITEM_LENGTH);
	brsstrcpy(return_path, ADR(path));
	
	// ------------------------------------------------------------------------------------------------ 		
	// Filter directory name																			
	IF(brsmemcmp(ADR(target), ADR('(DIR)'), 5) = 0) THEN
		brsmemcpy(ADR(tmp), ADR(target)+5, brsstrlen(ADR(target))-5);
	ELSE
		brsstrcpy(ADR(tmp), ADR(target));
	END_IF
		
	// ------------------------------------------------------------------------------------------------ 		
	// Create directory path
	IF(path <> '/') THEN
		brsstrcat(return_path, ADR('/')); 
	END_IF
	brsstrcat(return_path, ADR(tmp));
	//	brsstrcat(return_path, ADR('/')); 
	
	CreateCompletePath := FALSE;
END_FUNCTION

//******************************************************************************************************
// Working status																						
//******************************************************************************************************
FUNCTION WorkingStatus
	animation := animation+1;
	
	IF (animation = 80) THEN
		animation := 0;
	END_IF
	
	brsmemset(ADR(EXPL.status_text), 0, SIZEOF(EXPL.status_text));
	brsstrcpy(ADR(EXPL.status_text), str);
	CASE(animation) OF
		0..19	: brsstrcat(ADR(EXPL.status_text), ADR('/'));
		20..39	: brsstrcat(ADR(EXPL.status_text), ADR('-'));
		40..59	: brsstrcat(ADR(EXPL.status_text), ADR('\'));
		60..79	: brsstrcat(ADR(EXPL.status_text), ADR('|'));
	END_CASE;
	WorkingStatus := animation;
END_FUNCTION

//******************************************************************************************************
// Fill new folder or directory name																	
//******************************************************************************************************
FUNCTION InsertRecName
	// Set up start values for iteration																
	IF (EXPL.DAT[side].item_num <> 0) THEN 
		idy := EXPL.DAT[side].item_num - 1;
	END_IF
	idx := idy;
	
	// Start iteration	search																			
	WHILE (idy > 1) DO
		// Check current entry																			
		lSort := brsstrcmp(ADR(new_name), ADR(EXPL.DAT[side].item_list[idy]));
		// Solve new search range																		
		IF (idy MOD 2 = 0) THEN
			idy := idy / 2;
		ELSE				
			idy := idy / 2 + 1;
		END_IF
		// New range is lower or higher than current													
		IF (lSort > 0) THEN
			idx := idx + idy;
			IF (idx > UINT_TO_INT(EXPL.DAT[side].item_num)) THEN
				idx := EXPL.DAT[side].item_num;  
			END_IF
		ELSE
			idx := idx - idy;
			IF (idx < 1) THEN
				idx := 1;
			END_IF
		END_IF		
	END_WHILE;
			
	// New entry is this, next or previous 																
	lSort := brsstrcmp(ADR(new_name), ADR(EXPL.DAT[side].item_list[idx]));
	IF (lSort > 0 AND idx <> UINT_TO_INT(EXPL.DAT[side].item_num)) THEN 
		idx := idx +1;
	ELSIF (idx > 0) THEN
		lSort := brsstrcmp(ADR(new_name), ADR(EXPL.DAT[side].item_list[idx-1]));
		IF (lSort < 0) THEN 
			idx := idx - 1;
		END_IF
	END_IF
	
	// Force ".." at beginning of list	 																
	IF (idx = 0 AND EXPL.DAT[side].item_list[0] = '..') THEN
		idx := idx + 1;
	END_IF
	// Move all data entrys backwards and fill in new entry
	IF(idx < EXPL_LIST_NUM) THEN
		brsmemmove(ADR(EXPL.DAT[side].item_list[idx+1]),ADR(EXPL.DAT[side].item_list[idx]), (EXPL.DAT[side].item_num - idx) * SIZEOF(EXPL.DAT[side].item_list[0]));
		brsmemmove(ADR(EXPL.DAT[side].item_size[idx+1]),ADR(EXPL.DAT[side].item_size[idx]), (EXPL.DAT[side].item_num - idx) * SIZEOF(EXPL.DAT[side].item_size[0]));
	END_IF
	brsstrcpy(ADR(EXPL.DAT[side].item_list[idx]), ADR(new_name));
	// Create data structure for vis size list															
	brsstrcpy(ADR(EXPL.DAT[side].item_size[idx]), ADR(size));
	
	InsertRecName := TRUE;
END_FUNCTION

//******************************************************************************************************
// Is second string in first string																		
//******************************************************************************************************
FUNCTION IsInstr
	IF (brsstrlen(string1) > brsstrlen(string2)) THEN
		FOR idx:=0 TO brsstrlen(string1) - brsstrlen(string2) DO
			IF (brsmemcmp(string1 + idx, string2, brsstrlen(string2)) = 0) THEN
				IsInstr := TRUE;
				EXIT;
			END_IF
		END_FOR;
	END_IF
END_FUNCTION

//******************************************************************************************************
// Find second data in first data																		
//******************************************************************************************************
FUNCTION FindInMem
	FindInMem := -1;
	IF (len1 > len2) THEN
		IF(direction) THEN
			idx := len1 - len2; 
			WHILE(idx > 0) DO
				IF (brsmemcmp(data1 + idx, data2, len2) = 0) THEN
					FindInMem := idx;
					EXIT;
				END_IF
				idx := idx - 1;
			END_WHILE;
		ELSE
			FOR idx:=0 TO len1 - len2 DO
				IF (brsmemcmp(data1 + idx, data2, len2) = 0) THEN
					FindInMem := idx;
					EXIT;
				END_IF
			END_FOR;
		END_IF
	END_IF
END_FUNCTION

//******************************************************************************************************
// Find and replace string																	
//******************************************************************************************************
FUNCTION ReplaceString
	IF (brsstrlen(dataSTR) >= brsstrlen(searchSTR)) THEN
		FOR idx:=0 TO brsstrlen(dataSTR) - brsstrlen(searchSTR) DO
			IF (brsmemcmp(dataSTR + idx, searchSTR, brsstrlen(searchSTR)) = 0) THEN
				// Move data around
				brsmemmove(dataSTR + idx + brsstrlen(replaceSTR), dataSTR + idx + brsstrlen(searchSTR), brsstrlen(dataSTR) - brsstrlen(searchSTR) + 1);
				brsmemcpy(dataSTR + idx, replaceSTR, brsstrlen(replaceSTR));
				// Set found flag and exit if only one hit is needed
				ReplaceString := TRUE;
				IF(first) THEN
					EXIT;
				END_IF
				// Correct index for next search
				IF(brsstrlen(replaceSTR) > 0) THEN
					idx := idx + brsstrlen(replaceSTR);
				END_IF
				idx := idx - 1;
				// Exit if no data is left
				IF (brsstrlen(dataSTR) = 0 OR brsstrlen(dataSTR) < brsstrlen(searchSTR)) THEN
					EXIT;
				END_IF
			END_IF
		END_FOR;
	END_IF
END_FUNCTION

