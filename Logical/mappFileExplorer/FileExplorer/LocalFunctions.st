
//******************************************************************************************************
// Raise error function																					
//******************************************************************************************************
FUNCTION CreateError
	// Generate for known errors
	IF (nr = fiERR_NOT_ENOUGH_FREEMEM) THEN
		EXPL.ERR.txt := 'not enough memory available on the target device';
	ELSIF (nr = fiERR_FILE_DEVICE) THEN
		EXPL.ERR.txt := 'device is not connected';
	ELSIF (nr = fiERR_INVALID_PATH) THEN
		EXPL.ERR.txt := 'directory is too long or has invalid characters';
	ELSIF (nr = fiERR_DIR_NOT_EXIST) THEN
		EXPL.ERR.txt := 'directory does not exist';
	ELSIF (nr = fiERR_FILE_DEVICE) THEN
		EXPL.ERR.txt := 'directory path does not exist';
	ELSIF (nr = fiERR_DIR_ALREADY_EXIST) THEN
		EXPL.ERR.txt := 'directory or file already exists';			
	ELSE 
		EXPL.ERR.txt := text;
	END_IF	
	// Convert to error structure																		
	IF (side = 0) THEN
		brsstrcat(ADR(EXPL.ERR.txt), ADR(' on side a'));
	ELSE			
		brsstrcat(ADR(EXPL.ERR.txt), ADR(' on side b'));
	END_IF
	EXPL.ERR.no   	:= nr;
	EXPL.ERR.step 	:= step;
	// Set next step
	IF (step = STP_READ_DIR_2) THEN
		CreateError := STP_READ_DIR_3;
	ELSE
		// Reset all commands																				
		brsmemset(ADR(EXPL.CMD[side]), 0, SIZEOF(EXPL.CMD[side]));
		brsmemset(ADR(EXPL.CMD[NOT side]), 0, SIZEOF(EXPL.CMD[NOT side]));
		CreateError := STP_WAIT;
	END_IF
END_FUNCTION

//******************************************************************************************************
// Create complete path string																			
//******************************************************************************************************
FUNCTION CreateCompletePath
	brsmemset(ADR(tmp), 0, MAX_ITEM_SIZE);
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
	brsstrcat(return_path, ADR('/')); 
	brsstrcat(return_path, ADR(tmp));
	
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
	
	brsmemset(ADR(EXPL.status), 0, SIZEOF(EXPL.status));
	brsstrcpy(ADR(EXPL.status), str);
	CASE(animation) OF
		0..19	: brsstrcat(ADR(EXPL.status), ADR('/'));
		20..39	: brsstrcat(ADR(EXPL.status), ADR('-'));
		40..59	: brsstrcat(ADR(EXPL.status), ADR('\'));
		60..79	: brsstrcat(ADR(EXPL.status), ADR('|'));
	END_CASE;
	WorkingStatus := animation;
END_FUNCTION

//******************************************************************************************************
// Fill new folder or directory name																	
//******************************************************************************************************
FUNCTION InsertRecName
	// Set up start values for iteration																
	IF (EXPL.DAT[side].item_num <> 0) THEN 
		ly := EXPL.DAT[side].item_num - 1;
	END_IF
	lx := ly;
	
	// Start itteration	search																			
	WHILE (ly > 1) DO
		// Check current entry																			
		lSort := brsstrcmp(ADR(new_name), ADR(EXPL.DAT[side].item_list[ly]));
		// Solve new search range																		
		IF (ly MOD 2 = 0) THEN
			ly := ly / 2;
		ELSE				
			ly := ly / 2 + 1;
		END_IF
		// New range is lower or higher than current													
		IF (lSort > 0) THEN
			lx := lx + ly;
			IF (lx > UINT_TO_INT(EXPL.DAT[side].item_num)) THEN
				lx := EXPL.DAT[side].item_num;  
			END_IF
		ELSE
			lx := lx - ly;
			IF (lx < 1) THEN
				lx := 1;
			END_IF
		END_IF		
	END_WHILE;
			
	// New entry is this, next or previous 																
	lSort := brsstrcmp(ADR(new_name), ADR(EXPL.DAT[side].item_list[lx]));
	IF (lSort > 0 AND lx <> UINT_TO_INT(EXPL.DAT[side].item_num)) THEN 
		lx := lx +1;
	ELSIF (lx > 0) THEN
		lSort := brsstrcmp(ADR(new_name), ADR(EXPL.DAT[side].item_list[lx-1]));
		IF (lSort < 0) THEN 
			lx := lx - 1;
		END_IF
	END_IF
	
	// Force ".." at beginning of list	 																
	IF (lx = 0 AND EXPL.DAT[side].item_list[0] = '..') THEN
		lx := lx + 1;
	END_IF
	// Move all data entrys backwards and fill in new entry												
	brsmemmove(ADR(EXPL.DAT[side].item_list[lx+1]),ADR(EXPL.DAT[side].item_list[lx]), (EXPL.DAT[side].item_num - lx) * SIZEOF(EXPL.DAT[side].item_list[0]));
	brsstrcpy(ADR(EXPL.DAT[side].item_list[lx]), ADR(new_name));

	// Create data structure for vis size listbox															
	brsmemmove(ADR(EXPL.DAT[side].item_size[lx+1]),ADR(EXPL.DAT[side].item_size[lx]), (EXPL.DAT[side].item_num - lx) * SIZEOF(EXPL.DAT[side].item_size[0]));
	brsstrcpy(ADR(EXPL.DAT[side].item_size[lx]), ADR(size));
	
	InsertRecName := TRUE;
END_FUNCTION

//******************************************************************************************************
// Is second string in first string																		
//******************************************************************************************************
FUNCTION IsInstr
	IF (brsstrlen(string1) > brsstrlen(string2)) THEN
		FOR lx:=0 TO brsstrlen(string1) - brsstrlen(string2) DO
			IF (brsmemcmp(string1 + lx, string2, brsstrlen(string2)) = 0) THEN
				IsInstr := TRUE;
				EXIT;
			END_IF
		END_FOR;
	END_IF
END_FUNCTION

