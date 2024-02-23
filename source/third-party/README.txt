By default, MyDBFStudio requires the DBFLaz package which belongs to FPC.
The program initially was tested with FPC 3.2.0 and 3.2.2.

Normally the dbf package DbfLaz built in to the Lazarus IDE would be used. 
But in order to have some flexibility in testing and buf fixing DbfLaz was 
removed from the project's requirements, and the TDbf files from FPC v3.2.2
(packages/fcl-db/src/dbase/) were copied to a this "third-party" subdirectory of 
the source folder (tdbf_fpc_322). 
As alternative TDbf source, the code from https://sourceforge.net/p/tdbf/code/HEAD/tree/trunk/
was copied to subfolder tdbf_svn. 

By adapting the "Other unit files" in the project options one of these tdbf 
source versions can be compiled into the application.

The normal build modes of the project work with the fpc_322 version, but 
build modes "Debug (based on TDbf from sourceforge)" and "Release (based on TDbf
from sourceforge)" use the alternative code in the tdbf_svn folder.
