.model small
.stack 100h

extrn InsBlanks:near

.data
    input_string  db 'Hello man cycle',0   ; Входная строка
    k             dw 26                ; Требуемая длина
    word_count    dw 0                 ; Количество слов
    words         dw 20 dup(0)         ; Массив указателей на слова
    temp_buffer   db 256 dup('$')      ; Буфер для строки с одним пробелом между словами
    result_buffer db 256 dup('$')      ; Буфер для результата
    newline       db 13,10,'$'         ; Перевод строки

.code
main proc
    mov ax, @data
    mov ds, ax
    mov es, ax

    call split_string        ; Разбиваем строку на слова
    call build_temp_string   ; Формируем строку с одним пробелом между словами

    ; Вызов подпрограммы InsBlanks
    push offset temp_buffer   ; Адрес временной строки
    push k                   ; Требуемая длина
    push offset result_buffer ; Адрес буфера результата
    call InsBlanks

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
    lea si, input_string
    lea di, words
    xor cx, cx

skip_spaces:
    lodsb
    cmp al, 0
    je split_end
    cmp al, ' '
    je skip_spaces

    dec si
    mov [di], si
    add di, 2
    inc cx

read_word:
    lodsb
    cmp al, 0
    je word_end
    cmp al, ' '
    jne read_word
    mov byte ptr [si-1], 0
    jmp skip_spaces

word_end:
    dec si
split_end:
    mov word_count, cx
    ret
split_string endp

; Формирование строки с одним пробелом между словами
build_temp_string proc
    mov cx, word_count
    jcxz empty_temp
    lea si, words
    mov di, offset temp_buffer

    ; Копируем первое слово
    mov si, [si]
copy_first:
    mov al, [si]
    test al, al
    jz first_done
    stosb
    inc si
    jmp copy_first
first_done:

    ; Обработка остальных слов
    mov cx, word_count
    dec cx
    jz temp_done
    lea bx, words + 2

next_temp_word:
    mov al, ' '
    stosb
    mov si, [bx]
    add bx, 2
copy_word_temp:
    mov al, [si]
    test al, al
    jz word_done_temp
    stosb
    inc si
    jmp copy_word_temp
word_done_temp:
    loop next_temp_word

temp_done:
    mov byte ptr [di], 0   ; Завершаем 0 вместо '$'
    ret

empty_temp:
    mov byte ptr [temp_buffer], 0
    ret
build_temp_string endp

end main