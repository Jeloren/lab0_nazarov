; lab9.inc
; Константы и импорты

includelib import32.lib

; --- Константы Win32 API ---
STD_INPUT_HANDLE    EQU -10
STD_OUTPUT_HANDLE   EQU -11
NULL                EQU 0

; Константы для настройки клавиатуры
SPI_SETKEYBOARDSPEED EQU 000Bh ; (11) Скорость повтора
SPI_SETKEYBOARDDELAY EQU 0017h ; (23) Задержка перед первым повтором
SPIF_SENDCHANGE      EQU 0002h ; Обновить системные настройки немедленно

; --- Импорт функций ---
extrn ExitProcess:near
extrn GetStdHandle:near
extrn WriteConsoleA:near
extrn ReadConsoleA:near
extrn SystemParametersInfoA:near ; Находится в User32.dll

; Псевдонимы для удобства (как в методичке [cite: 88])
WriteConsole EQU WriteConsoleA
ReadConsole  EQU ReadConsoleA
SystemParametersInfo EQU SystemParametersInfoA