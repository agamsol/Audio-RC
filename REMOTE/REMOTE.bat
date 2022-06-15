@echo off
setlocal enableDelayedExpansion
pushd "%~dp0"

 set ScriptVersion=2.1
 set "WorkingDirectory=%appdata%\Audio RC\Version !ScriptVersion!\REMOTE"
 if defined ProgramFiles(x86) (set SYSTEM_BITS=64) else set SYSTEM_BITS=86
 set "SDK_LOCATION=%appdata%\SDK"
 title Audio RC v!ScriptVersion! - REMOTE

 if not exist "!WorkingDirectory!" md "!WorkingDirectory!"

call :IMPORT_SDK && (
    REM INFO: Installed SDK.
    REM INFO: Starting SDK.
    for /f "delims=" %%a in ('call "!SDK_CORE!" --curl "!SDK_CURL!" --install-location "!SDK_LOCATION!" --libraries "RENTRY"') do set %%a
)

if "%~1"=="--PauseAudio" (
    mode 50,10
    title Click To Stop Audio
    call :LOAD_CONFIG "!WorkingDirectory!\config.ini"
    if /i "!colors!"=="true" (
        set "grey=[90m"
        set "brightred=[91m"
    )
    call "!SDK[RENTRY]!" --raw --url "%~2" --file "!WorkingDirectory!\HOST-!ID!-SOCKET-2.ini"
    call :LOAD_CONFIG "!WorkingDirectory!\HOST-!ID!-SOCKET-2.ini"
    if /i "!colors!"=="true" (
        set "grey=[90m"
        set "brightred=[91m"
    )
    echo:
    echo  !grey!Press any key to !brightred!stop !grey!the audio.
    echo:
    pause >nul
    set STOP_ALL_SOUNDS=true
    set "ID=%~2"
    call :CREATE_DATABASE "!WorkingDirectory!\HOST-!ID!-SOCKET-2.ini"
    >nul call "!SDK[RENTRY]!" --edit --url "%~2" --edit-code "%~3" --file "!WorkingDirectory!\HOST-!ID!-SOCKET-2.ini"
    echo  !grey!Stopping any audio from playing.
    timeout /t 100 /nobreak>nul
    exit
)
mode 80,30

call :getPID ownPID
if not exist "!WorkingDirectory!\config.ini" (
    :LOGIN
    cls
    echo:
    echo  !grey!Please provide the ID of the HOST
    echo          Should be like this: !brightred!https://rentry.org/!green!XXXXX !grey!^(!brightblue!The XXXXX part is what you need!grey!^)
    echo:
    set /p "ID=!brightmagenta!--> "

    echo:
    echo  !grey!Please provide the HOST's Password.
    echo:
    set /p "EDIT_CODE=!brightmagenta!--> "

    >"!WorkingDirectory!\config.ini" (
        echo [LOGIN]
        echo ID=!ID!
        echo EDIT_CODE=!EDIT_CODE!
        echo:
        echo [OTHER]
        echo COLORS=true
        echo DefaultTimeout=100
    )
)

call :LOAD_CONFIG "!WorkingDirectory!\config.ini"

if /i "!colors!"=="true" (
    set "red=[31m"
    set "yellow=[33m"
    set "white=[37m"
    set "grey=[90m"
    set "brightred=[91m"
    set "brightblue=[94m"
    set "green=[32m"
    set "underline=[4m"
    set "underlineoff=[24m"
    set "brightmagenta=[95m"
)

call "!SDK[RENTRY]!" --raw --url "!ID!" --file "!WorkingDirectory!\HOST-!ID!.ini">nul || (
    echo:
    echo  !brightred!ERROR!grey!: HOST was not found, Please try again . . .
    timeout /t 5 /nobreak>nul
    goto :LOGIN
)
call "!SDK[RENTRY]!" --edit --url "!ID!" --edit-code "!EDIT_CODE!" --file "!WorkingDirectory!\HOST-!ID!.ini">nul || (
    echo:
    echo  !brightred!ERROR!grey!: Incorrect password for the host, Please try again . . .
    timeout /t 5 /nobreak>nul
    goto :LOGIN
)

