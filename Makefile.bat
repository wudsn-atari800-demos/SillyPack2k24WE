@rem Run via launch configuration from within WUDSN IDE to see the full logs.
@echo off
cd %~dp0
call Make-Settings.bat
IF ERRORLEVEL 1 goto :dir_error

cd %BASE_DIR%
IF ERRORLEVEL 1 goto :dir_error

echo Starting build in %BASE_DIR%.
rem Check menu structure
call :check

rem Clean and copy fixes first
call Make-Fixes.bat

rem Make main file
call :make AUTORUN.AR0

echo Creating disk image.
set ATR=%RELEASE%.atr
atr\hias\dir2atr.exe -d -m -b MyDos4534 %ATR% atr\files 2>%TEMP%\dir2atr.log
if ERRORLEVEL 1 goto :dir2atr_error
echo Done.

rem Remove potential dump files.
set DUMP=site\%RELEASE%\Altirra\AltirraCrash.mdmp
if exist %DUMP% del /Q %DUMP%

if NOT X%1==XSTART goto :eof
copy %ATR% site\%RELEASE%\%ATR%
cd site\%RELEASE%\
call %RELEASE%.bat
goto :eof

:make
cd asm
echo Compiling menu.
set EXECUTABLE=..\atr\files\%1
if exist %EXECUTABLE% del %EXECUTABLE% 
%MADS% -s SillyMenu.asm -o:SillyMenu.xex %2 %3
if ERRORLEVEL 1 goto :mads_error
echo Packing menu.
%EXOMIZER% sfx $2000 SillyMenu.xex -t 168 -o SillyMenu-Packed.xex -q
echo Compiling loader.
%MADS% -s SillyMenu-Loader.asm -l -o:%EXECUTABLE% %2 %3
if ERRORLEVEL 1 goto :mads_error
dir SillyMenu.xex %EXECUTABLE% | findstr .xex
cd ..
goto :eof

:dir_error
echo ERROR: Invalid working directory.
pause
exit

:mads_error
echo ERROR: MADS compilation errors occurred. Check error messages above.
exit

:dir2atr_error
type %TEMP%\dir2atr.log
echo ERROR: DIR2ATR errors occurred. Check error messages above.
exit

:check
echo off
set ALL_MENU_FILES=%TEMP%\SillyMenu-Entries-Files.txt
set ALL_MENU_TEXTS=%TEMP%\SillyMenu-Entries-Texts.txt
set ALL_EXISTING_FILES=%TEMP%\SillyMenu-Entries-All-Files.txt
copy menu\SillyMenu-Entries-Files.txt %ALL_MENU_FILES% >NUL
cd atr\files

C:\jac\bin\wbin\find.exe . -iname *.xex | C:\jac\bin\wbin\sed.exe "s/\.\\//g;s/\\/:/g;s/\.xex//g;" >%ALL_EXISTING_FILES%
sort %ALL_MENU_FILES% /O %ALL_MENU_FILES%

echo Writing menu texts to %ALL_MENU_TEXTS%.
echo ===================================== >%ALL_MENU_TEXTS%
for /f "tokens=*" %%f IN ('C:\jac\bin\wbin\find.exe . -iname *.txt') DO (
  echo "%%f" >>%ALL_MENU_TEXTS%
  type "%%f" >>%ALL_MENU_TEXTS%
  echo ===================================== >>%ALL_MENU_TEXTS%
)
rem type %ALL_MENU_TEXTS%

cd ..\..
echo Checking differences between %ALL_EXISTING_FILES% and %ALL_MENU_FILES%.
C:\jac\bin\wbin\diff.exe %ALL_EXISTING_FILES% %ALL_MENU_FILES%
goto :eof
