@REM Windows Start Script for Altirra
@ECHO OFF
setlocal
set RELEASE=SillyPack2k24WE
if exist Altirra\Altirra.exe goto :demo
ECHO Unpack the contents of the archive to a folder and run %RELEASE%.bat from there.
pause
goto :EOF

:demo
if not exist Altirra\ATARIXL.ROM curl "http://ftp.pigwa.net/stuff/collections/nir_dary_cds/Emulators/pcxformer%%203.60/ATARIXL.ROM" --output Altirra\ATARIXL.ROM

copy /Y Altirra\Altirra-Original.ini Altirra\Altirra.ini
echo 
start Altirra\Altirra.exe /portable /f /disk:%RELEASE%.atr

exit
