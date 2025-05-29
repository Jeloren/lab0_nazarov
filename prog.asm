.model small
.code
public InsBlanks

InsBlanks proc near
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    cld

    ; Проверка на пустую строку
    mov cl, [si]
    test cl, cl
    jz short exit

    ; Проверка длины
    cmp cl, al
    jae copy_original

    ; Вычисление delta
    mov dl, al
    sub dl, cl          ; dl = delta

    ; Копирование исходной строки в буфер
    push di
    mov [di], cl        ; Копируем длину
    inc di
    inc si
    mov ch, 0
    rep movsb
    pop di              ; DI указывает на буфер
    dec si              ; Восстановить SI

    ; Подсчет пробелов
    mov si, di
    inc si              ; Начало данных
    mov cl, [di]
    xor bx, bx          ; Счетчик пробелов
    xor dx, dx          ; Индекс символа
count_loop:
    lodsb
    cmp al, ' '
    jne next_char
    inc bx
next_char:
    inc dx
    loop count_loop

    ; Проверка наличия пробелов
    test bx, bx
    jz add_end

    ; Защита от деления на ноль
    test bl, bl
    jz add_end

    ; Распределение пробелов
    mov cx, dx          ; delta
    mov al, dl
    xor ah, ah
    div bl              ; AL = quotient, AH = remainder
    mov dh, ah          ; remainder
    mov dl, al          ; quotient

    ; Вставка пробелов
    mov si, di
    inc si              ; Начало данных
    mov cl, [di]
    xor ch, ch
insert_loop:
    push cx
    push si
    mov cl, [di]
    mov si, di
    inc si
search_spc:
    lodsb
    cmp al, ' '
    jne skip
    dec bx
    jnz skip
    ; Вставка пробелов
    mov al, ' '
    mov cx, dx
    add cl, dh
    jcxz skip
insert_space:
    stosb
    ; Обновление длины строки
    mov al, [di-1]
    inc al
    mov [di-1], al
    loop insert_space
skip:
    loop search_spc
    pop si
    pop cx
    loop insert_loop
    jmp short exit

add_end:
    ; Добавление пробелов в конец
    mov al, ' '
    mov cl, dl
    add cl, dh
    rep stosb
    ; Обновление длины строки
    mov [di-1], cl

copy_original:
    ; Копирование исходной строки
    mov cl, [si]
    mov [di], cl
    inc di
    inc si
    rep movsb

exit:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
InsBlanks endp

end