By default, MyDBFStudio requires the DBFLaz package which belongs to FPC.
The program was tested with FPC 3.2.0.

However, some bugs were detected in this package. In order to be able to fix
their effect on MyDBFStudio before the release of a new FPC version it is 
possible to copy the DBF sources from their FPC-trunk directory 
(packages/fcl-db/src/dbase/) to this third-party folder. When the 
DBFLaz package is removed from the project's package requirements, and the path 
to the new location of the dbf sources is added to the "Other unit files" in the
project options, the new sources will be used rather than those of the 
DBFLaz package.

Conversely, the original situation can be restored by deleting the "Other unit
files" entry and adding package DBFLaz to the project requirements again.

Note that a "Clean up and Build" is required to remove the compiled dbf units.
