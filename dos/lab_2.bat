tasm.exe lab_2.asm /l
pause
tasm.exe prog.asm /l
pause
tlink lab_2.obj prog.obj
pause
td.exe lab_2.exe