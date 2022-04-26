@echo off
setlocal enabledelayedexpansion
pushd "%~dp0"

:: <SETTINGS>
 set Version=2.0
 set "MainDirectory=%appdata%\Audio RC\Version !version!"
 set "AllConfigJsonKeys=METADATA colors scanEachSeconds HOST.URL HOST.EDIT_CODE  PATHS.curl"
 set "AllHOSTJsonKeys=YOUTUBE.URL YOUTUBE.ENABLED STOP_ALL_SOUNDS API.response API.errorlevel"
:: </SETTINGS>

:: <GITHUB SETTINGS>
 set BaseURL=https://github.com/
 set Repository=agamsol/Audio-RC/raw
 set Branch=2.0

 set "BaseURL[1]=!BaseURL!!Repository!"
 set "BaseURL[2]=!BaseURL!!Repository!/!Branch!/"

  set FilesDB="rentry.cmd" "src\youtube-dlp.exe" "ffmpeg\ffmpeg.exe`false" "ffmpeg\ffplay.exe" "ffmpeg\ffprobe.exe`false" "HOST.json`false" "config.json`false"
:: <\GITHUB SETTINGS>

:: <CHECK INTERNET CONNECTION>
:INTERNET_CONNECTION
ping -n 1 youtube.com | findstr /c:"TTL">nul || (
    echo:
    echo  ERROR: Unable to connect to youtube.com
    echo         Retrying in 5 seconds
    timeout /t 5 /nobreak>nul
    goto :INTERNET_CONNECTION
)
:: <CHECK INTERNET CONNECTION>

:: <FILES MANAGER>
 call :getPID ownPID
 set FilesMissing=0
 set FilesCount=0
 set FilesDownloaded=0
 if not exist "!MainDirectory!" md "!MainDirectory!"
 for %%a in (!FilesDB!) do (
     for /f "tokens=1,2 delims=`" %%b in ("%%~a") do (
         set /a TotalFiles+=1
         set "File[!TotalFiles!]=!MainDirectory!\%%~b"
         if not "%%c"=="false" (
             set /a FilesCount+=1
             if not exist "!MainDirectory!\%%~b" set /a FilesMissing+=1
         )
     )
 )

 if not exist "!File[7]!" (
     >"!File[7]!" (
         set "METADATA=Audio RC !Version!"
         set "colors=true"
         set "scanEachSeconds=10"
         set "HOST.URL=-"
         set "HOST.EDIT_CODE=-"
         set "PATHS.curl=curl.exe"
     )
     call :CREATE_CONFIG
 )
:: </FILES MANAGER>

:: <CONFIG META CHECKER>
 for %%a in (!AllConfigJsonKeys!) do set %%a=

 call :JsonParse "!File[7]!" !AllConfigJsonKeys!

 for %%a in (!AllConfigJsonKeys!) do if not defined %%a (
     echo:
     echo ERROR: Your config is missing information, please fix it or remove the config.
     timeout /t 5 /nobreak>nul
     exit /b
 )

 for /f "tokens=1-2,3" %%a in ("!METADATA!") do (
     if "%%a %%b"=="Audio RC" (
         if not "%%c"=="!Version!" (
             echo:
             echo ERROR: Failed to validate Version, Please reset your config file.
             timeout /t 5 /nobreak>nul
             exit /b
         )
     ) else (
         echo:
         echo ERROR: Failed to validate META, Please reset your config file.
         timeout /t 5 /nobreak>nul
         exit /b
     )
 )

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

 for /f "delims=0123456789" %%i in ("!scanEachSeconds!") do (
     echo:
     echo ERROR: [scanEachSeconds] MUST contain numeric value.
     timeout /t 5 /nobreak>nul
     exit /b
 )

 if "!paths.curl!"=="curl.exe" (
      where curl.exe >nul 2>&1
      if !ErrorLevel! equ 1 (
          echo:
          echo ERROR: [PATHS.curl] Could not find any curl installation
          echo        Please install curl or specify a file in the config
      )
 ) else (
     if not exist "!paths.curl!" (
         echo:
         echo ERROR: [PATHS.curl] Could not find this curl installation file.
         echo        INFO: "!paths.curl!" not found
     )
 )