:HOME_MENU
call "!SDK[RENTRY]!" --raw --url "!ID!" --file "!WorkingDirectory!\HOST-!ID!.ini"
call :LOAD_CONFIG "!WorkingDirectory!\HOST-!ID!.ini"
cls
echo:
echo   !green!You !grey!are connected to HOST - !brightblue!!ID!!grey!.
echo:
echo   !grey!1. !white!Play Audio From Youtube
echo:
echo   !grey!2. !white!Set Remote Volume
echo:
echo   !grey!3. !white!Logout from this HOST
echo:
set /p "user_main_selection=!brightmagenta!--> "
if !user_main_selection! equ 1 goto :PROVIDE_URL
if !user_main_selection! equ 2 goto :VOLUME
if !user_main_selection! equ 3 goto :LOGIN
goto :HOME_MENU

:VOLUME
set info=
set RESPONSE=
set RESPONSE_ERRORLEVEL=0
set GET_VOLUME=true
call :CREATE_DATABASE "!WorkingDirectory!\HOST-!ID!.ini"
>nul call "!SDK[RENTRY]!" --edit --url "!ID!" --edit-code "!EDIT_CODE!" --file "!WorkingDirectory!\HOST-!ID!.ini"
:VOLUME_GET_RESPONSE
if not defined info (
    echo:
    echo   !grey!Collecting necessary information . . .
    set info=1
)
call "!SDK[RENTRY]!" --raw --url "!ID!" --file "!WorkingDirectory!\HOST-!ID!.ini"
call :LOAD_CONFIG "!WorkingDirectory!\HOST-!ID!.ini"
timeout /t 2 /nobreak >nul
if "!RESPONSE!"=="VOLUME" (set Current_Volume=!RESPONSE_ERRORLEVEL!) else goto :VOLUME_GET_RESPONSE
:ASK_VOLUME
cls
echo:
echo   !grey!Current Volume: !brightblue!!Current_Volume!
echo:
echo   !grey!Please select a new volume amount ^(!brightblue!0!grey!\!brightblue!100!grey!^)
echo:
echo   !grey!TYPE "!brightblue!BACK!grey!" to return to home page.
echo:
set /p "VOLUME=!brightmagenta!--> "
if /i "!VOLUME!"=="back" goto :HOME_MENU
for /f "delims=0123456789" %%i in ("!VOLUME!") do goto :ASK_VOLUME
if !volume! lss 0 goto :ASK_VOLUME
if !volume! gtr 100 goto :ASK_VOLUME
call :CREATE_DATABASE "!WorkingDirectory!\HOST-!ID!.ini"
>nul call "!SDK[RENTRY]!" --edit --url "!ID!" --edit-code "!EDIT_CODE!" --file "!WorkingDirectory!\HOST-!ID!.ini"
echo:
echo    !grey!Volume has been set to '!brightblue!!VOLUME!!grey!'
>nul timeout /t 3 /nobreak
goto :HOME_MENU

:PROVIDE_URL
cls
echo:
echo   !grey!Please Provide Youtube URL to play . . .
echo:
echo   !grey!TYPE "!brightblue!BACK!grey!" to return to home page.
echo:
set /p "URL=!brightmagenta!--> "
if /i "!URL!"=="back" goto :HOME_MENU
set ValidStructure=false
for %%a in ("youtube.com" "youtu.be") do (
   echo."!URL!" | findstr /ic:"%%~a">nul && set ValidStructure=true
)
if "!ValidStructure!"=="false" (
    echo:
    echo  !brightred!ERROR!grey!: It seems that the URL you provided does not have the correct regex.
    echo:
    timeout /t 3 /nobreak>nul
    goto :PROVIDE_URL
)

