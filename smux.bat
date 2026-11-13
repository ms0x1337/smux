@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

rem ================== DEFAULT SETTINGS ==================
set "SCRIPT_DIR=%~dp0"
set "DEFAULT_VIDEO_DIR=%SCRIPT_DIR%"
set "DEFAULT_AUDIO_DIR=%SCRIPT_DIR%"
set "DEFAULT_SUB_DIR=%SCRIPT_DIR%"
set "DEFAULT_OUT_DIR=%SCRIPT_DIR%Completed"

set "MKVMERGE=%ProgramFiles%\MKVToolNix\mkvmerge.exe"
set "SKIP_EXISTING=1"

set "VIDEO_MASKS=*.mkv *.mp4 *.avi *.ts *.m4v *.webm *.mov *.wmv"
set "AUDIO_EXTS=mka ac3 eac3 dts flac wav aac m4a mp3 opus thd"
set "SUB_EXTS=ass ssa srt sub sup vtt"
rem ======================================================

rem --- parse arguments ---
set "VIDEO_DIR="
set "AUDIO_DIR="
set "SUB_DIR="
set "OUT_DIR="

:PARSE_ARGS
if "%~1"=="" goto :ARGS_DONE
if /i "%~1"=="-v" (
    set "VIDEO_DIR=%~2"
    shift & shift
    goto :PARSE_ARGS
)
if /i "%~1"=="-a" (
    set "AUDIO_DIR=%~2"
    shift & shift
    goto :PARSE_ARGS
)
if /i "%~1"=="-s" (
    set "SUB_DIR=%~2"
    shift & shift
    goto :PARSE_ARGS
)
if /i "%~1"=="-o" (
    set "OUT_DIR=%~2"
    shift & shift
    goto :PARSE_ARGS
)
if /i "%~1"=="-h" goto :HELP
if /i "%~1"=="--help" goto :HELP
echo [WARN] Unknown argument: %~1
shift
goto :PARSE_ARGS

:ARGS_DONE
if not defined VIDEO_DIR set "VIDEO_DIR=%DEFAULT_VIDEO_DIR%"
if not defined AUDIO_DIR set "AUDIO_DIR=%DEFAULT_AUDIO_DIR%"
if not defined SUB_DIR set "SUB_DIR=%DEFAULT_SUB_DIR%"
if not defined OUT_DIR set "OUT_DIR=%DEFAULT_OUT_DIR%"

rem --- normalize paths: relative -> absolute ---
call :NORMALIZE_PATH VIDEO_DIR "!VIDEO_DIR!" "%SCRIPT_DIR%"
call :NORMALIZE_PATH AUDIO_DIR "!AUDIO_DIR!" "!VIDEO_DIR!"
call :NORMALIZE_PATH SUB_DIR "!SUB_DIR!" "!VIDEO_DIR!"
call :NORMALIZE_PATH OUT_DIR "!OUT_DIR!" "%SCRIPT_DIR%"

rem --- remove trailing backslash (except drive root) ---
call :STRIP_TRAILING_SLASH VIDEO_DIR
call :STRIP_TRAILING_SLASH AUDIO_DIR
call :STRIP_TRAILING_SLASH SUB_DIR
call :STRIP_TRAILING_SLASH OUT_DIR

rem --- find mkvmerge ---
if not exist "%MKVMERGE%" set "MKVMERGE=%ProgramFiles(x86)%\MKVToolNix\mkvmerge.exe"
if not exist "%MKVMERGE%" for %%P in (mkvmerge.exe) do if not "%%~$PATH:P"=="" set "MKVMERGE=%%~$PATH:P"
if not defined MKVMERGE goto :NO_MKV
if not exist "%MKVMERGE%" goto :NO_MKV

if not exist "!OUT_DIR!" mkdir "!OUT_DIR!"
set /a OK=0, WARN=0, FAIL=0, SKIP=0

echo ========================================
echo  MKV Merge Script
echo  mkvmerge : "%MKVMERGE%"
echo  video dir: "!VIDEO_DIR!"
echo  audio dir: "!AUDIO_DIR!"
echo  sub dir  : "!SUB_DIR!"
echo  output   : "!OUT_DIR!"
echo ========================================
echo.

set "FOUND_VIDEO=0"
for %%M in (%VIDEO_MASKS%) do (
    for /f "delims=" %%F in ('dir /b /s /a-d "!VIDEO_DIR!\%%M" 2^>nul') do (
        set "FOUND_VIDEO=1"
        call :PROCESS_VIDEO "%%F"
    )
)

if !FOUND_VIDEO! equ 0 (
    echo [WARN] No video files found in "!VIDEO_DIR!"
)

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

:HELP
echo Usage: %~nx0 [-v VIDEO_DIR] [-a AUDIO_DIR] [-s SUB_DIR] [-o OUT_DIR]
echo.
echo   -v  Video folder (default: script folder)
echo   -a  Audio folder (default: script folder; relative path - from VIDEO_DIR)
echo   -s  Subtitle folder (default: script folder; relative path - from VIDEO_DIR)
echo   -o  Output folder (default: Completed in script folder)
echo   -h  Show this message
echo.
echo Examples:
echo   %~nx0
echo   %~nx0 -v "MySeries" -a "RUS Sound" -s "RUS Subs"
echo   %~nx0 -v "C:\Series" -a "Sound" -s "Subs" -o "D:\Output"
pause
exit /b 0


