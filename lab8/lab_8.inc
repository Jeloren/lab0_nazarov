; lab_8.inc
includelib import32.lib

extrn ExitProcess:near
extrn GetCommandLineA:near
extrn MoveFileExA:near
extrn GetLastError:near
; --- НОВЫЕ ФУНКЦИИ ДЛЯ ВЫВОДА ---
extrn GetStdHandle:near
extrn WriteConsoleA:near