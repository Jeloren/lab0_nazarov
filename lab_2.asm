.MODEL SMALL
.STACK 100h

EXTRN InsBlanks: FAR

.DATA
    S      DB 11, 'Hello world'   ; Исходная строка
    Len    DB 20                  ; Желаемая длина
    Result DB 255 DUP(?)          ; Результат (первый байт — длина)
    EndStr DB '$'                 ; Символ конца строки для вывода

.CODE
Start:
    mov ax, @data
    mov ds, ax

    ; Вызов InsBlanks(S, Len, Result)
    push ds
    lea ax, S
    push ax
    xor ax, ax                   ; Очистка AX
    mov al, Len                  ; Загрузка Len в AL
    push ax                      ; Передаём Len как слово
    push ds
    lea ax, Result
    push ax
    call InsBlanks

    ; Добавляем символ '$' в конец строки Result
    mov si, offset Result
    xor cx, cx
    mov cl, [si]                ; Загружаем длину строки из Result[0]
    lea di, [si + 1]            ; DI указывает на начало строки (после байта длины)
    add di, cx                   ; DI = конец строки
    mov byte ptr [di], '$'       ; Записываем '$'

    ; Вывод результата
    mov ah, 09h
    lea dx, [si + 1]            ; Пропускаем байт длины
    int 21h

    ; Завершение программы
    mov ax, 4C00h
    int 21h

END Start