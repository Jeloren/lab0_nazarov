@ECHO OFF
REM Ассемблирование
tasm32 /ml /l lab_9.asm
IF ERRORLEVEL 1 GOTO Error

REM Компоновка (Console mode)
tlink32 /Tpe /ap /c lab_9.obj
IF ERRORLEVEL 1 GOTO Error

ECHO Build Successful!
lab_9.exe
GOTO End

:Error
ECHO Build Failed!

:End
PAUSE