## Introduction
This is a sample project for a file Explorer with mappView. It allows you to copy and delete files between multiple locations.

![](Logical/mappView/Resources/Media/screenshot.png)

Also see [**How to import the user management into an existing project.**](Logical/mappFileExplorer/HowToImport.pdf) Download the latest release from [**here.**](../../releases)

## Requirements
* Automation Studio 4.5
* mappView 5.7.1
* Automation Runtime B4.53

Recommended task class is #8 with a 10ms cycle time.

## Description
The sample consists of two tasks and a mappView sample page. The task FileExplorer handles the majority of all functions and a helper task USBdevice. The USBdevice tasks auto detects connected USB sticks and automatically mounts these so they can be accessed from the FileExploer. The sample page shows all available functions and can be used as a starting point. The following functions are currently supported.

* Copy one or all files or folders
* Delete one or all files or folders
* Create a new folder

The task and mappView visualization use an interface to communicate that can also be used to trigger functions external. Since there are two sides in the file explorer most data exists twice. The structure looks as follows:

	EXPL
	* CMD		Used to trigger commands like copy, delete, create, ... A command is triggered by setting it to true, when the command is finished the task will reset the command. This indicates that the command is finished. Do not change any parameters or set another command until the previous command is finished. 
	  * refresh 	Read files and folder information
	  * dir_change 	Change to the folder name stored in PAR->dir_name
	  * dir_create 	Create new folder
	  * copy 	Copy selected file or folder
	  * copyall 	Copy all files and folders
	  * delete 	Delete file or folder
	* PAR 			Parameters
	  * device_active 	The device name that is currently used, see constant definition below
	  * device_list 	List of all available devices name that can be used, see constant definition below
	  * item_filter 	Only files and folders that fit this pattern will be listed
	  * UserRole 		The user role used with the assign and remove command
	  * dir_name 		Folder name used with the command dir_create
	  * dir_path 		Complete folder path 
	* DAT		File and folder information
	  * item_list	List of files and folders
	  * item_size	File size
	  * item_num	Number of files and folders
	  * UserActive	This is the user that is currently logged in
	* VIS				Data specific for the visualization
	  * item_selected		File or folder that is selected in mappView
	  * enable_copy_delete		Enables/Disables the buttons to copy or delete a file
	  * enable_refresh_create	Enables/Disables the buttons to create or refreash a folder
	  * double_click_dir_change	Helper variable to detect double click on itelm list
	  * device_list			Same information as PAR->device_list but formated for mappView  
	* ERR		Information about errors
	  * txt		Error text
	  * nr		Error number
	  * step	State where the error occured

## Configuration
The sample can be configured through the following constants located in mappFileExplorer->ExplorerVariables.var

	DIR_PATH_SIZE 	Maximum length for the complete path
	ITEM_LIST_NUM 	Maximum number if files and folders that can be listed
	MAX_ITEM_SIZE 	Maximum length for a file or folder name
	DEVICE_LIST   	List if predefined devices

## Limitations
* The sample is not yet multi client capable.
* There is no extra message box when files or folders are deleted.

## Revision History

#### Version 0.1
First public release
