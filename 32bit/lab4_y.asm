.386
.model flat, stdcall
option casemap :none

includelib import32.lib

extern MessageBoxA: PROC
extern ExitProcess: PROC
extern LoadLibraryA: PROC
extern GetProcAddress: PROC
extern FreeLibrary: PROC

.data
    input_string  db 'Hello asm world',0
    k             dd 26
    result_buffer db 256 dup(0)
    words_buffer  dd 20 dup(0)
    temp_buffer   db 256 dup(0)
    caption       db "Result",0
    dllName       db "prog.dll",0
    funcName      db "InsBlanks",0
    hLib          dd 0
    pInsBlanks    dd 0

.code
main proc
    ; Загрузка DLL
    push offset dllName
    call LoadLibraryA
    mov hLib, eax
    test eax, eax
    jz exit_program

    ; Получение адреса функции
    push offset funcName
    push eax
    call GetProcAddress
    mov pInsBlanks, eax
    test eax, eax
    jz unload_dll

    ; Вызов InsBlanks через указатель
    push offset temp_buffer
    push offset words_buffer
    push offset result_buffer
    push k
    push offset input_string
    call pInsBlanks
    add esp, 20     ; чистим стек

    ; Вывод результата
    push 0
    push offset caption
    push offset result_buffer
    push 0
    call MessageBoxA

unload_dll:
    ; Освобождение библиотеки
    push hLib
    call FreeLibrary

exit_program:
    push 0
    call ExitProcess
main endp

end main
