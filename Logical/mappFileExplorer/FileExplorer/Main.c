	//******************************** B&R * Application TB-West *******************************************
	//	Function:	Mini explorer																			
	//	Autor:		S.Stricker																				
	//  Version:	1.00																					
	//	Changed:	03.09.2019																				
	//	Error numbers:																						
	//	50000		Selected item name is empty																
	//	50001		This is not a valid item name															
	//	50010		Device is not defined																	
	//	50011		Item list is not defined																
	//	50012		Maximum entry parameter is 0															
	//	50100		Maximum number of files reached															
	//	50200		File name exceeds maximum length														
	//	50201		Directory name exceeds maximum length													
	//	50202		Directory path exceeds maximum length													
	//	50203		Directory path critical error															
	//******************************************************************************************************

#include <bur/plctypes.h>

#ifdef _DEFAULT_INCLUDES
	#include <AsDefault.h>
#endif

void CreateError(UINT nr, USINT SIDE, STRING txt[100], typMain_EXP *EXPL);
void WorkingStatus(typMain_EXP *EXPL, UDINT str);
void CreateCompletePath(STRING path[DIR_PATH_SIZE+MAX_ITEM_SIZE], STRING target[MAX_ITEM_SIZE], UDINT return_path);
void InsertRecName(typMain_EXP *EXPL, STRING new_name[DIR_PATH_SIZE], STRING size[15], UINT SIDE);
void SelectItem(typMain_EXP *EXPL, USINT SOURCE);
BOOL IsInstr(STRING string1[MAX_ITEM_SIZE], STRING string2[MAX_ITEM_SIZE]);

//******************************************************************************************************
// Init Part																							
//******************************************************************************************************
void _INIT ProgramInit(void)
{
	brsmemcpy((UDINT)EXPL.PAR[0].device_list, (UDINT)DEVICE_LIST, sizeof(DEVICE_LIST));
	brsmemcpy((UDINT)EXPL.PAR[1].device_list, (UDINT)DEVICE_LIST, sizeof(DEVICE_LIST));
	brsstrcpy((UDINT)EXPL.PAR[0].device_active, (UDINT)EXPL.PAR[0].device_list[0]);
	brsstrcpy((UDINT)EXPL.PAR[1].device_active, (UDINT)EXPL.PAR[1].device_list[0]);
}

