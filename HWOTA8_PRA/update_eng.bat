@echo off

color 17

set ROOTPATH=%~dp0
set SHELLPATH="%~dp0cygwin"
set "cocolor=%ROOTPATH%\tools\Windows\cocolor.exe"

:MAINMENU
CLS
ECHO.
%CoColor% 1E "=================================================="
%CoColor% 1A "         1: Will be repack firmware files?"
%CoColor% 1D "         2: The firmware files are already repacked"
%CoColor% 1E "==================================================" 1B
ECHO.
set /p input=Select:
if '%input%'=='1' goto Repack
if '%input%'=='2' goto Next
goto MAINMENU

:Repack
CLS
cd %ROOTPATH%\update
rename update_data_full_public.zip update_data_public.zip
rename update_full_*.zip update_all_hw.zip
call repack.bat
cd %ROOTPATH%

:Next
CLS
cd %SHELLPATH%
call shell.bat %ROOTPATH%hwota_eng.sh %ROOTPATH%


:Menulock
CLS
ECHO.
%CoColor% 1E "=================================================="
%CoColor% 1B "      Would you lock the bootloader?
%CoColor% 1A "      1: Yes, I would (status of relock)"
%CoColor% 1D "      2: No, I would not"
%CoColor% 1E "==================================================" 1B
ECHO.
set /p input=Select:
if '%input%'=='1' goto lock
if '%input%'=='2' exit
goto Menulock

:lock
%CoColor% 1D
CLS
cd %SHELLPATH%
call shell.bat %ROOTPATH%relock_eng.sh %ROOTPATH%
cd %ROOTPATH%
TIMEOUT /T 5
