@echo off
setlocal enableDelayedExpansion
TITLE Audio RC - REMOTE
pushd "%~dp0"

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
set "AllHOSTJsonKeys=YOUTUBE.URL YOUTUBE.ENABLED STOP_ALL_SOUNDS API.response API.errorlevel"

if "%~1"=="--PauseAudio" (
    mode 36,10
    title Click To Stop Audio
    call "rentry.cmd" --raw --url "%~2" --file "%temp%\REMOTE-%~2-SOCKET-2.json"
    call :JsonParse "%temp%\REMOTE-%~2-SOCKET-2.json" !AllHOSTJsonKeys!
    echo:
    echo  !grey!Press any key to !brightred!stop !grey!the audio.
    echo:
    pause >nul
    set STOP_ALL_SOUNDS=true
    set "ID=%~2"
    call :CREATE_DATABASE "-SOCKET-2"
    call "rentry.cmd" --edit --url "%~2" --edit-code "%~3" --file "%temp%\REMOTE-%~2-SOCKET-2.json">nul
    ECHO  !grey!Stopping any audio from playing.
    timeout /t 100 /nobreak>nul
    exit
)
mode 80,30

call :getPID ownPID
if not exist "config.json" (
    :LOGIN
    cls
    echo:
    echo  !grey!Please provide the ID of the HOST
    echo          Should be like this: !brightred!https://rentry.co/!green!XXXXX !grey!^(!brightblue!The green part is what you need!grey!^)
    echo:
    set /p "ID=!brightmagenta!--> "

    echo:
    echo  !grey!Please provide the HOST's Password.
    echo:
    set /p "EDIT_CODE=!brightmagenta!--> "

    >"config.json" (
        echo {
        echo     "ID": "!ID!",
        echo     "EDIT_CODE": "!EDIT_CODE!"
        echo }
    )
)

call :JsonParse "config.json" ID EDIT_CODE
call "rentry.cmd" --raw --url "!ID!" --file "%temp%\REMOTE-!ID!.json">nul || (
    echo:
    echo  !brightred!ERROR!grey!: HOST was not found, Please try again . . .
    timeout /t 5 /nobreak>nul
    goto :LOGIN
)
call "rentry.cmd" --edit --url "!ID!" --edit-code "!EDIT_CODE!" --file "%temp%\REMOTE-!ID!.json">nul || (
    echo:
    echo  !brightred!ERROR!grey!: Incorrect password for the host, Please try again . . .
    timeout /t 5 /nobreak>nul
    goto :LOGIN
)

:PROVIDE_URL
call "rentry.cmd" --raw --url "!ID!" --file "%temp%\REMOTE-!ID!.json"
call :JsonParse "%temp%\REMOTE-!ID!.json" !AllHOSTJsonKeys!
cls
echo:
echo   !green!You !grey!are connected to !brightblue!!ID!!grey!.
echo:
echo   !grey!Please Provide Youtube URL to play . . .
echo:
set /p "YOUTUBE.URL=!brightmagenta!--> "
set ValidStructure=false
for %%a in ("youtube.com" "youtu.be") do (
   echo."!YOUTUBE.URL!" | findstr /ic:"%%~a">nul && set ValidStructure=true
)
if "!ValidStructure!"=="false" (
    echo:
    echo  !brightred!ERROR!grey!: It seems that the URL you provided does not have the correct regex.
    echo:
    timeout /t 3 /nobreak>nul
    goto :PROVIDE_URL
)

set API.response=
set API.errorlevel=0
set STOP_ALL_SOUNDS=false
set YOUTUBE.ENABLED=true
call :CREATE_DATABASE
call "rentry.cmd" --edit --url "!ID!" --edit-code "!EDIT_CODE!" --file "%temp%\REMOTE-!ID!.json">nul
echo:
echo    !grey![!brightblue!HOST !grey!^<-- !brightblue!!green!REMOTE!grey!] Request Sent =^>
echo           Asking !brightblue!HOST !grey!to play audio, waiting for !brightblue!Audio RC's !grey!response.
set Received=false
:API_RESPOND_TO_PLAY_AUDIO
call "rentry.cmd" --raw --url "!ID!" --file "%temp%\REMOTE-!ID!.json"
call :JsonParse "%temp%\REMOTE-!ID!.json" !AllHOSTJsonKeys!
if not "!Received!"=="true" (
    echo !API.response! | findstr /c:"Received request to play audio, request is being proceeded">nul && (
        set Received=true
        echo:
        echo    !grey![!brightblue!HOST !grey!--^> !brightblue!!green!REMOTE!grey!] Response received =^>
        echo           Audio is now being played . . .
        echo:
    )
)
if "!Received!"=="true" tasklist | findstr /c:"!StopMusicWindowPID!">nul 2>&1 || (
    start "" cmd /k ""%~f0" "--PauseAudio" "!ID!" "!EDIT_CODE!""
    set StopMusicWindowPID=
    for /f "skip=1" %%a in ('wmic process where "name='cmd.exe' and ParentProcessID=!ownPID!" get ProcessID') do if not defined StopMusicWindowPID for %%b in (%%a) do set "StopMusicWindowPID=%%b"
)
if !API.errorlevel! equ 1 (
    echo !API.response! | findstr /c:"ERROR: Invalid URL Request - Youtube Video not found, Request Disabled.">nul && (
        echo:
        echo    !grey![!brightblue!HOST !grey!--^> !brightblue!!green!REMOTE!grey!] Response received !brightred!=^>
        echo           !grey!Youtube Video not found, Request ignored.
        echo:
        timeout /t 5 /nobreak>nul
        goto :PROVIDE_URL
    )
)
echo !API.response! | findstr /c:"Audio has finished playing">nul && (
    taskkill /f /T /PID !StopMusicWindowPID!>NUL 2>&1
    echo    !grey![!brightblue!HOST !grey!--^> !brightblue!!green!REMOTE!grey!] Response received =^>
    echo           Audio has finished playing.
    echo:
    timeout /t 5 /nobreak>nul
    goto :PROVIDE_URL
)
goto :API_RESPOND_TO_PLAY_AUDIO


:: <CREATE HOST DATABASE>
 :CREATE_DATABASE
 for %%a in (YOUTUBE.ENABLED STOP_ALL_SOUNDS) do (
     for %%b in (true false) do if /i "!%%a!"=="%%b" set %%a=%%b
 )
 >"%temp%\REMOTE-!ID!%~1.json" (
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


:JsonParse <Json file> <Json keys to parse>
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