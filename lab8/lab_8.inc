; lab_8.inc
; Имена используемых функций из kernel32.dll

includelib import32.lib ; Используем kernel32.lib для MoveFileA и ExitProcess

extrn ExitProcess:near
extrn GetCommandLineA:near
extrn MoveFileA:near       ; Функция, необходимая для варианта 10
extrn GetLastError:near    ; Добавлено для отладки ошибок