//******************************************************************************************************
// Cyclic Part																							
//******************************************************************************************************
void _CYCLIC ProgramCyclic(void)
{
	USINT SIDE;
	SIDE = side;

	//--------------------------------------------------------------------------------------------------
	// Check if parameters are valid																	
	if (brsstrcmp((UDINT)EXPL.PAR[SIDE].device_active, (UDINT)"") == 0)
	{
		CreateError(50010, SIDE, "device is not defined", &EXPL);
		return;
	}
	if(brsstrlen((UDINT)EXPL.PAR[SIDE].dir_path) >= DIR_PATH_SIZE)
	{
		CreateError(50203, SIDE, "Directory path critical error", &EXPL);
		return;
	}
	// ------------------------------------------------------------------------------------------------ 
	// Track filter change																				
	if((FILTER_AUTO_REFRESH) && (brsstrcmp((UDINT)old_filter[SIDE], (UDINT)EXPL.PAR[SIDE].item_filter) != 0))
	{
		brsstrcpy((UDINT)old_filter[SIDE], (UDINT)EXPL.PAR[SIDE].item_filter);
		EXPL.CMD[SIDE].refresh	= 1;			
	}
	
	// ------------------------------------------------------------------------------------------------ 
	// Track device name change																				
	if(brsstrcmp((UDINT)device_active_old[SIDE], (UDINT)EXPL.PAR[SIDE].device_active) != 0)
	{
		brsstrcpy((UDINT)EXPL.PAR[SIDE].dir_path, (UDINT)"");
		EXPL.CMD[SIDE].refresh	= 1;			
	} 
	brsstrcpy((UDINT)device_active_old[SIDE], (UDINT)EXPL.PAR[SIDE].device_active);
	
	// ------------------------------------------------------------------------------------------------ 
	// Set switches for HMI
	if(EXPL.DAT[SIDE].item_num > 0) EXPL.VIS[SIDE].enable_copy_delete = 1;
	else EXPL.VIS[SIDE].enable_copy_delete = 0;
	
	// ------------------------------------------------------------------------------------------------
	// Generate device name list
	brsmemset((UDINT)EXPL.VIS[SIDE].device_list, 0, sizeof(EXPL.VIS[SIDE].device_list));
	for (x = 0; x < sizeof(EXPL.VIS[SIDE].device_list)/sizeof(EXPL.VIS[SIDE].device_list[0]); x++)
	{
		if (brsstrcmp((UDINT)EXPL.PAR[SIDE].device_list[x], (UDINT)"") != 0)
		{
			brsstrcpy((UDINT)EXPL.VIS[SIDE].device_list[x], (UDINT)"{\"value\":\"");
			brsstrcat((UDINT)EXPL.VIS[SIDE].device_list[x], (UDINT)EXPL.PAR[SIDE].device_list[x]);					
			brsstrcat((UDINT)EXPL.VIS[SIDE].device_list[x], (UDINT)"\",\"text\":\"");
			brsstrcat((UDINT)EXPL.VIS[SIDE].device_list[x], (UDINT)EXPL.PAR[SIDE].device_list[x]);					
			brsstrcat((UDINT)EXPL.VIS[SIDE].device_list[x], (UDINT)"\"}");
		}
	}

	// ------------------------------------------------------------------------------------------------ 
	// Handle double click for directory change
	if(EXPL.VIS[SIDE].double_click_dir_change > 0)
	{
		DoubleClickDirChange.PT = 50;
		DoubleClickDirChange.IN = 1;
		TON_10ms(&DoubleClickDirChange);
		if(EXPL.VIS[SIDE].double_click_dir_change > 1) 
		{
			DoubleClickDirChange.IN = 0;
			TON_10ms(&DoubleClickDirChange);
			EXPL.VIS[SIDE].double_click_dir_change = 0;
			if(brsmemcmp((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)"(DIR)", 5) == 0 || 
			   brsmemcmp((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)"..", 2) == 0) EXPL.CMD[SIDE].dir_change = 1;
		}
	}
	if(DoubleClickDirChange.Q)
	{
		DoubleClickDirChange.IN = 0;
		TON_10ms(&DoubleClickDirChange);
		if(EXPL.VIS[SIDE].double_click_dir_change > 0) EXPL.VIS[SIDE].double_click_dir_change = EXPL.VIS[SIDE].double_click_dir_change - 1;		
	}
	
	for (cycles = 0; cycles < override; cycles++)
	{
		// ------------------------------------------------------------------------------------------------ 
		// Break if no command is set																		
		if (EXPL.CMD[SIDE].refresh 		== 0 && 
			EXPL.CMD[SIDE].dir_change	== 0 &&
			EXPL.CMD[SIDE].dir_create 	== 0 && 
			EXPL.CMD[SIDE].copy 		== 0 && 
			EXPL.CMD[SIDE].copyall 		== 0 && 
			EXPL.CMD[SIDE].delete 		== 0)
		{
			// -------------------------------------------------------------------------------------------- 
			// Show current state																			
			brsstrcpy((UDINT)EXPL.status, (UDINT)"Waiting..."); 
			// -------------------------------------------------------------------------------------------- 
			// If selection is out of range set it to maximum												
			if ((EXPL.VIS[SIDE].item_selected > EXPL.DAT[SIDE].item_num - 1) && 
				(EXPL.DAT[SIDE].item_num != 0)) EXPL.VIS[SIDE].item_selected = EXPL.DAT[SIDE].item_num - 1;
			side = !side;
			// Enable buttons when command is active
			EXPL.VIS[0].enable_refresh_create = 1;
			EXPL.VIS[1].enable_refresh_create = 1;
			break;
		}
		// Disable buttons when command is active
		EXPL.VIS[0].enable_copy_delete = 0;
		EXPL.VIS[1].enable_copy_delete = 0;
		EXPL.VIS[0].enable_refresh_create = 0;
		EXPL.VIS[1].enable_refresh_create = 0;
		//**************************************************************************************************
		// Cyclic Part																						
		//**************************************************************************************************	
		switch (step)
		{
			//**********************************************************************************************
			// Wait for command																				
			//**********************************************************************************************
			case STP_WAIT:
				// ---------------------------------------------------------------------------------------- 
				// Command refresh																			
				if (EXPL.CMD[SIDE].refresh == 1) step = STP_READ_DIR;
				// ---------------------------------------------------------------------------------------- 
				// Command directory change																	
				if (EXPL.CMD[SIDE].dir_change == 1)	
				{
					// ------------------------------------------------------------------------------------ 		
					// Check if directory name is empty														
					if (brsstrcmp((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)"") == 0)	CreateError(50000, SIDE, "directory name is empty", &EXPL);
						// Check if directory name is valid														
					else if((brsmemcmp((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)"(DIR)", 5) != 0) && (brsmemcmp((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)"..", 2) != 0)) CreateError(50001, SIDE, "this is not a valid directory name", &EXPL);
						// Check if new directory name fits into string											
					else if(brsstrlen((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected]) - 5 + brsstrlen((UDINT)EXPL.PAR[SIDE].dir_path) + 1 >= DIR_PATH_SIZE) CreateError(50202, SIDE, "directory path exceeds maximum length", &EXPL);
					else step = STP_DIR_CHANGE;
				}
				// ---------------------------------------------------------------------------------------- 
				// Command directory create																	
				if (EXPL.CMD[SIDE].dir_create == 1) 	
				{
					// ------------------------------------------------------------------------------------ 		
					// Check if new directory name is empty													
					if (brsstrcmp((UDINT)EXPL.PAR[SIDE].dir_name, (UDINT)"") == 0) CreateError(50000, SIDE, "directory name is empty", &EXPL);
						// Check if new directory name fits into path string									
					else if(brsstrlen((UDINT)EXPL.PAR[SIDE].dir_name) + brsstrlen((UDINT)EXPL.PAR[SIDE].dir_path) + 1 >= DIR_PATH_SIZE) CreateError(50202, SIDE, "directory path name exceeds maximum length", &EXPL);
						// Check if new directory name fits into directory name string						
					else if(brsstrlen((UDINT)EXPL.PAR[SIDE].dir_name) + 5 >= MAX_ITEM_SIZE) CreateError(50201, SIDE, "directory name exceeds maximum length", &EXPL);
					else step = STP_DIR_CREATE;
				}
				// ---------------------------------------------------------------------------------------- 
				// Command copy																				
				if (EXPL.CMD[SIDE].copy == 1) 	
				{
					// ------------------------------------------------------------------------------------ 		
					// Make sure that user chooses a valid item												
					if (brsstrcmp((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)"..") == 0)			CreateError(50001, SIDE, "this is not a valid item name", &EXPL);
					else if(brsmemcmp((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)"(DIR)", 5) == 0)	step = STP_DIR_COPY;
					else																														step = STP_FILE_COPY;
				}
				// ---------------------------------------------------------------------------------------- 
				// Command copy all																			
				if (EXPL.CMD[SIDE].copyall == 1) step = STP_COPY_ALL;
				// ---------------------------------------------------------------------------------------- 
				// Command delete																			
				if (EXPL.CMD[SIDE].delete == 1) 	
				{
					// ------------------------------------------------------------------------------------ 		
					// Check if directory name is empty														
					if (brsstrcmp((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)"") == 0)	CreateError(50000, SIDE, "item name is empty", &EXPL);
						// Check if new directory name fits into string											
					else if(brsstrlen((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected]) + brsstrlen((UDINT)EXPL.PAR[SIDE].dir_path) + 1 >= DIR_PATH_SIZE + MAX_ITEM_SIZE) CreateError(50202, SIDE, "directory path exceeds maximum length", &EXPL);
						// Make sure that user chooses a valid item												
					else if(brsstrcmp((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)"..") == 0) CreateError(50001, SIDE, "this is not a valid item name", &EXPL);
						// Delete a directory																	
					else if(brsmemcmp((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)"(DIR)", 5) == 0)	step = STP_DIR_DELETE;
						// Delete a file																		
					else																											step = STP_FILE_DELETE;
				}
				// ---------------------------------------------------------------------------------------- 
				// Clear errors																						
				if (EXPL.CMD[SIDE].refresh 		== 1 || 
					EXPL.CMD[SIDE].copy 		== 1 || 
					EXPL.CMD[SIDE].copyall 		== 1 || 
					EXPL.CMD[SIDE].dir_create 	== 1 || 
					EXPL.CMD[SIDE].delete		== 1)
				{
					brsstrcpy((UDINT)EXPL.ERR.txt, (UDINT)"");
					EXPL.ERR.nr   		= 0;
					EXPL.ERR.step 		= 0;
				}			
				break;
			//**********************************************************************************************
			// Read directory information																	
			//**********************************************************************************************
			case STP_READ_DIR:
				// Show current state																		
				WorkingStatus(&EXPL, (UDINT)"read directory...");
				// ---------------------------------------------------------------------------------------- 
				// Clear all entrys																			
				brsmemset((UDINT)&EXPL.DAT[SIDE], 0, sizeof(EXPL.DAT[SIDE]));
				EXPL.VIS[SIDE].item_selected = 0;
				EXPL.DAT[SIDE].item_num = 0;
				// ---------------------------------------------------------------------------------------- 
				// Add .. for directory up																	
				if((brsstrcmp((UDINT)EXPL.PAR[SIDE].dir_path, (UDINT)"\\") != 0) && 
				   (brsstrcmp((UDINT)EXPL.PAR[SIDE].dir_path, (UDINT)"") != 0))
				{
					brsstrcpy((UDINT)EXPL.DAT[SIDE].item_list, (UDINT)"..");
					EXPL.DAT[SIDE].item_num = 1;			
				} 
				// ---------------------------------------------------------------------------------------- 		
				// Set values and get device dir															
				DInfo.enable 	= 1;
				DInfo.pDevice	= (UDINT)EXPL.PAR[SIDE].device_active;
				DInfo.pPath 	= (UDINT)EXPL.PAR[SIDE].dir_path;
				DirInfo(&DInfo);
					
				// ---------------------------------------------------------------------------------------- 		
				// ->Success																																				
				if (DInfo.status == OK) step = STP_READ_DIR_1;
				// ---------------------------------------------------------------------------------------- 		
				// Device is not available																	
				else if (DInfo.status == fiERR_FILE_DEVICE ) 
				{
					brsstrcpy((UDINT)EXPL.DAT[SIDE].item_list, (UDINT)"not connected");
					CreateError(DInfo.status, SIDE, "not connected", &EXPL);
				}
				// ---------------------------------------------------------------------------------------- 		
				// Device is not available																	
				else if (DInfo.status == fiERR_DEVICE_MANAGER ) 
				{
					brsstrcpy((UDINT)EXPL.DAT[SIDE].item_list, (UDINT)"not connected");
					CreateError(DInfo.status, SIDE, "check device name and path", &EXPL);
				}
				else if (DInfo.status != 65535) CreateError(DInfo.status, SIDE, "error dir info", &EXPL);			
				break;
			//**********************************************************************************************
			// Open directory 																				
			//**********************************************************************************************
			case STP_READ_DIR_1:
				// ---------------------------------------------------------------------------------------- 		
				// Set values and get device dir															
				DOpen.enable 	= 1;
				DOpen.pDevice	= (UDINT)EXPL.PAR[SIDE].device_active;
				DOpen.pName 	= (UDINT)EXPL.PAR[SIDE].dir_path;
				DirOpen(&DOpen);
					
				// ---------------------------------------------------------------------------------------- 		
				// ->Success																																				
				if (DOpen.status == OK) step	= STP_READ_DIR_2;
				else if (DOpen.status != 65535) CreateError(DOpen.status, SIDE, "error dir open", &EXPL);			
				break;
			//**********************************************************************************************
			// Read file directory information																
			//**********************************************************************************************
			case STP_READ_DIR_2:
				// ---------------------------------------------------------------------------------------- 		
				// Initialize read directory structure 														
				DRead.enable 	= 1;
				DRead.ident		= DOpen.ident;
				DRead.pData 	= (UDINT)&lDirReadData;
				DRead.data_len 	= sizeof(lDirReadData);
				DirReadEx(&DRead);
									
				// ---------------------------------------------------------------------------------------- 		
				// ->Success																																				
				if (DRead.status == OK)
				{
					// ------------------------------------------------------------------------------------ 		
					// Verify that we still have space in list												
					if (EXPL.DAT[SIDE].item_num < sizeof(EXPL.DAT[SIDE].item_list)/sizeof(EXPL.DAT[SIDE].item_list[0]))
					{
						// -------------------------------------------------------------------------------- 		
						// Verify that extension is equal to filter											
						if ((brsstrlen((UDINT)EXPL.PAR[SIDE].item_filter) == 0) || (IsInstr((STRING*)lDirReadData.Filename, EXPL.PAR[SIDE].item_filter)))
						{
							// ---------------------------------------------------------------------------- 		
							// Read file information														
							if (lDirReadData.Mode == fiFILE)
							{					
								if (brsstrlen((UDINT)lDirReadData.Filename) < MAX_ITEM_SIZE-5)
								{
									brsmemset((UDINT)tmp_str1, 0, sizeof(tmp_str1));
									brsmemcpy((UDINT)tmp_str1, (UDINT)lDirReadData.Filename, brsstrlen((UDINT)lDirReadData.Filename));
									// -------------------------------------------------------------------- 		
									// Append file size														
									if(lDirReadData.Filelength > 999999)
									{
										brsitoa((lDirReadData.Filelength/1000000), (UDINT)tmp_str2);
										brsstrcat((UDINT)tmp_str2, (UDINT)"M");
									}
									else if(lDirReadData.Filelength > 999)
									{
										brsitoa((lDirReadData.Filelength/1000), (UDINT)tmp_str2);
										brsstrcat((UDINT)tmp_str2, (UDINT)"K");
									}
									else
									{
										brsitoa((lDirReadData.Filelength), (UDINT)tmp_str2);
									}
									brsmemcpy((UDINT)tmp_str1 + MAX_ITEM_SIZE - brsstrlen((UDINT)tmp_str2) - 1, (UDINT)tmp_str2, brsstrlen((UDINT)tmp_str2));
									InsertRecName(&EXPL, tmp_str1, tmp_str2, SIDE);
									EXPL.DAT[SIDE].item_num++;
								}
								else CreateError(50200, SIDE, "file name exceeds maximum length", &EXPL);
							}
							// ---------------------------------------------------------------------------- 		
							// Read directory information													
							else if((brsstrcmp((UDINT)lDirReadData.Filename, (UDINT)".")  != 0) &&
								    (brsstrcmp((UDINT)lDirReadData.Filename, (UDINT)"..") != 0) &&
									(brsstrcmp((UDINT)lDirReadData.Filename, (UDINT)"System Volume Information") != 0))
								{																
								if (brsstrlen((UDINT)lDirReadData.Filename) < MAX_ITEM_SIZE-5)
								{
									// Copy directory name													
									brsstrcpy((UDINT)tmp_str1, (UDINT)"(DIR)");
									brsstrcat((UDINT)tmp_str1, (UDINT)lDirReadData.Filename);
									InsertRecName(&EXPL, tmp_str1, "", SIDE);
									EXPL.DAT[SIDE].item_num++;
								}
								else CreateError(50201, SIDE, "directory name exceeds maximum length", &EXPL);
							}
						}
					}
					else CreateError(50100, SIDE, "maximum number of files reached", &EXPL);
				}
				else if (DRead.status == fiERR_NO_MORE_ENTRIES) step = STP_READ_DIR_3;
					// ---------------------------------------------------------------------------------------- 		
				else if (DRead.status != 65535) CreateError(DRead.status, SIDE, "error dir read", &EXPL);
				break;	
			//**********************************************************************************************
			// Close directory information																	
			//**********************************************************************************************
			case STP_READ_DIR_3:
				// ---------------------------------------------------------------------------------------- 		
				// Initialize read directory structure 														
				DClose.enable 	= 1;
				DClose.ident	= DOpen.ident;
				DirClose(&DClose);
									
				// ---------------------------------------------------------------------------------------- 		
				// ->Success																																				
				if (DClose.status == OK)
				{
					// Select item after copy->refresh														
					if(do_select != 0)	SelectItem(&EXPL, do_select-1);
					do_select = 0;
					// Reset command and return to wait state												
					EXPL.CMD[SIDE].refresh	= 0;
					DClose.ident			= 0;
					step					= STP_WAIT;
				}
					// ---------------------------------------------------------------------------------------- 		
				else if (DClose.status != 65535) CreateError(DClose.status, SIDE, "error dir close", &EXPL);
				break;
			//**********************************************************************************************
			// Change directory 																			
			//**********************************************************************************************
			case STP_DIR_CHANGE:
				// ---------------------------------------------------------------------------------------- 		
				// Move one directory up																	
				if(brsstrcmp((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)"..") == 0)
				{
					x = brsstrlen((UDINT)EXPL.PAR[SIDE].dir_path);
					while(x>0)
					{				
					if(brsmemcmp((UDINT)(UDINT)(EXPL.PAR[SIDE].dir_path + x), (UDINT)"\\", 1) == 0) break;
					else brsmemset((UDINT)(UDINT)(EXPL.PAR[SIDE].dir_path + x), 0, 1);
					x--;
					}
					brsmemset((UDINT)(UDINT)(EXPL.PAR[SIDE].dir_path + x), 0, 1);
				}
					// ---------------------------------------------------------------------------------------- 		
					// Move one directory down																	
				else
				{
					brsstrcat((UDINT)EXPL.PAR[SIDE].dir_path, (UDINT)"\\");
					brsstrcat((UDINT)EXPL.PAR[SIDE].dir_path, (UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected] + 5);
					EXPL.CMD[SIDE].refresh = 1;
				}
				// Reset command and return to wait state													
				EXPL.VIS[SIDE].item_selected	= 0;
				EXPL.CMD[SIDE].dir_change 		= 0;
				EXPL.CMD[SIDE].refresh 			= 1;
				step							= STP_WAIT;
				break;
			//**********************************************************************************************
			// Copy all items																				
			//**********************************************************************************************
			case STP_COPY_ALL:
				// Show current state																		
				WorkingStatus(&EXPL, (UDINT)"copying files...");
					
				EXPL.VIS[SIDE].item_selected = 0;
				// ---------------------------------------------------------------------------------------- 		
				// Skip dots at list beginning																
				if (brsstrcmp((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)"..") == 0)		EXPL.VIS[SIDE].item_selected++;
				// Check first entry																		
				if(brsmemcmp((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)"(DIR)", 5) == 0)	step = STP_DIR_COPY;
				else																													step = STP_FILE_COPY;
				break;
			//**********************************************************************************************
			// Copy files																					
			//**********************************************************************************************
			case STP_FILE_COPY:
				// Show current state																		
				WorkingStatus(&EXPL, (UDINT)"copying file...");
		
				// -----------------------------------------------------------------.---------------------- 		
				// Proceed with copy all until last file is copied											
				if ((EXPL.VIS[SIDE].item_selected < sizeof(EXPL.DAT[SIDE].item_list)/sizeof(EXPL.DAT[SIDE].item_list[0])) && (EXPL.VIS[SIDE].item_selected < EXPL.DAT[SIDE].item_num))
				{
					// ------------------------------------------------------------------------------------ 		
					// Check if file name is empty															
					if (brsstrcmp((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)"") != 0)
					{		
						// -------------------------------------------------------------------------------- 
						// Check if new file name fits into string											
						if(brsstrlen((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected]) < MAX_ITEM_SIZE)
						{								
							// ---------------------------------------------------------------------------- 		
							// Initialize copy structure													
							CreateCompletePath((void*)EXPL.PAR[SIDE].dir_path, (void*)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)&tmp_str3);
							CreateCompletePath((void*)EXPL.PAR[!SIDE].dir_path, (void*)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)&tmp_str4);
							FCopy.enable 	= 1;
							FCopy.pSrcDev	= (UDINT)EXPL.PAR[SIDE].device_active;
							FCopy.pSrc		= (UDINT)&tmp_str3;
							FCopy.pDestDev  = (UDINT)EXPL.PAR[!SIDE].device_active;
							FCopy.pDest		= (UDINT)&tmp_str4;
							FCopy.option 	= FILE_OW_DETMEM;
							FileCopy(&FCopy);
												
							// ---------------------------------------------------------------------------- 		
							// ->Success																																	
							if ((FCopy.status == OK) && (EXPL.CMD[SIDE].copy == 1))
							{
								// Select entry, reset command and refresh directory						
								if(COPY_AUTO_REFRESH) EXPL.CMD[!SIDE].refresh = 1;
								if(COPY_AUTO_SELECT) do_select = SIDE + 1;
								EXPL.CMD[SIDE].copy	= 0;
								step = STP_WAIT;
							}
							// ---------------------------------------------------------------------------- 		
							// Proceed with next file														
							else if (FCopy.status == OK) EXPL.VIS[SIDE].item_selected++;
							else if (FCopy.status != 65535)	CreateError(FCopy.status, SIDE, "error copying file", &EXPL);
						}
						else CreateError(50200, SIDE, "file name exceeds maximum length", &EXPL);
					}
					else CreateError(50000, SIDE, "file name is empty", &EXPL);
				}
				// ---------------------------------------------------------------------------------------- 		
				// Finish copy all																			
				else
				{
					// Reset command and refresh directory													
					if(COPY_AUTO_REFRESH) EXPL.CMD[!SIDE].refresh = 1;
					EXPL.CMD[SIDE].copyall			= 0;
					EXPL.VIS[SIDE].item_selected 	= 0;
					step				= STP_WAIT;
				}
				break;		
			//**********************************************************************************************
			// Copy directory																				
			//**********************************************************************************************
			case STP_DIR_COPY:
				// Show current state																		
				WorkingStatus(&EXPL, (UDINT)"copying directory...");
		
				// ---------------------------------------------------------------------------------------- 		
				// Proceed with copy all until last file is copied											
				if ((EXPL.VIS[SIDE].item_selected < sizeof(EXPL.DAT[SIDE].item_list)/sizeof(EXPL.DAT[SIDE].item_list[0])) && (EXPL.VIS[SIDE].item_selected < EXPL.DAT[SIDE].item_num))
				{
					if (brsstrcmp((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)"") != 0)
					{		
					// -------------------------------------------------------------------------------- 		
					// Check if new directory name fits into path string								
					if(brsstrlen((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected]) + brsstrlen((UDINT)EXPL.PAR[!SIDE].dir_path) + 1 < DIR_PATH_SIZE)
					{								
					// ---------------------------------------------------------------------------- 		
					// Initialize copy structure													
					CreateCompletePath((void*)EXPL.PAR[SIDE].dir_path, (void*)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)&tmp_str3);
					CreateCompletePath((void*)EXPL.PAR[!SIDE].dir_path, (void*)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)&tmp_str4);
					DCopy.enable 	= 1;
					DCopy.pSrcDev	= (UDINT)EXPL.PAR[SIDE].device_active;
					DCopy.pSrcDir	= (UDINT)&tmp_str3;
					DCopy.pDestDev 	= (UDINT)EXPL.PAR[!SIDE].device_active;
					DCopy.pDestDir 	= (UDINT)&tmp_str4;
					DCopy.option 	= fiOVERWRITE;	
					DirCopy(&DCopy);
												
					// ---------------------------------------------------------------------------- 		
					// ->Success																																	
					if ((DCopy.status == OK) && (EXPL.CMD[SIDE].copy == 1))
					{
					// Reset command and refresh directory										
					if(COPY_AUTO_REFRESH) 	EXPL.CMD[!SIDE].refresh = 1;
					if(COPY_AUTO_SELECT) 	do_select = SIDE + 1;
					EXPL.CMD[SIDE].copy	= 0;
					step		= STP_WAIT;
					}
					// ---------------------------------------------------------------------------- 		
					// Proceed with next directory													
					else if (DCopy.status == OK) 
					{
					EXPL.VIS[SIDE].item_selected++;
					// Switch to file copy when no more directory can be found					
					if(brsmemcmp((UDINT)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)"(DIR)", 5) != 0)	step = STP_FILE_COPY;
					}
					else if (DCopy.status != 65535) CreateError(DCopy.status, SIDE, "error copying directory", &EXPL);
					}
					else CreateError(50202, SIDE, "directory path name exceeds maximum length", &EXPL);
					}
					else CreateError(50000, SIDE, "directory name is empty", &EXPL);
				}
					// ---------------------------------------------------------------------------------------- 		
					// Finish copy all																			
				else
				{
					// Reset command and refresh directory													
					if(COPY_AUTO_REFRESH) EXPL.CMD[!SIDE].refresh = 1;
					EXPL.CMD[SIDE].copyall			= 0;
					EXPL.VIS[SIDE].item_selected 	= 0;
					step				= STP_WAIT;
				}				
				break;		
			//**********************************************************************************************
			// Delete selected file																			
			//**********************************************************************************************
			case STP_FILE_DELETE:
				// Show current state																		
				WorkingStatus(&EXPL, (UDINT)"deleting file...");
		
				// ---------------------------------------------------------------------------------------- 		
				// Initialize file delete structure 														
				CreateCompletePath((void*)EXPL.PAR[SIDE].dir_path, (void*)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)&tmp_str3);
				FDelete.enable		= 1;
				FDelete.pDevice 	= (UDINT)EXPL.PAR[SIDE].device_active;
				FDelete.pName		= (UDINT)tmp_str3;
				FileDelete(&FDelete);
									
				// ---------------------------------------------------------------------------------------- 		
				// ->Success																																				
				if (FDelete.status == OK)
				{
					// Reset command and return to wait state												
					EXPL.CMD[SIDE].delete 	= 0;
					EXPL.CMD[SIDE].refresh  = 1;
					step = STP_WAIT;
				}
				else if (FDelete.status != 65535) CreateError(FDelete.status, SIDE, "error deleting file", &EXPL);
				break;
			//**********************************************************************************************
			// Create new directory																			
			//**********************************************************************************************
			case STP_DIR_CREATE:
				// Show current state																		
				WorkingStatus(&EXPL, (UDINT)"creating directory...");
		
				// ---------------------------------------------------------------------------------------- 		
				// Initialize directory create structure													
				CreateCompletePath((void*)EXPL.PAR[SIDE].dir_path, (void*)EXPL.PAR[SIDE].dir_name, (UDINT)&tmp_str3);
				DCreate.enable	= 1;
				DCreate.pDevice = (UDINT)EXPL.PAR[SIDE].device_active;
				DCreate.pName 	= (UDINT)&tmp_str3;
				DirCreate(&DCreate);
									
				// ---------------------------------------------------------------------------------------- 		
				// ->Success																																				
				if (DCreate.status == OK)
				{
					// Reset command and return to wait state												
					EXPL.CMD[SIDE].dir_create 	= 0;
					EXPL.CMD[SIDE].refresh 		= 1;
					step = STP_WAIT;
				}
				else if (DCreate.status != 65535) CreateError(DCreate.status, SIDE, "error creating directory", &EXPL);
				break;
			//**********************************************************************************************
			// Delete selected directory																	
			//**********************************************************************************************
			case STP_DIR_DELETE:
				// Show current state																		
				WorkingStatus(&EXPL, (UDINT)"deleting directory...");
		
				// ---------------------------------------------------------------------------------------- 		
				// Initialize directory delete structure													
				CreateCompletePath((void*)EXPL.PAR[SIDE].dir_path, (void*)EXPL.DAT[SIDE].item_list[EXPL.VIS[SIDE].item_selected], (UDINT)&tmp_str3);
				DDelete.enable	= 1;
				DDelete.pDevice = (UDINT)EXPL.PAR[SIDE].device_active;
				DDelete.pName 	= (UDINT)&tmp_str3;
				DirDeleteEx(&DDelete);
									
				// ---------------------------------------------------------------------------------------- 		
				// ->Success																																				
				if (DDelete.status == OK)
				{
					// Reset command and return to wait state												
					EXPL.CMD[SIDE].delete 	= 0;
					EXPL.CMD[SIDE].refresh = 1;
					step		= STP_WAIT;
				}
				else if (DDelete.status != 65535) CreateError(DDelete.status, SIDE, "error deleting directory", &EXPL);
				break;
		}
	}
}

