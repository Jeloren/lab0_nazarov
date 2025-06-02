.model small
.stack 100h       ; Устанавливаем размер стека (256 байт)

extrn InsBlanks:near ; Объявляем внешнюю процедуру InsBlanks

.data
    input_string  db 'Hello asm world',0 ; Исходная строка
    k             dw 26                 ; Желаемая длина
    result_buffer db 256 dup('$')       ; Буфер для результата
    words_buffer  dw 20 dup(0)          ; Массив указателе на слова
    temp_buffer   db 256 dup('$')       ; Буфер для нормализованной строки
    newline       db 13,10,'$'          ; Перевод строки (CR+LF)

.code
main proc
    mov ax, @data  ; Загружаем адрес данных в DS и ES
    mov ds, ax
    mov es, ax

    ; Вызов InsBlanks с 5 параметрами:
    push offset input_string   ; Адрес исходной строки
    push k                     ; Желаемая длина
    push offset result_buffer  ; Буфер для результата
    push offset words_buffer   ; Буфер для массива слов
    push offset temp_buffer    ; Буфер для нормализованной строки
    call InsBlanks

    ; Выводим результат
    mov ah, 09h  ; в ah заносится команда вызова, 
    lea dx, result_buffer ; заносит в dx result_buffer
    int 21h
    
    ; Выводим перевод строки
    lea dx, newline
    int 21h

    ; Завершаем программу
    mov ax, 4C00h
    int 21h
main endp

end main