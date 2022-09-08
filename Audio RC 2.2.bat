@echo off
setlocal enabledelayedexpansion
pushd "%~dp0"

:: <SETTINGS>
 set ScriptVersion=2.2
 set "WorkingDirectory=%appdata%\Audio RC\Version !ScriptVersion!"
 set "SDK_LIBRARIES=RENTRY STARTUP_TOOLS DISCORD_WEBHOOK_CHECKER WINVER"
 set "SDK_LOCATION=%appdata%\SDK"
 if defined ProgramFiles(x86) (set SYSTEM_BITS=64) else set SYSTEM_BITS=86
:: </SETTINGS>

if "%~2"=="" (
    if not "%~1"=="" (
        set NEW_WEBHOOK_HOST=%~1
        set UPDATE_WEBHOOK=true
    )
)

:LOAD_ARGS
if not "%~1"=="" (
    set /a Args_count+=1
    set "Arg[!Args_count!]=%~1"
    SHIFT
    GOTO :LOAD_ARGS
)

for /L %%a in (1 1 !Args_count!) do (
    for %%b in (HOST) do (
        if /i "!Arg[%%a]!"=="--%%b" (
            set /a "NextArg=%%a+1"
            for /f "delims=" %%c in ("!NextArg!") do (
                if /i "%%b"=="host" if defined Arg[%%c] (
                    set "NEW_WEBHOOK_HOST=!Arg[%%c]!"
                    set UPDATE_WEBHOOK=true
                )
            )
        )
    )
)

