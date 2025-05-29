.model small
.stack 100h

.data
    input_string  db 'a b b c d d',0   ; Входная строка с нулевым окончанием
    k             dw 20                ; Параметр k
    word_count    dw 0                 ; Количество слов
    words         dw 20 dup(0)         ; Массив указателей на слова
    total_len     dw 0                 ; Общая длина всех слов
    b             dw 0                 ; Общее количество пробелов для вставки
    p             dw 0                 ; Базовое количество пробелов
    q             dw 0                 ; Дополнительные пробелы
    result_buffer db 256 dup('$')      ; Буфер результата (завершается '$')
    newline       db 13,10,'$'         ; Перевод строки для вывода

.code
main proc
    mov ax, @data
    mov ds, ax
    mov es, ax

    call split_string        ; Разбиваем строку на слова
    call calculate_total_len ; Вычисляем общую длину слов
    call adjust_k            ; Корректируем значение k
    call calc_p_and_q        ; Вычисляем p и q
    call build_result        ; Формируем результирующую строку

    ; Вывод результата
    mov ah, 09h
    lea dx, result_buffer
    int 21h
    
    ; Вывод перевода строки
    lea dx, newline
    int 21h

    ; Завершение программы
    mov ax, 4C00h
    int 21h
main endp

; Разбиение строки на слова
split_string proc
    lea si, input_string     ; SI = начало строки
    lea di, words            ; DI = массив указателей
    xor cx, cx               ; Счетчик слов = 0

skip_spaces:
    lodsb                    ; Загружаем символ
    cmp al, 0                ; Конец строки?
    je split_end
    cmp al, ' '              ; Пробел?
    je skip_spaces           ; Пропускаем пробелы

    ; Нашли начало слова
    dec si                   ; Возвращаемся к первому символу слова
    mov [di], si             ; Сохраняем указатель на слово
    add di, 2                ; Следующая позиция в массиве
    inc cx                   ; Увеличиваем счетчик слов

read_word:
    lodsb                    ; Читаем следующий символ
    cmp al, 0                ; Конец строки?
    je word_end
    cmp al, ' '              ; Пробел?
    jne read_word            ; Продолжаем, если не пробел
    
    ; Найден пробел - конец слова
    mov byte ptr [si-1], 0   ; Заменяем пробел на 0
    jmp skip_spaces          ; Ищем следующее слово

word_end:
    dec si                   ; Корректируем позицию для последнего слова
split_end:
    mov word_count, cx       ; Сохраняем количество слов
    ret
split_string endp

; Вычисление общей длины слов
calculate_total_len proc
    mov cx, word_count
    test cx, cx
    jz no_words              ; Если слов нет
    lea si, words            ; SI = массив указателей
    xor dx, dx               ; Общая длина = 0

word_loop:
    mov di, [si]             ; DI = текущее слово
    add si, 2                ; Следующий указатель
    xor ax, ax               ; Длина слова = 0

count_chars:
    cmp byte ptr [di], 0     ; Конец слова?
    je add_length
    inc ax                   ; Увеличиваем длину
    inc di                   ; Следующий символ
    jmp count_chars

add_length:
    add dx, ax               ; Добавляем к общей длине
    loop word_loop

no_words:
    mov total_len, dx        ; Сохраняем результат
    ret
calculate_total_len endp

; Корректировка значения k
adjust_k proc
    mov ax, word_count
    shl ax, 1                ; AX = 2 * word_count
    dec ax                   ; AX = 2 * word_count - 1
    cmp ax, k                ; Сравниваем с k
    jbe adjust_end
    mov k, ax                ; Обновляем k если нужно
adjust_end:
    ret
adjust_k endp

; Вычисление p и q
calc_p_and_q proc
    mov ax, k
    sub ax, total_len        ; AX = b (общее кол-во пробелов)
    mov b, ax

    mov cx, word_count
    dec cx                   ; CX = кол-во промежутков (n-1)
    jz no_gaps               ; Если слов < 2

    xor dx, dx
    div cx                   ; AX = p (частное), DX = q (остаток)
    mov p, ax
    mov q, dx
    ret

no_gaps:
    mov p, 0
    mov q, 0
    ret
calc_p_and_q endp

; Формирование результата
build_result proc
    mov cx, word_count
    jcxz empty_result        ; Если нет слов

    ; Копируем первое слово
    lea si, words
    mov di, offset result_buffer
    mov si, [si]            ; SI = первое слово

copy_first_word:
    lodsb                    ; Копируем символы
    test al, al
    jz first_word_end
    stosb
    jmp copy_first_word
first_word_end:

    ; Обработка остальных слов
    mov cx, word_count
    dec cx                   ; Кол-во оставшихся слов
    jz finish_result         ; Если только одно слово

    lea si, words + 2        ; Указатель на 2-е слово
    xor bx, bx               ; Индекс текущего слова (для q)

next_word:
    push cx
    push si

    ; Вставляем пробелы
    mov cx, p
    cmp bx, q                ; Сравниваем индекс с q
    jb extra_space
    jmp insert_spaces
extra_space:
    inc cx                   ; p+1 пробелов
insert_spaces:
    jcxz after_spaces
    mov al, ' '
    rep stosb                ; Вставляем пробелы
after_spaces:

    pop si                   ; Восстанавливаем указатель
    mov bp, si               ; Сохраняем указатель массива
    mov si, [si]             ; SI = текущее слово

    ; Копируем слово
copy_word:
    lodsb
    test al, al
    jz word_copied
    stosb
    jmp copy_word
word_copied:
    mov si, bp               ; Восстанавливаем указатель массива
    add si, 2                ; Следующее слово

    pop cx
    inc bx                   ; Увеличиваем индекс
    loop next_word

finish_result:
    mov byte ptr [di], '$'   ; Завершаем строку
    ret

empty_result:
    mov di, offset result_buffer
    mov byte ptr [di], '$'   ; Пустая строка
    ret
build_result endp

end main