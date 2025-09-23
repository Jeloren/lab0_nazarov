tasm32 /ml /l lab4_y.asm
pause
tlink32 /Tpe /aa /x /c lab4_y.obj,,,import32.lib
pause
td32.exe lab4_y.exe