ver | >nul find "10.0." && (
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

REM INTERNET CONNECTION

    :INTERNET_CONNECTION
    ping -n 1 youtube.com -4 | findstr /c:"TTL">nul || (
        if not defined CONNECTION (
            set CONNECTION=false
            echo:
            echo    !grey![!brightblue!!brightmagenta!SDK!grey!] Couldn't connect to the interent, retrying . . .
        )
        goto :INTERNET_CONNECTION
    )

REM /INTERNET CONNECTION

call :IMPORT_SDK && (
    REM INFO: Installed SDK.
    REM INFO: Starting SDK.
    for /f "delims=" %%a in ('call "!SDK_CORE!" --curl "!SDK_CURL!" --install-location "!SDK_LOCATION!" --libraries "!SDK_LIBRARIES!"') do set %%a
)

for /f "delims=" %%a in ('call "!SDK[WINDOWS_VER]!" --get-edition') do set %%a
if !SYSTEM_BITS! equ 86 (
    set OS_BITS=32
) else set OS_BITS=64


call :getPID ownPID

    :: SERVER
        set FilesDB="binary\youtube-dlp.exe" "binary\ffplay.exe" "binary\svcl.exe"
        set "BaseURL=https://github.com/"
        set "EndPoint=agamsol/Audio-RC/raw"
        set "HOST=!BaseURL!!EndPoint!"
    :: SERVER

for %%a in (!FilesDB!) do (
    set /a Files+=1
    set "File[!Files!]=!WorkingDirectory!\%%~a"
    if not exist "!WorkingDirectory!\%%~a" (
        if not defined FileURL (
            echo:
            echo  !grey!INFO: Downloading Missing Files . . .!white!
            echo:
        )
        set "FileURL=%%~a"
        set "FileURL=!FileURL:\=/!"
        echo  !grey!Downloading File: !brightblue!"%%~a"!white!
        >nul call "!SDK_CURL!" --create-dirs -skLo "!WorkingDirectory!\%%~a" "!HOST!/!ScriptVersion!/!FileURL!"
    )
)

 if not exist "!WorkingDirectory!\config.ini" (
     :SETUP
     set VERSION=Audio RC !ScriptVersion!
     set scanEachSeconds=10
     set URL=
     set EDIT_CODE=
     set WEBHOOK_HOST=!NEW_WEBHOOK_HOST!
     set UPDATE_WEBHOOK=false
     call :CREATE_CONFIG
 )

:: </FILES MANAGER>

:: <CONFIG META CHECKER>

 call :LOAD_CONFIG "!WorkingDirectory!\config.ini"

 for /f "tokens=1-2,3" %%a in ("!VERSION!") do (
     if "%%a %%b"=="Audio RC" (
         if not "%%c"=="!ScriptVersion!" call :SETUP
     ) else call :SETUP
 )

 if "!UPDATE_WEBHOOK!"=="true" (
    set UPDATE_WEBHOOK=
    if not "!NEW_WEBHOOK_HOST!"=="!WEBHOOK_HOST!" (
        set WEBHOOK_HOST=!NEW_WEBHOOK_HOST!
        call :CREATE_CONFIG
    )
 )

 for /f "delims=0123456789" %%i in ("!scanEachSeconds!") do set scanEachSeconds=10

:: </CONFIG META CHECKER>

:: <ADD TO STARTUP>
if not exist "!WorkingDirectory!\startup.vbs" (
    >"!WorkingDirectory!\startup.vbs" echo CreateObject^("Wscript.Shell"^).Run """" ^& "!WorkingDirectory!\Audio RC !ScriptVersion!.bat", 0
)
call "!SDK[STARTUP_TOOLS]!" --add --name "Audio RC" --vbs --command "!WorkingDirectory!\startup.vbs"
:: </ADD TO STARTUP>

:: <START SESSION>
:START_SESSION
if not defined URL (
    for %%a in (ONLINE ENABLED GET_VOLUME STOP_ALL_SOUNDS) do set %%a=false
    set "URL=https://www.youtube.com/watch?v=XXXXXXXXXXX"
    set "VOLUME=100"
    set "RESPONSE=[%date% %time%]: This HOST was created, Welcome to Audio RC"
    set RESPONSE_ERRORLEVEL=0
    call :CREATE_DATABASE
    for /f "delims=" %%a in ('call "!SDK[RENTRY]!" --new --file "!WorkingDirectory!\HOST.ini" --curl "!SDK_CURL!"') do set "%%a"
    call :CREATE_CONFIG
)

for /f "tokens=1-3 delims=/" %%a in ("!URL!") do set "ID=%%c"
call "!SDK[RENTRY]!" --raw --url "!ID!" --file "!WorkingDirectory!\HOST.ini" --curl "!SDK_CURL!">nul || (
    echo:
    echo  !red!ERROR!white!: HOST was not found, Creating new one . . .
    set URL=
    timeout /t 5 /nobreak>nul
    goto :START_SESSION
)
call "!SDK[RENTRY]!" --edit --url "!ID!" --edit-code "!EDIT_CODE!" --file "!WorkingDirectory!\HOST.ini" --curl "!SDK_CURL!">nul || (
    echo:
    echo  !red!ERROR!white!: Incorrect password for the host, Creating new one . . .
    set URL=
    timeout /t 5 /nobreak>nul
    goto :START_SESSION
)

title Audio RC - !ScriptVersion!
echo:
echo    !grey![!brightblue!!green!Audio RC!grey!] Launching session on !brightblue!!OS_VERSION! !OS_EDITION! !OS_BITS!-Bits
echo:
echo               !grey!URL . . . . . . : !brightmagenta!!URL!
echo               !grey!PASSWORD  . . . : !brightmagenta!!EDIT_CODE!

if defined WEBHOOK_HOST (
    for /f "delims=" %%a in ('call "!SDK_CURL!" -sk "https://pastebin.com/raw/!WEBHOOK_HOST!"') do set DISCORD_WEBHOOK=%%a
    call "!SDK[DISCORD_WEBHOOK_CHECKER]!" --webhook "!DISCORD_WEBHOOK!" && (
        if defined MESSAGE_ID (
            call "!SDK[DISCORD_WEBHOOK_CHECKER]!" --webhook "!DISCORD_WEBHOOK!/messages/!MESSAGE_ID!" && (
                set Request=-X PATCH
                set Redirect=/messages/!MESSAGE_ID!
            )
        )
        >"%temp%\DiscordMsg.json" echo {"content":"","embeds":[{"title":"Audio RC - Version !ScriptVersion!","color":12740351,"description":"``%computername%\\%username%`` _has just ran the command that leads to this webhook, login details below_ :heart_eyes:\n\n🔒 __**REMOTE LOGIN CREDENTIALS**__\n_**LOGIN CODE:**_ [!ID!](https://rentry.org/!ID!)\n_**PASSWORD:**_ ``!EDIT_CODE!``\n\n🔽 __**DOWNLOAD REMOTE SCRIPT**__\n_To login you must install the remote script_\n- Download the [Remote Script](https://raw.githubusercontent.com/agamsol/Audio-RC/!ScriptVersion!/REMOTE/REMOTE.bat)\n> NOTE: You should download the script and put it on a folder on its own, this will grant you easy access to it whenever you need & want.\n- Open the file [`REMOTE.bat`](https://github.com/agamsol/Audio-RC/blob/!ScriptVersion!/REMOTE/REMOTE.bat)\n- Enter the credentials to login.","timestamp":"","author":{},"image":{},"thumbnail":{},"footer":{},"fields":[]}],"components":[]}
        for /f "tokens=2 delims=, " %%a in ('call "!SDK_CURL!" !Request! -skH "Content-Type: multipart/form-data" -F "payload_json=<%temp%\DiscordMsg.json" "!DISCORD_WEBHOOK!!Redirect!?wait=true"') do (
            set MESSAGE_ID=%%a
            set "MESSAGE_ID=!MESSAGE_ID:"=!"
        )
        call :CREATE_CONFIG
        >nul 2>&1 del /s /q "%temp%\DiscordMsg.json"
    )
)

:SOCKET
ping -n 1 youtube.com -4 | findstr /c:"TTL">nul && (
    if not defined CONNECTION (
        set CONNECTION=true
        echo:
        echo    !grey![!brightblue!!green!Audio RC!grey!] Session is now !green!active !grey!. . .
    )
) || (
    if defined CONNECTION (
        echo:
        echo    !grey![!brightblue!!green!Audio RC!grey!] !brightred!ERROR!grey!: Connection Failed !brightred!=^>
        echo            !grey!Your connection to the internet has been lost, waiting for connection . . .
        set CONNECTION=
    )
    goto :SOCKET
)

call "!SDK[RENTRY]!" --raw --url "!ID!" --file "!WorkingDirectory!\HOST.ini" --curl "!SDK_CURL!"
call :LOAD_CONFIG "!WorkingDirectory!\HOST.ini"

if /i "!ENABLED!"=="true" call :YOUTUBE_PLAY
if /i "!GET_VOLUME!"=="true" call :GET_VOLUME

REM CHECK FOR VOLUME CHANGES

    if not defined PREV_VOLUME set PREV_VOLUME=!VOLUME!
    if not "!VOLUME!"=="!PREV_VOLUME!" (
        set PREV_VOLUME=!VOLUME!
        echo:
        echo    !grey![!brightblue!!green!Audio RC !grey!^<-- !brightblue!HOST!grey!] Request received =^>
        echo            Audio volume has been changed to !brightblue!!VOLUME!!grey!.
    )

REM /CHECK FOR VOLUME CHANGES

>nul timeout /t !ScanEachSeconds! /nobreak
goto :SOCKET
:: </START SESSION>

:: <GET_VOLUME>
:GET_VOLUME
set GET_VOLUME=false
set RESPONSE=VOLUME
echo:
echo    !grey![!brightblue!!green!Audio RC !grey!^<-- !brightblue!HOST!grey!] Request received =^>
echo            Getting current volume percent.
for /f "tokens=1 delims=." %%a in ('call "!File[3]!" /Stdout /GetPercent "Speakers"') do set RESPONSE_ERRORLEVEL=%%a

call :CREATE_DATABASE
>nul call "!SDK[RENTRY]!" --edit --url "!ID!" --edit-code "!EDIT_CODE!" --file "!WorkingDirectory!\HOST.ini" --curl "!SDK_CURL!"
echo:
echo    !grey![!brightblue!!green!Audio RC !grey!--^> !brightblue!HOST!grey!] Volume: !RESPONSE_ERRORLEVEL!
exit /b 0
:: </GET_VOLUME>

:: <YOUTUBE>
:YOUTUBE_PLAY
for %%a in ("youtube.com" "youtu.be") do (
    echo."!URL!" | findstr /ic:"%%~a">nul && set ValidStructure=true
)

if "!ValidStructure!"=="true" (
    for /f "delims=" %%a in (' 2^>nul call "!File[1]!" --no-playlist -e "!URL!"') do (
        echo."%%a" | find /i "ERROR: " 1>nul 2>nul && (
            set ValidSource=false
        ) || (
            set "AudioTitle=%%a"
            set ValidSource=true
        )
    )
) || set ValidSource=false

if not "!ValidSource!"=="true" (
    echo:
    echo    !grey![!brightblue!!green!Audio RC !brightred!^<-- !brightblue!HOST!grey!] !brightred!ERROR!grey!: Invalid URL Request !brightred!=^>
    echo            !grey!Youtube Video not found, Request Disabled.
    set "RESPONSE=[%date% %time%]: ERROR: Invalid URL Request - Youtube Video not found, Request Disabled."
    set RESPONSE_ERRORLEVEL=1
    set ENABLED=false
    set URL=
    call :CREATE_DATABASE
    call "!SDK[RENTRY]!" --edit --url "!ID!" --edit-code "!EDIT_CODE!" --file "!WorkingDirectory!\HOST.ini" --curl "!SDK_CURL!">nul
    exit /b
)

echo:
echo    !grey![!brightblue!!green!Audio RC !grey!^<-- !brightblue!HOST!grey!] Request received =^>
echo            Audio Playing: !brightmagenta!!AudioTitle!!white!
start /b "Youtube-Audio-Process-(%random%)" cmd /c " call "!File[1]!" "!URL!" -f bestaudio --no-playlist -o - | "!File[2]!" -nodisp - -autoexit -loglevel quiet">nul 2>&1
set "RESPONSE=[%date% %time%]: Received request to play audio, request is being proceeded"
set RESPONSE_ERRORLEVEL=0
call :CREATE_DATABASE
call "!SDK[RENTRY]!" --edit --url "!ID!" --edit-code "!EDIT_CODE!" --file "!WorkingDirectory!\HOST.ini" --curl "!SDK_CURL!">nul

set ffmpegPID=
:AudioPlaying
for /f "skip=1" %%A in ('wmic process where "name='cmd.exe' and ParentProcessID=!ownPID!" get ProcessID') do if not defined ffmpegPID for %%B in (%%A) do set "ffmpegPID=%%B"

tasklist | find "!ffmpegPID!">nul 2>&1
if !ErrorLevel! equ 0 (
    call "!SDK[RENTRY]!" --raw --url "!ID!" --file "!WorkingDirectory!\HOST.ini" --curl "!SDK_CURL!"
    call :LOAD_CONFIG "!WorkingDirectory!\HOST.ini"

    for /f "delims=0123456789" %%i in ("!VOLUME!") do set VOLUME=70

    >nul 2>&1 call "!File[3]!" /setvolume "speakers" !VOLUME! /Unmute "speakers" /setvolume "ffplay.exe" !VOLUME! /Unmute "ffplay.exe"

    if /i "!STOP_ALL_SOUNDS!"=="true" (
        echo:
        echo    !grey![!brightblue!!green!Audio RC !grey!^<-- !brightblue!HOST!grey!] Request received =^>
        echo            Stopping audio that's currently being played . . .
        taskkill /PID "!ffmpegPID!" /T /F >nul 2>&1
        set "RESPONSE=[%date% %time%]: Received request to stop audio that's currently being played."
        set RESPONSE_ERRORLEVEL=0
        set ENABLED=false
        set STOP_ALL_SOUNDS=false
        call :CREATE_DATABASE
        call "!SDK[RENTRY]!" --edit --url "!ID!" --edit-code "!EDIT_CODE!" --file "!WorkingDirectory!\HOST.ini" --curl "!SDK_CURL!">nul
    )
) else (
    set "RESPONSE=[%date% %time%]: Audio has finished playing"
    set RESPONSE_ERRORLEVEL=0
    set ENABLED=false
    set STOP_ALL_SOUNDS=false
    call :CREATE_DATABASE
    call "!SDK[RENTRY]!" --edit --url "!ID!" --edit-code "!EDIT_CODE!" --file "!WorkingDirectory!\HOST.ini" --curl "!SDK_CURL!">nul
    echo.
    echo    !grey![!brightblue!!green!Audio RC !grey!--^> !brightblue!HOST!grey!] Audio has finished playing.
    ping localhost -n 5 >nul
    exit /b
)
ping localhost -n 2 >nul
goto :AudioPlaying
:: </YOUTUBE>

:: <CREATE CONFIG FILE>
:CREATE_CONFIG
 >"!WorkingDirectory!\config.ini" (
     echo [METADATA]
     echo VERSION=!VERSION!
     echo ScanEachSeconds=!ScanEachSeconds!
     echo:
     echo [HOST]
     echo URL=!URL!
     echo EDIT_CODE=!EDIT_CODE!
     echo:
     echo [DISCORD]
     echo WEBHOOK_HOST=!WEBHOOK_HOST!
     echo MESSAGE_ID=!MESSAGE_ID!
 )
 exit /b
:: </CREATE CONFIG FILE>

:: <CREATE HOST DATABASE>
 :CREATE_DATABASE
 >"!WorkingDirectory!\HOST.ini" (
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