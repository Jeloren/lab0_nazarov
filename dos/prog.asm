.model small       ; Модель памяти small (64KB для кода и данных)
.386               ; Используем 386 инструкции
public InsBlanks   ; Делаем процедуру InsBlanks доступной из других модулей

.code
InsBlanks proc near
    push bp        ; Сохраняем BP
    mov bp, sp     ; Устанавливаем BP на стек
    pusha          ; Сохраняем все регистры

    ; Загрузка параметров:
    ; [bp+4]  = temp_buffer
    ; [bp+6]  = words_buffer
    ; [bp+8]  = result_buffer
    ; [bp+10] = k
    ; [bp+12] = input_string

    ; 1. Разбиваем строку на слова
    mov si, [bp+12]   ; SI = input_string
    mov di, [bp+6]    ; DI = words_buffer
    xor cx, cx        ; CX = счётчик слов

skip_spaces:
    lodsb             ; Читаем символ
    cmp al, 0         ; Конец строки?
    je split_end
    cmp al, ' '       ; Пропускаем пробелы
    je skip_spaces

    ; Начало слова
    dec si            ; Возвращаемся к первому символу
    mov [di], si      ; Сохраняем указатель
    add di, 2         ; Следующий элемент массива
    inc cx            ; Увеличиваем счётчик слов

read_word:
    lodsb             ; Читаем символ
    cmp al, 0         ; Конец строки?
    je word_end
    cmp al, ' '       ; Конец слова?
    jne read_word
    mov byte ptr [si-1], 0 ; Заменяем пробел на 0
    jmp skip_spaces

word_end:
    dec si            ; Корректируем указатель
split_end:
    push cx           ; Сохраняем количество слов

    ; 2. Собираем нормализованную строку
    mov di, [bp+4]    ; DI = temp_buffer
    pop cx            ; Восстанавливаем CX (количество слов)
    jcxz empty_temp   ; Если слов нет

    ; Копируем первое слово
    mov si, [bp+6]    ; SI = words_buffer
    mov si, [si]      ; SI = адрес первого слова
copy_first:
    mov al, [si]
    test al, al       ; Конец слова?
    jz first_done
    mov [di], al      ; Копируем символ
    inc di
    inc si
    jmp copy_first

first_done:
    push cx           ; Сохраняем количество слов
    pop cx            ; Восстанавливаем CX
    dec cx            ; Оставшиеся слова
    jz temp_done      ; Если только одно слово

    mov si, [bp+6]    ; SI = words_buffer
    add si, 2         ; Переходим ко второму слову
next_temp_word:
    mov al, ' '       ; Добавляем пробел
    mov [di], al
    inc di
    mov bx, [si]      ; BX = адрес слова
    add si, 2         ; Следующее слово
copy_word_temp:
    mov al, [bx]
    test al, al       ; Конец слова?
    jz word_done_temp
    mov [di], al      ; Копируем символ
    inc di
    inc bx
    jmp copy_word_temp

word_done_temp:
    loop next_temp_word ; Повторяем для всех слов

temp_done:
    mov byte ptr [di], 0 ; Завершаем строку
    jmp after_build

empty_temp:
    mov byte ptr [di], 0 ; Пустая строка

after_build:
    ; 3. Вставляем пробелы для достижения длины k
    mov si, [bp+4]    ; SI = temp_buffer
    mov di, [bp+8]    ; DI = result_buffer
    mov bx, [bp+10]   ; BX = k

    ; Проверка на пустую строку
    cmp byte ptr [si], 0
    je copy_direct

    ; Подсчёт длины и количества слов
    xor cx, cx        ; Длина строки
    xor dx, dx        ; Количество слов
    mov ah, 0         ; Флаг внутри слова
count_loop:
    mov al, [si]
    cmp al, 0         ; Конец строки?
    je end_count
    inc cx            ; Увеличиваем длину
    cmp al, ' '       ; Пробел?
    je space_char

    ; Обработка буквы
    test ah, ah       ; Уже внутри слова?
    jnz not_new_word
    inc dx            ; Новое слово
    mov ah, 1         ; Устанавливаем флаг
not_new_word:
    jmp next_char

space_char:
    mov ah, 0         ; Сбрасываем флаг
next_char:
    inc si
    jmp count_loop

end_count:
    mov si, [bp+4]    ; Восстанавливаем начало строки
    cmp cx, bx        ; Текущая длина >= k?
    jae copy_direct
    test dx, dx       ; Нет слов?
    jz copy_direct
    cmp dx, 1         ; Одно слово?
    je handle_single_word

    ; Вычисляем пробелы для добавления
    mov ax, bx        ; AX = k
    sub ax, cx        ; AX = всего пробелов
    mov cx, dx        ; CX = количество слов
    dec cx            ; Промежутки = слов - 1
    xor dx, dx
    div cx            ; AX = p, DX = q

    ; Вставляем пробелы
    xor cx, cx        ; Счётчик промежутков
    mov bx, ax        ; BX = p
copy_loop:
    mov al, [si]      ; Читаем символ
    inc si
    test al, al       ; Конец строки?
    jz end_ins
    cmp al, ' '       ; Пробел?
    jne copy_char

    ; Обработка пробела
    push cx           ; Сохраняем счётчик
    mov cx, 1         ; Базовый пробел
    add cx, bx        ; + p пробелов
    pop ax            ; AX = текущий промежуток
    cmp ax, dx        ; Сравниваем с q
    jae no_extra
    inc cx            ; Добавляем дополнительный пробел
no_extra:
    push ax           ; Сохраняем обратно
    mov al, ' '       ; Вставляем пробелы
insert_spaces:
    mov [di], al
    inc di
    loop insert_spaces
    pop cx            ; Восстанавливаем счётчик
    inc cx            ; Следующий промежуток
    jmp copy_loop

copy_char:
    mov [di], al      ; Копируем символ
    inc di
    jmp copy_loop

end_ins:
    mov byte ptr [di], 0 ; Конец строки
    jmp done_ins

handle_single_word:
    ; Обработка одного слова
    mov si, [bp+4]    ; Начало строки
    xor cx, cx        ; Длина слова
count_single_len:
    cmp byte ptr [si], 0
    je end_count_single
    inc cx
    inc si
    jmp count_single_len
end_count_single:
    mov si, [bp+4]    ; Восстанавливаем начало
copy_single_word:
    mov al, [si]
    test al, al       ; Конец слова?
    jz add_tail_spaces
    mov [di], al
    inc di
    inc si
    jmp copy_single_word

add_tail_spaces:
    mov ax, [bp+10]   ; AX = k
    sub ax, cx        ; Пробелы для добавления
    mov cx, ax
    jle done_tail     ; Если <=0, пропускаем
    mov al, ' '
    rep stosb         ; Заполняем пробелами
done_tail:
    mov byte ptr [di], 0 ; Конец строки
    jmp done_ins

copy_direct:
    ; Простое копирование
    mov al, [si]
    mov [di], al
    inc si
    inc di
    test al, al
    jnz copy_direct

done_ins:
    popa              ; Восстанавливаем регистры
    pop bp
    ret 10            ; Возврат с очисткой стека (5 аргументов)
InsBlanks endp
end