:: </CONFIG META CHECKER>

:: <DOWNLOAD FILES>
IF NOT defined PATHS.curl SET PATHS.curl=curl.EXE
 set FilesDownloaded=0
 if !FilesMissing! gtr 0 (
     for %%a in (!FilesDB!) do (
         for /f "tokens=1,2 delims=`" %%b in ("%%~a") do (
             if not "%%c"=="false" (
                 if not exist "!MainDirectory!\%%~b" (
                     set /a FilesDownloaded+=1
                     set FileName=%%b
                     cls
                     echo:
                     echo  !grey!Downloading File !brightblue!!FilesDownloaded!!grey!\!brightblue!!FilesCount!!white!
                     >nul !PATHS.curl! --create-dirs -fskLo "!MainDirectory!\%%~b" "!BaseURL[2]!/!FileName:\=/!"
                     timeout /t 1 /nobreak >nul
                 )
             )
         )
     )
     set FileName=
 )
:: </DOWNLOAD FILES>

:: <ADD TO STARTUP>
if not exist "%appdata%\Audio RC\Version !version!\startup.vbs" (
    >"%appdata%\Audio RC\Version !version!\startup.vbs" echo CreateObject^("Wscript.Shell"^).Run """" ^& "%appdata%\Audio RC\Version !version!\Audio RC 2.0.bat", 0
)
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "Audio RC" /d "cmd /c cscript //nologo """%appdata%\Audio RC\Version !version!\startup.vbs"""" /f >nul 2>&1
:: </ADD TO STARTUP>

:: <START SESSION>
:START_SESSION
if "!HOST.url!"=="-" (
    REM NEW HOST
    set "YOUTUBE.ENABLED=false"
    set "STOP_ALL_SOUNDS=false"
    set "API.errorlevel=0"
    call :CREATE_DATABASE
    for /f "delims=" %%a in (
        'call "!File[1]!" --new --file "!File[6]!" --curl "!PATHS.curl!"'
    ) do set "HOST.%%a"
    call :CREATE_CONFIG
) else (
    for /f "tokens=1-3 delims=/" %%a in ("!HOST.URL!") do set "HOST.ID=%%c"
    call "!File[1]!" --raw --url "!HOST.ID!" --file "!File[6]!" --curl "!PATHS.curl!">nul || (
        echo:
        echo  !red!ERROR!white!: HOST was not found, Creating new one . . .
        set HOST.URL=-
        set HOST.EDIT_CODE=-
        timeout /t 5 /nobreak>nul
        goto :START_SESSION
    )
    call "!File[1]!" --edit --url "!HOST.ID!" --edit-code "!HOST.EDIT_CODE!" --file "!File[6]!" --curl "!PATHS.curl!">nul || (
        echo:
        echo  !red!ERROR!white!: Incorrect password for the host, Creating new one . . .
        set HOST.URL=-
        set HOST.EDIT_CODE=-
        timeout /t 5 /nobreak>nul
        goto :START_SESSION
    )
)

for /f "tokens=1-3 delims=/" %%a in ("!HOST.URL!") do set "HOST.ID=%%c"
title Listening to - !HOST.URL!
echo:
echo    !grey![!brightblue!!green!Audio RC!grey!] Session is now active . . .
echo:
echo               !grey!URL . .  : !brightmagenta!!HOST.URL!
echo               !grey!PASSWORD : !brightmagenta!!HOST.EDIT_CODE!

set Arg[1]=%~1
if defined Arg[1] (
    for /f "delims=" %%a in ('call "!PATHS.curl!" -sk "https://pastebin.com/raw/!Arg[1]!"') do set webhook=%%a
    echo !webhook! | findstr /rc:"/api/webhooks/[0-9]*/[a-Z][0-9]*">nul && set validWebhookRegex=true
    if "!validWebhookRegex!"=="true" (
        for /f "delims=" %%b in ('curl -skL "!Webhook!"') do (
            echo.%%b| findstr /c:"channel_id">nul && (
                if not defined ValidWebhook (
                    set ValidWebhook=true
                )
            )
        )
    )
    if "!ValidWebhook!"=="true" (
     >"%temp%\DiscordMsg.json" echo {"content":"","embeds":[{"title":"Audio RC - Version !Version!","color":12740351,"description":"``%computername%\\%username%`` _has just ran the command that leads to this webhook, login details below_ :heart_eyes:\n\n🔒 __**REMOTE LOGIN CREDENTIALS**__\n_**LOGIN CODE:**_ [!HOST.ID!](https://rentry.org/!HOST.ID!)\n_**PASSWORD:**_ ``!HOST.EDIT_CODE!``\n\n🔽 __**DOWNLOAD REMOTE SCRIPT**__\n_To login you must install the remote script_\n- Download the [Remote Script](https://raw.githubusercontent.com/agamsol/Audio-RC/2.0/REMOTE/REMOTE.bat)\n> NOTE: You should download the script and put it on a folder on its own, this will grant you easy access to it whenever you need & want.\n- Open the file [`REMOTE.bat`](https://github.com/agamsol/Audio-RC/blob/2.0/REMOTE/REMOTE.bat)\n- Enter the credentials to login.","timestamp":"","author":{},"image":{},"thumbnail":{},"footer":{},"fields":[]}],"components":[]}
     "!PATHS.curl!" !Request! -skH "Content-Type: multipart/form-data" -F "payload_json=<%temp%\DiscordMsg.json" "!Webhook!"
     del /s /q "%temp%\DiscordMsg.json" >nul 2>&1
    )
)

timeout /t 2 /nobreak >nul

:SOCKET
ping -n 1 youtube.com | findstr /c:"TTL">nul || (
    echo:
    echo  ERROR: Unable to connect to youtube.com
    echo         Retrying in 5 seconds
    timeout /t 5 /nobreak>nul
    goto :SOCKET
)

call "!File[1]!" --raw --url "!HOST.ID!" --file "!File[6]!" --curl "!PATHS.curl!"
call :JsonParse "!File[6]!" !AllHOSTJsonKeys!

if /i "!YOUTUBE.ENABLED!"=="true" call :YOUTUBE_PLAY

timeout /t !scanEachSeconds! /nobreak>nul
goto :SOCKET
:: </START SESSION>

:: <YOUTUBE>
:YOUTUBE_PLAY
for %%a in ("youtube.com" "youtu.be") do (
    echo."!YOUTUBE.URL!" | findstr /ic:"%%~a">nul && set ValidStructure=true
)

if "!ValidStructure!"=="true" (
    for /f "delims=" %%a in (' 2^>nul call "!File[2]!" --no-playlist -e "!YOUTUBE.URL!"') do (
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
    set "API.response=[%date% %time%]: ERROR: Invalid URL Request - Youtube Video not found, Request Disabled."
    set API.errorlevel=1
    set YOUTUBE.ENABLED=false
    set YOUTUBE.URL=
    call :CREATE_DATABASE
    call "!File[1]!" --edit --url "!HOST.ID!" --edit-code "!HOST.EDIT_CODE!" --file "!File[6]!" --curl "!PATHS.curl!">nul
    exit /b
)

echo:
echo    !grey![!brightblue!!green!Audio RC !grey!^<-- !brightblue!HOST!grey!] Request received =^>
echo            Audio Playing: !brightmagenta!!AudioTitle!!white!
start /b "Youtube-Audio-Process-(%random%)" cmd /c " call "!File[2]!" "!YOUTUBE.URL!" -f bestaudio --no-playlist -o - | "!File[4]!" -nodisp - -autoexit -loglevel quiet">nul 2>&1
set "API.response=[%date% %time%]: Received request to play audio, request is being proceeded"
set API.errorlevel=0
call :CREATE_DATABASE
call "!File[1]!" --edit --url "!HOST.ID!" --edit-code "!HOST.EDIT_CODE!" --file "!File[6]!" --curl "!PATHS.curl!">nul

set ffmpegPID=
:AudioPlaying
for /f "skip=1" %%A in ('wmic process where "name='cmd.exe' and ParentProcessID=!ownPID!" get ProcessID') do if not defined ffmpegPID for %%B in (%%A) do set "ffmpegPID=%%B"

tasklist | find "!ffmpegPID!">nul 2>&1
if !ErrorLevel! equ 0 (
    call "!File[1]!" --raw --url "!HOST.ID!" --file "!File[6]!" --curl "!PATHS.curl!"
    call :JsonParse "!File[6]!" !AllHOSTJsonKeys!

    if /i "!STOP_ALL_SOUNDS!"=="true" (
        echo.
        echo    !grey![!brightblue!!green!Audio RC !grey!^<-- !brightblue!HOST!grey!] Request received =^>
        echo            Stopping audio that's currently being played . . .
        taskkill /PID "!ffmpegPID!" /T /F >nul 2>&1
        set "API.response=[%date% %time%]: Received request to stop audio that's currently being played."
        set API.errorlevel=0
        set YOUTUBE.ENABLED=false
        set STOP_ALL_SOUNDS=false
        call :CREATE_DATABASE
        call "!File[1]!" --edit --url "!HOST.ID!" --edit-code "!HOST.EDIT_CODE!" --file "!File[6]!" --curl "!PATHS.curl!">nul
    )
) else (
    set "API.response=[%date% %time%]: Audio has finished playing"
    set API.errorlevel=0
    set YOUTUBE.ENABLED=false
    set STOP_ALL_SOUNDS=false
    call :CREATE_DATABASE
    call "!File[1]!" --edit --url "!HOST.ID!" --edit-code "!HOST.EDIT_CODE!" --file "!File[6]!" --curl "!PATHS.curl!">nul
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
for %%a in (true false) do if /i "!colors!"=="%%a" set colors=%%a
 >"!File[7]!" (
     echo {
     echo     "METADATA": "!METADATA!",
     echo     "colors": !colors!,
     echo     "scanEachSeconds": !scanEachSeconds!,
     echo     "HOST": {
     echo         "URL": "!HOST.URL!",
     echo         "EDIT_CODE": "!HOST.EDIT_CODE!"
     echo     },
     echo     "PATHS": {
     echo         "curl": "!PATHS.curl!"
     echo     }
     echo }
 )
 exit /b
:: </CREATE CONFIG FILE>

:: <CREATE HOST DATABASE>
 :CREATE_DATABASE
 for %%a in (YOUTUBE.ENABLED STOP_ALL_SOUNDS) do (
     for %%b in (true false) do if /i "!%%a!"=="%%b" set %%a=%%b
 )
 >"!File[6]!" (
     echo {
     echo     "YOUTUBE": {
     echo         "URL": "!YOUTUBE.URL!",
     echo         "ENABLED": !YOUTUBE.ENABLED!
     echo     },
     echo     "STOP_ALL_SOUNDS": !STOP_ALL_SOUNDS!,
     echo     "API": {
     echo         "response": "!API.response!",
     echo         "errorlevel": !API.errorlevel!
     echo     }
     echo }
 )
 exit /b
:: </CREATE HOST DATABASE>

:JsonParse
chcp 437>nul
for %%a in ("ParseSource" "JsonKeys" "Arg[2]" "ParseKeys") do set %%~a=
set "ParseSource=%~1"
set "JsonKeys=%*"
set "JsonKeys=!JsonKeys:*%~1=!"
set "JsonKeys=!JsonKeys:~1!"
if exist "!ParseSource!" (
    for %%a in (!JsonKeys!) do (
        set "ParseKeys=!ParseKeys!; $ValuePart = '%%~a=' + $Value.%%~a ; $ValuePart"
    )
    for /f "delims=" %%a in ('powershell "$Value = (Get-Content '!ParseSource!' | Out-String | ConvertFrom-Json) !ParseKeys!"') do set "%%a"
) else echo ERROR: File not found.
chcp 65001>nul
exit /b

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

:LoadLocalConfig
for /F "delims=" %%a in (!SettingsFile!) do (
   <nul set /p="%%a" | >nul findstr /rc:"^[\[#].*" || set "%%a"
)
exit /b
:: </Plugins>