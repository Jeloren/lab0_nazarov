.MODEL LARGE
.CODE

PUBLIC InsBlanks

InsBlanks PROC FAR
    ; Параметры в стеке:
    ; [BP+6]  - Смещение строки S
    ; [BP+8]  - Сегмент строки S
    ; [BP+10] - Длина Len (слово, но используем только младший байт)
    ; [BP+12] - Смещение результата Res
    ; [BP+14] - Сегмент результата Res

    push bp
    mov bp, sp
    push ds
    push es
    push si
    push di
    push ax
    push bx
    push cx
    push dx

    ; Загрузка адреса исходной строки S в DS:SI
    lds si, [bp+6]     ; DS:SI = S

    ; Загрузка адреса результата Res в ES:DI
    les di, [bp+12]    ; ES:DI = Res

    ; Копирование исходной строки S в Res
    mov cl, [si]       ; Длина S
    mov ch, 0
    mov es:[di], cl    ; Сохраняем длину в Res
    inc di             ; Пропускаем байт длины
    inc si             ; Пропускаем байт длины в S
    jcxz CopyDone      ; Если строка пустая

CopyLoop:
    mov al, [si]
    mov es:[di], al
    inc si
    inc di
    loop CopyLoop

CopyDone:
    ; Проверяем, нужно ли добавлять пробелы
    les di, [bp+12]    ; ES:DI = Res (байт длины)
    mov al, es:[di]    ; Текущая длина Res
    cmp al, [bp+10]    ; Сравниваем с Len
    jae Exit           ; Если длина >= Len, выход

    ; Вычисляем количество пробелов для добавления
    mov bl, [bp+10]    ; Целевая длина
    sub bl, al         ; BL = delta

AddSpaces:
    ; Поиск позиций для вставки пробелов между словами
    mov cx, es:[di]    ; Текущая длина
    mov ch, 0
    inc di             ; ES:DI указывает на первый символ

FindInsertPos:
    mov si, di         ; ES:SI = начало строки
    add si, cx         ; ES:SI = конец строки
    dec si             ; Последний символ

    mov dx, 0          ; Индекс текущего символа

CheckLoop:
    cmp dx, cx
    jae EndCheck       ; Пройдена вся строка

    mov al, es:[si]
    cmp al, ' '
    jne NextChar       ; Текущий символ не пробел

    ; Проверяем предыдущий символ
    cmp dx, 0
    je NextChar        ; Первый символ - пробел, пропускаем

    mov al, es:[si-1]
    cmp al, ' '
    je NextChar        ; Предыдущий тоже пробел, пропускаем

    ; Нашли место для вставки (пробел между словами)
    ; Вставляем пробел
    push cx
    push si
    push di

    ; Сдвигаем символы вправо
    mov di, si
    inc di             ; Куда сдвигать
    mov cx, cx         ; CX = текущая длина
    sub cx, dx         ; Сколько символов сдвигать
    std                ; Направление с конца
    rep movsb
    cld

    ; Вставляем пробел
    mov byte ptr es:[si], ' '

    ; Увеличиваем длину строки
    les di, [bp+12]
    inc byte ptr es:[di]

    ; Уменьшаем delta
    dec bl
    jz Exit            ; Если пробелы добавлены

    pop di
    pop si
    pop cx

NextChar:
    inc dx
    inc si
    jmp CheckLoop

EndCheck:
    ; Если пробелы ещё нужно добавить
    jmp AddSpaces

Exit:
    pop dx
    pop cx
    pop bx
    pop ax
    pop di
    pop si
    pop es
    pop ds
    pop bp
    retf 10            ; Удаляем параметры из стека (4 + 2 + 4 = 10 байт)
InsBlanks ENDP

END
