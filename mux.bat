@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

rem ================== SETTINGS ==================
set "MKVMERGE=%ProgramFiles%\MKVToolNix\mkvmerge.exe"
set "OUTPUT_DIR=Completed"
set "SKIP_EXISTING=1"

set "VIDEO_MASKS=*.mkv *.mp4 *.avi *.ts *.m4v *.webm *.mov *.wmv"
set "AUDIO_EXTS=mka ac3 eac3 dts flac wav aac m4a mp3 opus thd"
set "SUB_EXTS=ass ssa srt sub sup vtt"
rem ===============================================

rem --- mkvmerge search: specified path -> x86 -> PATH ---
if not exist "%MKVMERGE%" set "MKVMERGE=%ProgramFiles(x86)%\MKVToolNix\mkvmerge.exe"
if not exist "%MKVMERGE%" for %%P in (mkvmerge.exe) do if not "%%~$PATH:P"=="" set "MKVMERGE=%%~$PATH:P"
if not defined MKVMERGE goto :NO_MKV
if not exist "%MKVMERGE%" goto :NO_MKV

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
set /a OK=0, WARN=0, FAIL=0, SKIP=0

echo ========================================
echo  MKV Merge Script
echo  mkvmerge: "%MKVMERGE%"
echo  output  : "%OUTPUT_DIR%"
echo ========================================
echo.

for %%F in (%VIDEO_MASKS%) do call :PROCESS "%%~fF"

echo.
echo ========================================
echo  Done. OK=%OK%  WARN=%WARN%  SKIP=%SKIP%  ERROR=%FAIL%
echo ========================================
pause
exit /b 0

:NO_MKV
echo [ERROR] mkvmerge.exe not found.
echo         Set the full path in the MKVMERGE variable at the top of the script.
pause
exit /b 1


rem ================== PROCESS SINGLE VIDEO ==================
:PROCESS
set "SRC=%~1"
set "BASE=%~n1"
set "OUT=%OUTPUT_DIR%\%~n1.mkv"
set "ARGS="
set /a NA=0, NS=0

if "%SKIP_EXISTING%"=="1" if exist "%OUT%" (
    echo [SKIP] "%~nx1" - already muxed
    set /a SKIP+=1
    exit /b 0
)

echo Processing: "%~nx1"

rem --- external audio: BASE.ext and BASE.*.ext ---
for %%E in (%AUDIO_EXTS%) do for %%A in ("%BASE%.%%E" "%BASE%.*.%%E") do if exist "%%~fA" (
    set "ARGS=!ARGS! "%%~fA""
    set /a NA+=1
    echo    + audio: "%%~nxA"
)

rem --- external subtitles: BASE.ext and BASE.*.ext ---
for %%E in (%SUB_EXTS%) do for %%S in ("%BASE%.%%E" "%BASE%.*.%%E") do if exist "%%~fS" (
    set "ARGS=!ARGS! "%%~fS""
    set /a NS+=1
    echo    + sub  : "%%~nxS"
)

rem --- no external audio or subtitles found ---
if !NA! EQU 0 if !NS! EQU 0 (
    echo    [SKIP] no external audio/subtitles
    set /a SKIP+=1
    echo.
    exit /b 0
)

echo    audio=!NA!  sub=!NS!
echo    out : "!OUT!"
"%MKVMERGE%" -o "%OUT%" "%SRC%"!ARGS!
set "RC=!errorlevel!"

if !RC! EQU 0 (
    echo    [OK]
    set /a OK+=1
) else if !RC! EQU 1 (
    echo    [WARN] muxed with warnings
    set /a WARN+=1
) else (
    echo    [ERROR] mkvmerge exit code !RC!
    set /a FAIL+=1
)
echo.
exit /b 0