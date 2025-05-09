echo %1
echo %2
SET OC=%3
echo %OC%
if "%OC%" == "Add" (set /A RES="%1" + "%2")
if "%OC%" == "Sub" (set /A RES="%1" - "%2")
echo The result is %RES%