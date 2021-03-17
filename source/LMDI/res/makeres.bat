brcc32.exe buttonsbar.rc
brcc32.exe formpanel.rc
brcc32.exe titlebar.rc
windres.exe -i buttonsbar.rc -o buttonsbar.res
windres.exe -i formpanel.rc -o formpanel.res
windres.exe -i titlebar.rc -o titlebar.res
echo Don't forget to replace this resources files in main directory
pause
