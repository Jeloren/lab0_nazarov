tasm32.exe /ml lab4.asm
pause
tasm32.exe /ml prog.asm
pause
tlink32.exe /Tpe /aa /c lab4.obj prog.obj
pause
td32.exe lab4.exe