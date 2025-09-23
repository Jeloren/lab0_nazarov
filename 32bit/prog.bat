tasm32 /ml /l prog.asm
pause
tlink32 /Tpd /c prog.obj,,,import32.lib,prog.def
pause
implib prog.lib prog.dll
pause