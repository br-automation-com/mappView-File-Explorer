## Table of Contents
* [Introduction](#Introduction)
* [Requirements](#Requirements)
* [Revision History](#Revision-History)

<a name="Introduction"></a>
## Introduction
This is a sample project for a file Explorer with mappView. It allows you to delete and copy files or directories between two locations. Navigate through the folder structure by double tapping on a folder name. Access USB sticks and network shares and use them like local folders.

![](Logical/mappView/Resources/Media/screenshot_main.png)

See [**How to import the user management into an existing project.**](Logical/mappFileExplorer/HowToImport.pdf) Download the latest release from [**here.**](../../releases) When upgrading from a previous version make sure to delete the files that were imported before. Detailed information are available in the [**Wiki**](https://github.com/stephan1827/mappView-File-Explorer/wiki). This sample can run in simualtion mode (http://127.0.0.1:81/).

<a name="Requirements"></a>
## Requirements
* Automation Studio 4.5
* mappView 5.7.1
* Automation Runtime B4.53

Recommended task class is #8 with a 10ms cycle time.	

<a name="Revision-History"></a>
## Revision History

#### Version 1.7
- Fixed data start offset in upload was not correct
- Fixed upload file name can exceed EXPL_ITEM_LENGTH
- Fixed upload crashing CPU when it exceeds EXPL_UPLOAD_DOWNLOAD_SIZE

