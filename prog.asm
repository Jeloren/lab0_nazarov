.model small       ; Модель памяти small (64KB для кода и данных)
.386               ; Используем 386 инструкции
public InsBlanks   ; Делаем процедуру InsBlanks доступной из других модулей

.code
InsBlanks proc near
    push bp        ; Сохраняем BP (базовый указатель стека)
    mov bp, sp     ; Устанавливаем BP на текущую вершину стека
    push si        ; Сохраняем регистры, которые будем использовать
    push di
    push bx
    push cx
    push dx

    ; Загружаем параметры из стека
    mov si, [bp+8] ; SI = адрес исходной строки (1-й аргумент)
    mov di, [bp+4] ; DI = адрес буфера результата (3-й аргумент)
    mov bx, [bp+6] ; BX = требуемая длина k (2-й аргумент)

    ; Проверка на пустую строку
    cmp byte ptr [si], 0
    je copy_direct ; Если строка пустая, переходим к копированию

    ; Подсчет длины строки (CX) и количества слов (DX)
    xor cx, cx     ; CX = длина строки
    xor dx, dx     ; DX = количество слов
    mov ah, 0      ; AH = флаг "внутри слова" (0 = нет, 1 = да)

count_loop:
    mov al, [si]   ; Читаем символ из строки
    cmp al, 0      ; Если конец строки (0), выходим
    je end_count
    inc cx         ; Увеличиваем длину строки
    cmp al, ' '    ; Если пробел, обрабатываем
    je space_char
    
    ; Обработка НЕ-пробела (часть слова)
    test ah, ah    ; Проверяем, внутри ли слова
    jnz not_new_word ; Если уже внутри слова, пропускаем
    inc dx         ; Иначе увеличиваем счетчик слов
    mov ah, 1      ; Устанавливаем флаг "внутри слова"
not_new_word:
    jmp next_char

space_char:
    mov ah, 0      ; Сбрасываем флаг "внутри слова"
next_char:
    inc si         ; Переходим к следующему символу
    jmp count_loop

end_count:
    ; Восстанавливаем указатель на начало строки
    mov si, [bp+8]

    ; Проверяем, нужно ли добавлять пробелы
    cmp cx, bx     ; Если текущая длина >= k, просто копируем
    jae copy_direct
    test dx, dx    ; Если слов нет, копируем
    jz copy_direct
    cmp dx, 1      ; Если только одно слово, обрабатываем отдельно
    je handle_single_word

    ; Вычисляем, сколько пробелов добавить
    mov ax, bx     ; AX = k
    sub ax, cx     ; AX = количество пробелов для добавления
    mov cx, dx     ; CX = количество слов
    dec cx         ; CX = количество промежутков (n-1)
    
    ; Делим пробелы между промежутками
    xor dx, dx
    div cx         ; AX = p (базовые пробелы), DX = q (доп. пробелы)
    
    ; Начинаем копирование с добавлением пробелов
    xor cx, cx     ; CX = счетчик промежутков
    mov bx, ax     ; BX = p

copy_loop:
    mov al, [si]   ; Читаем символ
    inc si
    test al, al    ; Если конец строки, завершаем
    jz end_ins
    
    cmp al, ' '    ; Если пробел, добавляем дополнительные
    jne copy_char
    
    ; Вставляем пробелы
    push cx        ; Сохраняем счетчик промежутков
    mov cx, 1      ; Минимум 1 пробел
    add cx, bx     ; Добавляем p пробелов
    
    ; Проверяем, нужно ли добавить еще один пробел (если q > 0)
    pop ax         ; AX = текущий промежуток
    cmp ax, dx     ; Сравниваем с q
    jae no_extra   ; Если >= q, не добавляем
    inc cx         ; Иначе добавляем 1 пробел
no_extra:
    push ax        ; Восстанавливаем счетчик
    
    ; Вставляем пробелы в буфер результата
    mov al, ' '
insert_spaces:
    mov [di], al
    inc di
    loop insert_spaces
    
    pop cx         ; Восстанавливаем счетчик промежутков
    inc cx         ; Увеличиваем его
    jmp copy_loop

copy_char:
    mov [di], al   ; Копируем символ в результат
    inc di
    jmp copy_loop

end_ins:
    mov byte ptr [di], 0 ; Завершаем строку нулем
    jmp done

handle_single_word:
    ; Копируем слово и добавляем пробелы в конец
    mov al, [si]
    test al, al
    jz add_tail_spaces
    mov [di], al
    inc di
    inc si
    jmp handle_single_word

add_tail_spaces:
    ; Добавляем пробелы до длины k
    mov ax, [bp+6] ; AX = k
    sub ax, cx     ; AX = количество пробелов
    mov cx, ax
    jle done_tail  ; Если <= 0, пропускаем
    mov al, ' '
    rep stosb      ; Заполняем пробелами
done_tail:
    mov byte ptr [di], 0
    jmp done

copy_direct:
    ; Просто копируем строку без изменений
    mov al, [si]
    mov [di], al
    inc si
    inc di
    test al, al
    jnz copy_direct

done:
    pop dx         ; Восстанавливаем регистры
    pop cx
    pop bx
    pop di
    pop si
    pop bp
    ret 6          ; Возврат с очисткой 6 байт аргументов
InsBlanks endp
end