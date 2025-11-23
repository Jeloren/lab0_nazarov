@ECHO OFF
CLS

ECHO [1] Assembling lab_8.asm...

if exist lab_8.obj del lab_8.obj
if exist lab_8.exe del lab_8.exe

:: Запуск TASM
tasm32 /ml /l lab_8.asm > tasm_log.txt 2>&1
IF ERRORLEVEL 1 (
    ECHO Error in TASM!
    TYPE tasm_log.txt
    PAUSE
    GOTO :EOF
)

ECHO [2] Linking lab_8.obj -> lab_8.exe...

tlink32 lab_8.obj /Tpe /ap /c > tlink_log.txt 2>&1
IF ERRORLEVEL 1 (
    ECHO Error in TLINK!
    TYPE tlink_log.txt
    PAUSE
    GOTO :EOF
)

IF NOT EXIST lab_8.exe (
    ECHO Error: lab_8.exe was not created!
    PAUSE
    GOTO :EOF
)

ECHO.
ECHO Build Successful! lab_8.exe is ready.
PAUSE