//******************************************************************************************************
// Create complete path string																			
//******************************************************************************************************
void CreateCompletePath(STRING path[DIR_PATH_SIZE+MAX_ITEM_SIZE], STRING target[MAX_ITEM_SIZE], UDINT return_path)
{
	STRING 	tmp[MAX_ITEM_SIZE];
	brsmemset((UDINT)&tmp, 0, MAX_ITEM_SIZE);
	brsstrcpy((UDINT)return_path, (UDINT)path);
	// ------------------------------------------------------------------------------------------------ 		
	// Filter directory name																			
	if(brsmemcmp((UDINT)target, (UDINT)"(DIR)", 5) == 0)
		brsmemcpy((UDINT)tmp, (UDINT)(target+5), brsstrlen((UDINT)target)-5);
	else
		brsstrcpy((UDINT)tmp, (UDINT)target);
		
	// ------------------------------------------------------------------------------------------------ 		
	// Create directory path																			
	brsstrcat((UDINT)return_path, (UDINT)"\\"); 
	brsstrcat((UDINT)return_path, (UDINT)tmp);
}

//******************************************************************************************************
// Raise error function																					
//******************************************************************************************************
void CreateError(UINT nr, USINT SIDE, STRING txt[100], typMain_EXP *EXPL)
{
	if (nr == fiERR_NOT_ENOUGH_FREEMEM) brsstrcpy((UDINT)EXPL->ERR.txt, (UDINT)"not enough memory available on the target device");
	else if (nr == fiERR_FILE_DEVICE) 	brsstrcpy((UDINT)EXPL->ERR.txt, (UDINT)"device is not connected");
	else if (nr == fiERR_INVALID_PATH) 	brsstrcpy((UDINT)EXPL->ERR.txt, (UDINT)"directory is too long or has invalid characters");
	else if (nr == fiERR_DIR_NOT_EXIST) brsstrcpy((UDINT)EXPL->ERR.txt, (UDINT)"directory path dont exist");			
	else brsstrcpy((UDINT)EXPL->ERR.txt, (UDINT)txt);
	// Convert to error structure																		
	if (SIDE == 0) 	brsstrcat((UDINT)EXPL->ERR.txt, (UDINT)" on side a");
	else			brsstrcat((UDINT)EXPL->ERR.txt, (UDINT)" on side b");
	EXPL->ERR.nr   	= nr;
	EXPL->ERR.step 	= step;
	// Reset all commands 																				
	brsmemset((UDINT)&EXPL->CMD[SIDE], 0, sizeof(EXPL->CMD[SIDE]));
	brsmemset((UDINT)&EXPL->CMD[!SIDE], 0, sizeof(EXPL->CMD[!SIDE]));
	if (DClose.ident == 0) 	step = STP_WAIT;
	else					step = STP_READ_DIR_3;
}

