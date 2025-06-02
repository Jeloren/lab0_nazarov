.model small
.386
public InsBlanks

.code
InsBlanks proc near
    push bp
    mov bp, sp
    push si
    push di
    push bx
    push cx
    push dx

    mov si, [bp+8]   ; Адрес исходной строки
    mov di, [bp+4]   ; Адрес буфера результата
    mov bx, [bp+6]   ; Требуемая длина (k)

    ; Проверка на пустую строку
    cmp byte ptr [si], 0
    je copy_direct

    ; Подсчет длины строки и количества слов
    xor cx, cx        ; длина строки
    xor dx, dx        ; счетчик слов
    mov ah, 0         ; флаг внутри слова (0=нет, 1=да)

count_loop:
    mov al, [si]
    cmp al, 0         ; конец строки?
    je end_count
    inc cx            ; увеличиваем длину
    cmp al, ' '
    je space_char
    
    ; Обработка НЕ-пробела
    test ah, ah       ; уже внутри слова?
    jnz not_new_word
    inc dx            ; новое слово
    mov ah, 1         ; устанавливаем флаг "внутри слова"
not_new_word:
    jmp next_char

space_char:
    mov ah, 0         ; сбрасываем флаг "внутри слова"
next_char:
    inc si
    jmp count_loop

end_count:
    ; Восстановление указателя на начало строки
    mov si, [bp+8]
    
    ; Проверка необходимости обработки
    cmp cx, bx         ; сравнение текущей длины с k
    jae copy_direct    ; если >=, копируем без изменений
    test dx, dx        ; если слов нет
    jz copy_direct
    cmp dx, 1          ; если только одно слово
    je handle_single_word

    ; Вычисление параметров для распределения пробелов
    mov ax, bx         ; ax = k
    sub ax, cx         ; ax = количество пробелов для добавления
    mov cx, dx         ; cx = количество слов
    dec cx             ; cx = количество промежутков (n-1)
    
    ; Вычисление p и q
    xor dx, dx
    div cx             ; ax = p, dx = q
    
    ; Инициализация
    xor cx, cx         ; счетчик промежутков (индекс текущего промежутка)
    mov bx, ax         ; сохраняем p в bx

copy_loop:
    mov al, [si]
    inc si
    test al, al        ; конец строки?
    jz end_ins
    
    cmp al, ' '
    jne copy_char
    
    ; Обработка пробела: вставляем дополнительные пробелы
    push cx            ; сохраняем счетчик промежутков
    mov cx, 1          ; минимум 1 пробел
    add cx, bx         ; + p пробелов
    
    ; Проверяем, нужно ли добавить дополнительный пробел
    pop ax             ; ax = текущий индекс промежутка
    cmp ax, dx         ; сравнение с q
    jae no_extra
    inc cx             ; добавляем дополнительный пробел
no_extra:
    push ax            ; сохраняем индекс обратно
    
    ; Вставляем пробелы
    mov al, ' '
insert_spaces:
    mov [di], al
    inc di
    loop insert_spaces
    
    pop cx             ; восстанавливаем индекс промежутка
    inc cx             ; увеличиваем индекс промежутка
    jmp copy_loop

copy_char:
    mov [di], al
    inc di
    jmp copy_loop

end_ins:
    mov byte ptr [di], 0
    jmp done

handle_single_word:
    ; Копируем слово
    mov al, [si]
    test al, al
    jz add_tail_spaces
    mov [di], al
    inc di
    inc si
    jmp handle_single_word

add_tail_spaces:
    ; Добавляем пробелы в конец
    mov ax, [bp+6]    ; k
    sub ax, cx        ; ax = количество пробелов для добавления
    mov cx, ax
    jle done_tail     ; если не нужно добавлять пробелы
    mov al, ' '
rep stosb
done_tail:
    mov byte ptr [di], 0
    jmp done

copy_direct:
    ; Простое копирование строки
    mov al, [si]
    mov [di], al
    inc si
    inc di
    test al, al
    jnz copy_direct

done:
    pop dx
    pop cx
    pop bx
    pop di
    pop si
    pop bp
    ret 6
InsBlanks endp
end