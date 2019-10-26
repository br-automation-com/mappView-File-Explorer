## Table of Contents
* [Introduction](#Introduction)
* [Requirements](#Requirements)
* [Revision History](#Revision-History)

<a name="Introduction"></a>
## Introduction
This is a sample project for a file Explorer with mappView. It allows you to delete and copy files or directories between two locations. Navigate through the folder structure by double tapping on a folder name. Access USB sticks and network shares and use them like local folders.

![](Logical/mappView/Resources/Media/screenshot_main.png)

See [**How to import the user management into an existing project.**](Logical/mappFileExplorer/HowToImport.pdf) Download the latest release from [**here.**](../../releases) When upgrading from a previous version make sure to delete the files that were imported before. Detailed information are available in the [**Wiki**](https://github.com/stephan1827/mappView-File-Explorer/wiki).

<a name="Requirements"></a>
## Requirements
* Automation Studio 4.5
* mappView 5.7.1
* Automation Runtime B4.53

Recommended task class is #8 with a 10ms cycle time.	

<a name="Revision-History"></a>
## Revision History

#### Version 0.6
- Changed upper limit of USB polling interval
- Removed obsolete error numbers
- Replaced error numbers with constants
- Removed obsolete variables
- Fixed old_filter variable size
- Fixed file size added to file name
- Disable file device and filter during operation