//******************************************************************************************************
// Working status																						
//******************************************************************************************************
void WorkingStatus(typMain_EXP *EXPL, UDINT str)
{
	animation++;
	if (animation == 80) animation = 0;
	brsmemset((UDINT)EXPL->status, 0, sizeof(EXPL->status));
	brsstrcpy((UDINT)EXPL->status, (UDINT)str);
	switch(animation)
	{
		case 0 ... 19	: brsstrcat((UDINT)EXPL->status, (UDINT)"/"); break;
		case 20 ... 39	: brsstrcat((UDINT)EXPL->status, (UDINT)"-"); break;
		case 40 ... 59	: brsstrcat((UDINT)EXPL->status, (UDINT)"\\"); break;
		case 60 ... 79	: brsstrcat((UDINT)EXPL->status, (UDINT)"|"); break;
	}
}

//******************************************************************************************************
// Fill new folder or directory name																	
//******************************************************************************************************
void InsertRecName(typMain_EXP *EXPL, STRING new_name[MAX_ITEM_SIZE], STRING size[15], UINT SIDE)
{
	DINT 				lx		= 0;
	DINT 				ly		= 0;
	DINT  				lSort	= 0;

	// Set up start values for iteration																
	if (EXPL->DAT[SIDE].item_num != 0) ly = EXPL->DAT[SIDE].item_num - 1;
	lx = ly;
	// Start itteration	search																			
	while (ly > 1)
	{
		// Check current entry																			
		lSort = brsstrcmp((UDINT)new_name, (UDINT)EXPL->DAT[SIDE].item_list[ly]);
		// Solve new search range																		
		if (ly % 2 == 0) 	ly = ly / 2;
		else				ly = ly / 2 + 1;
		// New range is lower or higher than current													
		if (lSort > 0)
		{
			lx = lx + ly;
			if (lx > EXPL->DAT[SIDE].item_num) lx = EXPL->DAT[SIDE].item_num;  
		}
		else
		{
			lx = lx - ly;
			if (lx < 1) lx = 1;
		}		
	}
	// New entry is this, next or previous 																
	lSort = brsstrcmp((UDINT)new_name, (UDINT)EXPL->DAT[SIDE].item_list[lx]);
	if ((lSort > 0) && (lx != EXPL->DAT[SIDE].item_num)) lx++;
	else if (lx > 0)
	{
		lSort = brsstrcmp((UDINT)new_name, (UDINT)EXPL->DAT[SIDE].item_list[lx-1]);
		if (lSort < 0) lx--;
	}
	// Force ".." at beginning of list	 																
	if ((lx == 0) && (brsstrcmp((UDINT)"..", (UDINT)EXPL->DAT[SIDE].item_list)) == 0) lx++;
	// Move all data entrys backwards and fill in new entry												
	brsmemmove((UDINT)EXPL->DAT[SIDE].item_list[lx+1],(UDINT)EXPL->DAT[SIDE].item_list[lx], (EXPL->DAT[SIDE].item_num - lx) * (MAX_ITEM_SIZE + 1));
	brsstrcpy((UDINT)EXPL->DAT[SIDE].item_list[lx], (UDINT)new_name);

	// Create data structure for vis size listbox															
	brsmemmove((UDINT)EXPL->DAT[SIDE].item_size[lx+1],(UDINT)EXPL->DAT[SIDE].item_size[lx], (EXPL->DAT[SIDE].item_num - lx) * (15 + 1));
	brsstrcpy((UDINT)EXPL->DAT[SIDE].item_size[lx], (UDINT)size);
}

//******************************************************************************************************
// Select item																							
//******************************************************************************************************
void SelectItem(typMain_EXP *EXPL, USINT SOURCE)
{
	UINT x = 0;
	
	for(x=0;x<EXPL->DAT[!SOURCE].item_num;x++) if(brsstrcmp((UDINT)EXPL->DAT[SOURCE].item_list[EXPL->VIS[SOURCE].item_selected], (UDINT)EXPL->DAT[!SOURCE].item_list[x]) == 0) break;
	EXPL->VIS[!SOURCE].item_selected = x;
}

//******************************************************************************************************
// Is second string in first string																		
//******************************************************************************************************
BOOL IsInstr(STRING string1[MAX_ITEM_SIZE], STRING string2[MAX_ITEM_SIZE])
{
	UINT x = 0;
	
	if(brsstrlen((UDINT)string1)>brsstrlen((UDINT)string2))
	{
		for(x=0;x<=brsstrlen((UDINT)string1)-brsstrlen((UDINT)string2);x++) if(brsmemcmp((UDINT)string1 + x, (UDINT)string2, brsstrlen((UDINT)string2)) == 0) return 1;
	}
	return 0;
}


