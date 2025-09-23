.386
.model flat, stdcall

includelib import32.lib
includelib prog.lib       ; импорт-библиотека для prog.dll

extern MessageBoxA: near
extern ExitProcess: near
extern InsBlanks: near

.data
    input_string  db 'Hello asm world',0
    k             dd 26
    result_buffer db 256 dup(0)
    words_buffer  dd 20 dup(0)
    temp_buffer   db 256 dup(0)
    caption       db "Result",0

.code
main proc
    ; Вызов InsBlanks напрямую
    push offset temp_buffer
    push offset words_buffer
    push offset result_buffer
    push k
    push offset input_string
    call InsBlanks
    add esp, 20

    ; Вывод результата
    push 0
    push offset caption
    push offset result_buffer
    push 0
    call MessageBoxA

    ; Завершение программы
    push 0
    call ExitProcess
main endp

end main
