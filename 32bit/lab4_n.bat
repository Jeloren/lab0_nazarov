tasm32 /ml /l lab4_n.asm
pause
tlink32 /Tpe /aa /x /c lab4_n.obj,,,import32.lib
pause
td32 lab4_n.exe