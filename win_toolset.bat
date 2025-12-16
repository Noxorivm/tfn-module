@echo off

set USERDIR=C:\Users\lideo\Desktop\backup-servidor.tar\home\nwn-server\the-frozen-north

echo Usando userdirectory: %USERDIR%
echo.

set DefaultSteamPath=C:\Program Files (x86)\Steam\steamapps\common\Neverwinter Nights\bin\win32\nwtoolset.exe
if exist "%DefaultSteamPath%" (
    echo Encontrado Toolset Steam: "%DefaultSteamPath%"
    START "" "%DefaultSteamPath%" -userdirectory "%USERDIR%"
    exit
)

set DefaultGogPath=C:\Program Files (x86)\GOG Galaxy\Games\Neverwinter Nights Enhanced Edition\bin\win32\nwtoolset.exe
if exist "%DefaultGogPath%" (
    echo Encontrado Toolset GOG: "%DefaultGogPath%"
    START "" "%DefaultGogPath%" -userdirectory "%USERDIR%"
    exit
)

set DefaultBeamdogPath=C:\Users\%USERNAME%\Beamdog Library\00785\bin\win32\nwtoolset.exe
if exist "%DefaultBeamdogPath%" (
    echo Encontrado Toolset Beamdog: "%DefaultBeamdogPath%"
    START "" "%DefaultBeamdogPath%" -userdirectory "%USERDIR%"
    exit
)

echo No se ha encontrado ninguna instalación del Aurora Toolset.
pause