set RESPONSE=
set RESPONSE_ERRORLEVEL=0
set STOP_ALL_SOUNDS=false
set ENABLED=true
call :CREATE_DATABASE "!WorkingDirectory!\HOST-!ID!.ini"
>nul call "!SDK[RENTRY]!" --edit --url "!ID!" --edit-code "!EDIT_CODE!" --file "!WorkingDirectory!\HOST-!ID!.ini"
echo:
echo    !grey![!brightblue!HOST !grey!^<-- !brightblue!!green!REMOTE!grey!] Request Sent =^>
echo           Asking !brightblue!HOST !grey!to play audio, waiting for !brightblue!Audio RC's !grey!response.
set Received=false
:API_RESPOND_TO_PLAY_AUDIO
call "!SDK[RENTRY]!" --raw --url "!ID!" --file "!WorkingDirectory!\HOST-!ID!.ini"
call :LOAD_CONFIG "!WorkingDirectory!\HOST-!ID!.ini"
if not "!Received!"=="true" (
    echo !RESPONSE! | findstr /c:"Received request to play audio, request is being proceeded">nul && (
        set Received=true
        echo:
        echo    !grey![!brightblue!HOST !grey!--^> !brightblue!!green!REMOTE!grey!] Response received =^>
        echo           Audio is now being played . . .
        echo:
    )
)
if "!Received!"=="true" (
        tasklist | findstr /c:"!StopMusicWindowPID!">nul 2>&1 || (
        start "" cmd /k ""%~f0" "--PauseAudio" "!ID!" "!EDIT_CODE!""
        set StopMusicWindowPID=
        for /f "skip=1" %%a in ('wmic process where "name='cmd.exe' and ParentProcessID=!ownPID!" get ProcessID') do if not defined StopMusicWindowPID for %%b in (%%a) do set "StopMusicWindowPID=%%b"
    )
) else (
    set /a ResponseTimeout+=1
    if !ResponseTimeout! equ !DefaultTimeout! (
        set /a DefaultTimeout+=100
        echo:
        echo    !grey![!green!REMOTE!grey!] !yellow!WARNING: !brightblue!Audio RC !grey!didn't respond for quite long time . . .
        echo          !grey!Make sure that the other side is not !brightred!OFFLINE !grey!or keep waiting.
        echo:
    )
)
if !RESPONSE_ERRORLEVEL! equ 1 (
    echo !RESPONSE! | findstr /c:"ERROR: Invalid URL Request - Youtube Video not found, Request Disabled.">nul && (
        echo:
        echo    !grey![!brightblue!HOST !grey!--^> !brightblue!!green!REMOTE!grey!] Response received !brightred!=^>
        echo           !grey!Youtube Video not found, Request ignored.
        echo:
        timeout /t 5 /nobreak>nul
        goto :PROVIDE_URL
    )
)
echo !RESPONSE! | findstr /c:"Audio has finished playing">nul && (
    taskkill /f /T /PID !StopMusicWindowPID!>NUL 2>&1
    echo    !grey![!brightblue!HOST !grey!--^> !brightblue!!green!REMOTE!grey!] Response received =^>
    echo           Audio has finished playing.
    echo:
    timeout /t 5 /nobreak>nul
    goto :PROVIDE_URL
)
goto :API_RESPOND_TO_PLAY_AUDIO

:: <CREATE HOST DATABASE>
 :CREATE_DATABASE [SAVE]
 >"%~1" (
     echo ```ini
     echo [YouTube]
     echo URL=!URL!
     echo ENABLED=!ENABLED!
     echo:
     echo [GET_VOLUME]
     echo GET_VOLUME=!GET_VOLUME!
     echo:
     echo [WHILE_PLAYING]
     echo STOP_ALL_SOUNDS=!STOP_ALL_SOUNDS!
     echo VOLUME=!VOLUME!
     echo:
     echo [API]
     echo RESPONSE=!RESPONSE!
     echo RESPONSE_ERRORLEVEL=!RESPONSE_ERRORLEVEL!
     echo ```
 )
 exit /b
