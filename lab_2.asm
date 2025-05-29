.model small
.stack 100h

.data
    ; Тестовые данные
    test_empty    db 0                 ; Пустая строка
    len_empty     db 5

    test_no_spc  db 3, 'abc'          ; Строка без пробелов
    len_no_spc   db 5

    test_with_spc db 5, 'a b c'       ; Строка с пробелами
    len_with_spc  db 8

    result       db 255 dup(?)        ; Буфер для результата

.code
extrn InsBlanks:proc

main proc
    mov ax, @data
    mov ds, ax
    mov es, ax

    ; Тест 1: Пустая строка
    mov si, offset test_empty
    mov al, len_empty
    mov di, offset result
    call InsBlanks

    ; Тест 2: Строка без пробелов
    mov si, offset test_no_spc
    mov al, len_no_spc
    mov di, offset result
    call InsBlanks

    ; Тест 3: Строка с пробелами
    mov si, offset test_with_spc
    mov al, len_with_spc
    mov di, offset result
    call InsBlanks

    ; Завершение программы
    mov ax, 4C00h
    int 21h
main endp

end main