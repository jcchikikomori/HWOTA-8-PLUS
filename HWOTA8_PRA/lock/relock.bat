@echo off

set ROOTPATH=%~dp0
set SHELLPATH="%~dp0../cygwin"

cd %SHELLPATH%
call shell.bat %ROOTPATH%/relock.sh %ROOTPATH%