:: </CREATE HOST DATABASE>

:: <Load INI Files>
:LOAD_CONFIG [FILE] [(PREFIX)]
if exist "%~1" (
    for /f "tokens=* eol=`" %%a in ('type "%~1"') do <nul set /p="%%a" | >nul findstr /rc:"^[\[#].*" || set "%~2%%a"
) else exit /b 1
exit /b 0
:: </Load INI Files>

:getPID  [RtnVar]
setlocal disableDelayedExpansion
:getLock
set "lock=%temp%\%~nx0.%time::=.%.lock"
set "uid=%lock:\=:b%"
set "uid=%uid:,=:c%"
set "uid=%uid:'=:q%"
set "uid=%uid:_=:u%"
setlocal enableDelayedExpansion
set "uid=!uid:%%=:p!"
endlocal & set "uid=%uid%"
2>nul ( 9>"%lock%" (
  for /f "skip=1" %%A in (
    'wmic process where "name='cmd.exe' and CommandLine like '%%<%uid%>%%'" get ParentProcessID'
  ) do for %%B in (%%A) do set "PID=%%B"
  (call )
))||goto :getLock
del "%lock%" 2>nul
endlocal & if "%~1" equ "" (echo(%PID%) else set "%~1=%PID%"
exit /b

:: <IMPORT SDK>
:IMPORT_SDK
set SDK_CURL=
if not exist "!SDK_LOCATION!" md "!SDK_LOCATION!"
for /f "delims=" %%a in ('2^>nul where curl.exe ^|^| echo 1') do (
    if %%a neq 1 (
        call :VALIDATE_CURL_INSTALLATION "%%a" && set "SDK_CURL=%%a"
    ) else (
        if exist "!SDK_LOCATION!\curl.exe" call :VALIDATE_CURL_INSTALLATION "!SDK_LOCATION!\curl.exe" && set "SDK_CURL=!SDK_LOCATION!\curl.exe"
    )
)
if not defined SDK_CURL call :IMPORT_CURL || exit /b 1

set "SDK_CORE=%SDK_LOCATION%\SDK.bat"

if not exist "!SDK_CORE!" call "!SDK_CURL!" -L#sko "!SDK_CORE!" "https://raw.githubusercontent.com/agamsol/SDK/latest/SDK.bat"
exit /b 0
:: </IMPORT SDK>

:: <IMPORT CURL>
:IMPORT_CURL
for /f "delims=" %%a in ("https://github.com/agamsol/SDK/raw/latest/curl/x!SYSTEM_BITS!/curl.exe") do (
    set "SDK_CURL=!SDK_LOCATION!\curl.exe"
    >nul chcp 437
    >nul 2>&1 powershell /? && (
        >nul 2>&1 powershell $progressPreference = 'silentlyContinue'; Invoke-WebRequest -Uri "'%%~a'" -OutFile "'!SDK_CURL!'"
        >nul chcp 65001
        call :VALIDATE_CURL_INSTALLATION "!SDK_CURL!" && exit /b 0
    )
    >nul chcp 65001
    >nul bitsadmin /transfer someDownload /download /priority high "%%~a" "!SDK_CURL!"
    call :VALIDATE_CURL_INSTALLATION "!SDK_CURL!" && exit /b 0
    >nul certutil -urlcache -split -f "%%~a" "!SDK_CURL!"
    call :VALIDATE_CURL_INSTALLATION "!SDK_CURL!" && exit /b 0
)
exit /b 1

:VALIDATE_CURL_INSTALLATION "[CURL]"
if not exist "%~1" exit /b 1
call "%~1" --version | findstr /brc:"curl [0-9]*\.[0-9]*\.[0-9]*">nul || (
    >nul 2>&1 del /s /q "%~1"
    exit /b 1
)
exit /b 0
:: </IMPORT CURL>