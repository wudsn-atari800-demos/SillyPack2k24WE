echo off
cd /D "%~dp0"
pushd atr\files
for /f tokens^=10*delims^=\ %%i in ('DIR .\*.xex /S/B ') do call :print %%j
popd
pause
goto :eof

:print
set str=%1
call set str=%%str:.xex=%%
call set str=%%str:\=:%%
@echo=%str%
