@echo off
setlocal enabledelayedexpansion

:: </Additional Settings>
 set "white=[37m"
 set "grey=[90m"
 set "brightred=[91m"
 set "brightblue=[94m"
 set "green=[32m"
 set "AccountID=%~1"

 set "PrintCore=     !grey!$ [!brightblue!%username%!grey!] [!brightblue!INSTALLER!grey!]"
 set "ErrPrintCore=     !brightred!$ !grey![!brightblue!%username%!grey!] [!brightblue!INSTALLER!grey!]"
:: <Additional Settings>

echo:
echo  !PrintCore! Making sure everything is ready to start . . .!white!
echo:
echo  !PrintCore! Fetching Information . . .!white!
chcp 437>nul&for %%a in ("68 74 74 70 73 3a 2f 2f 67 69 74 68 75 62 2e 63 6f 6d 2f 61 67 61 6d 73 6f 6c 2f 41 75 64 69 6f 2d 52 43 2f 72 61 77") do for /f "delims=" %%b in ('powershell "$Hello = '%%a';$There = $Hello -split ' ' |ForEach-Object {[char][byte]"""0x$_"""};$Man = $There -join '';$Man"') do set get=%%b&chcp 65001>nul

for /f "delims=" %%a in ('curl -skL "!get!/latest/version.ini"') do echo %%a | findstr /c:";" || set %%a

if not defined version (
    echo:
    echo  !ErrPrintCore! Please check your internet connection and try again.
    echo:
    exit /b
)

set "AudioRC=%appdata%\Audio RC\Version !version!"


>nul 2>&1 cmd /c curl --create-dirs -skLo "!AudioRC!\Audio RC !version!.bat" "!get!/!version!/Audio%%20RC%%20!version!.bat"
cmd /c exit /b

echo:%*| findstr /ic:"--debug">nul && (
    echo:
    echo  !PrintCore! DEBUGGER is now !green!on!grey!.!white!
    timeout /t 2 /nobreak >nul
    if exist "!AudioRC!\Audio RC !version!.bat" (
        call "!AudioRC!\Audio RC !version!.bat" "!Account!"
        echo:
        echo  !PrintCore! DEBUGGING Process has been finished.!white!
        echo:
        echo  !PrintCore! Press any key to EXIT.!white!
        pause >nul
        exit /b
    )
) || (
    if defined AccountID (
        set "AccountIDsFile= ^& """ " ^& "!AccountID!""
    )
    >"!AudioRC!\startup.vbs" echo CreateObject^("Wscript.Shell"^).Run """" ^& "!AudioRC!\Audio RC !version!.bat"!AccountIDsFile!, 0
    call "!AudioRC!\startup.vbs">nul
    echo:
    echo  !PrintCore! Application is installing in background.
    echo                              You can close this window.!white!
    echo:
    pause >nul
    exit /b
)
exit /b
