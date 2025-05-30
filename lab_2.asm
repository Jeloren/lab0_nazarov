.model small
.stack 100h       ; Устанавливаем размер стека (256 байт)

extrn InsBlanks:near ; Объявляем внешнюю процедуру InsBlanks

.data
    input_string  db 'Hello man cycle',0 ; Исходная строка
    k             dw 26                 ; Желаемая длина
    word_count    dw 0                  ; Счетчик слов
    words         dw 20 dup(0)          ; Массив указателей на слова
    temp_buffer   db 256 dup('$')       ; Буфер для нормализованной строки
    result_buffer db 256 dup('$')       ; Буфер для результата
    newline       db 13,10,'$'          ; Перевод строки (CR+LF)

.code
main proc
    mov ax, @data  ; Загружаем адрес данных в DS и ES
    mov ds, ax
    mov es, ax

    ; Разбиваем строку на слова
    call split_string

    ; Собираем строку с одним пробелом между слов
    call build_temp_string

    ; Вызываем InsBlanks:
    ; 1. Адрес нормализованной строки
    ; 2. Желаемая длина (k)
    ; 3. Адрес буфера результата
    push offset temp_buffer
    push k
    push offset result_buffer
    call InsBlanks

    ; Выводим результат
    mov ah, 09h
    lea dx, result_buffer
    int 21h
    
    ; Выводим перевод строки
    lea dx, newline
    int 21h

    ; Завершаем программу
    mov ax, 4C00h
    int 21h
main endp

; Разбивает строку на слова, сохраняя указатели в массив words
split_string proc
    lea si, input_string ; SI = начало строки
    lea di, words        ; DI = массив указателей
    xor cx, cx           ; CX = счетчик слов

skip_spaces:
    lodsb                ; Читаем символ
    cmp al, 0            ; Если конец строки, завершаем
    je split_end
    cmp al, ' '          ; Пропускаем пробелы
    je skip_spaces

    ; Нашли начало слова
    dec si               ; Возвращаемся на первый символ слова
    mov [di], si         ; Сохраняем указатель на слово
    add di, 2            ; Переходим к следующему элементу массива
    inc cx               ; Увеличиваем счетчик слов

read_word:
    lodsb                ; Читаем символ
    cmp al, 0            ; Если конец строки, завершаем
    je word_end
    cmp al, ' '          ; Если пробел, завершаем слово
    jne read_word
    mov byte ptr [si-1], 0 ; Заменяем пробел на 0 (конец строки)
    jmp skip_spaces      ; Продолжаем поиск слов

word_end:
    dec si               ; Корректируем указатель
split_end:
    mov word_count, cx   ; Сохраняем количество слов
    ret
split_string endp

; Собирает строку с одним пробелом между словами
build_temp_string proc
    mov cx, word_count   ; CX = количество слов
    jcxz empty_temp      ; Если слов нет, пропускаем
    lea si, words        ; SI = массив указателей
    mov di, offset temp_buffer ; DI = буфер результата

    ; Копируем первое слово
    mov si, [si]         ; SI = адрес первого слова
copy_first:
    mov al, [si]         ; Читаем символ
    test al, al          ; Если конец слова, переходим дальше
    jz first_done
    stosb                ; Записываем символ в буфер  di = al; di++; lodsb al = si; si++ 
    inc si               ; Переходим к следующему
    jmp copy_first

first_done:
    ; Обрабатываем остальные слова
    mov cx, word_count
    dec cx               ; Количество промежутков = слов - 1
    jz temp_done         ; Если одно слово, завершаем
    lea bx, words + 2    ; BX = указатель на второе слово

next_temp_word:
    mov al, ' '          ; Вставляем пробел
    stosb
    mov si, [bx]         ; SI = адрес слова
    add bx, 2            ; Переходим к следующему слову
copy_word_temp:
    mov al, [si]         ; Копируем слово
    test al, al
    jz word_done_temp
    stosb
    inc si
    jmp copy_word_temp

word_done_temp:
    loop next_temp_word  ; Повторяем для всех слов

temp_done:
    mov byte ptr [di], 0 ; Завершаем строку нулем
    ret

empty_temp:
    mov byte ptr [temp_buffer], 0 ; Пустая строка
    ret
build_temp_string endp

end main