@echo off
echo ==================================================
systeminfo | findstr /c:"OS Name"
systeminfo | findstr /c:"OS Version"
systeminfo | findstr /c:"System Type"
wmic diskdrive get name,model,size
ipconfig | findstr IPv4ipconfig
echo %PATH%
echo ==================================================