rem ================== PROCESS VIDEO ==================
:PROCESS_VIDEO
set "SRC=%~1"
set "BASE=%~n1"
set "SRC_DIR=%~dp1"

rem --- relative path from VIDEO_DIR ---
call :GET_REL_DIR REL_DIR "!SRC_DIR!" "!VIDEO_DIR!"

set "OUT_DIR_FULL=!OUT_DIR!\!REL_DIR!"
set "OUT=!OUT_DIR_FULL!\!BASE!.mkv"

if not exist "!OUT_DIR_FULL!" mkdir "!OUT_DIR_FULL!"

if "%SKIP_EXISTING%"=="1" if exist "!OUT!" (
    echo [SKIP] "!SRC!" - already muxed
    set /a SKIP+=1
    exit /b 0
)

echo Processing: "!SRC!"

set "ARGS="
set /a NA=0, NS=0

rem --- calculate base name length ---
call :STRLEN BASE_LEN "!BASE!"

rem --- search audio (recursive, using dir) ---
for %%E in (%AUDIO_EXTS%) do (
    for /f "delims=" %%A in ('dir /b /s /a-d "!AUDIO_DIR!\*.%%E" 2^>nul') do (
        set "FNAME=%%~nA"
        call :STRLEN FNAME_LEN "!FNAME!"
        
        set "MATCH=0"
        if /i "!FNAME!"=="!BASE!" set "MATCH=1"
        if !FNAME_LEN! GTR !BASE_LEN! (
            if /i "!FNAME:~0,%BASE_LEN%!"=="!BASE!" if "!FNAME:~%BASE_LEN%,1!"=="." set "MATCH=1"
        )
        
        if !MATCH! equ 1 (
            set "ARGS=!ARGS! "%%A""
            set /a NA+=1
            echo    + audio: "%%~nxA"
        )
    )
)

rem --- search subtitles (recursive, using dir) ---
for %%E in (%SUB_EXTS%) do (
    for /f "delims=" %%S in ('dir /b /s /a-d "!SUB_DIR!\*.%%E" 2^>nul') do (
        set "FNAME=%%~nS"
        call :STRLEN FNAME_LEN "!FNAME!"
        
        set "MATCH=0"
        if /i "!FNAME!"=="!BASE!" set "MATCH=1"
        if !FNAME_LEN! GTR !BASE_LEN! (
            if /i "!FNAME:~0,%BASE_LEN%!"=="!BASE!" if "!FNAME:~%BASE_LEN%,1!"=="." set "MATCH=1"
        )
        
        if !MATCH! equ 1 (
            set "ARGS=!ARGS! "%%S""
            set /a NS+=1
            echo    + sub  : "%%~nxS"
        )
    )
)

if !NA! EQU 0 if !NS! EQU 0 (
    echo    [SKIP] no external audio/subtitles
    set /a SKIP+=1
    echo.
    exit /b 0
)

echo    audio=!NA!  sub=!NS!
echo    out : "!OUT!"
"%MKVMERGE%" -o "!OUT!" "!SRC!"!ARGS!
set "RC=!errorlevel!"

if !RC! EQU 0 (
    echo    [OK]
    set /a OK+=1
) else if !RC! EQU 1 (
    echo    [WARN] muxed with warnings
    set /a WARN+=1
) else (
    echo    [ERROR] mkvmerge exit code: !RC!
    set /a FAIL+=1
)
echo.
exit /b 0


rem ================== UTILITIES ==================

:NORMALIZE_PATH
set "VAR=%~1"
set "VAL=%~2"
set "BASE=%~3"
set "C1=!VAL:~0,1!"
set "C2=!VAL:~1,1!"
if "!C2!"==":" (
    set "%VAR%=!VAL!"
) else if "!C1!"=="\" if "!C2!"=="\" (
    set "%VAR%=!VAL!"
) else (
    set "%VAR%=!BASE!\!VAL!"
)
exit /b 0

:STRIP_TRAILING_SLASH
set "VAR=%~1"
set "VAL=!%~1!"
if "!VAL:~-1!"=="\" (
    set "TMP=!VAL:~0,-1!"
    if not "!TMP!"=="" (
        set "C2=!TMP:~1,1!"
        if not "!C2!"==":" set "%VAR%=!TMP!"
    )
)
exit /b 0

:GET_REL_DIR
set "VAR=%~1"
set "FULL=%~2"
set "BASE=%~3"
if "!BASE:~-1!"=="\" (
    set "PREFIX=!BASE!"
) else (
    set "PREFIX=!BASE!\"
)
set "TMP=!FULL:%PREFIX%=!"
if "!TMP!"=="!FULL!" (
    set "%VAR%=."
) else (
    if "!TMP!"=="" set "TMP=."
    set "%VAR%=!TMP!"
)
exit /b 0

:STRLEN
set "VAR=%~1"
set "STR=%~2"
set "LEN=0"
:STRLEN_LOOP
if "!STR:~%LEN%!"=="" goto :STRLEN_DONE
set /a LEN+=1
goto :STRLEN_LOOP
:STRLEN_DONE
set "%VAR%=!LEN!"
exit /b 0