; sseg segment stack 'stack'
;  dw 256 dup(?)
; sseg ends

; data segment
; msg1 db 10,13,'Programm a-b',10,13,'a: ','$'
; msg2 db 10,13,'b: ','$'
; msg3 db 10,13,'a-b = ','$'
; data ends

; code segment
; assume cs:code,ds:data,ss:sseg
; start: 
;  mov ax,data
;  mov ds,ax
;  lea dx,msg1
;  call print_msg
;  call input_digit
;  mov bl,al
;  lea dx,msg2
;  call print_msg
;  call input_digit
;  lea dx,msg3
;  call print_msg
;  call sub_and_show
;  mov ah,4ch
;  int 21h

; print_msg proc
;  push ax
;  mov ah,09h
;  int 21h
;  pop ax
;  ret
; print_msg endp

; input_digit proc
; input_again:
;  mov ah,01h
;  int 21h
;  cmp al,'0'
;  jl input_again
;  cmp al,'9'
;  jg input_again
;  sub al,30h
;  ret
; input_digit endp

; sub_and_show proc
;  sub bl,al ; Вычитание (BL = BL - AL)
;  jns not_carry ; Если результат не отрицательный, перейти к not_carry
;  neg bl ; Инвертировать результат, если отрицательный
;  mov ah,2h
;  mov dl,'-' ; Вывести знак минус
;  int 21h
; not_carry: 
;  add bl,30h ; Преобразовать число в символ
;  mov ah,2h
;  mov dl,bl ; Вывести результат
;  int 21h
;  ret
; sub_and_show endp

; code ends
; end start




sseg segment stack 'stack'  ; Сегмент стека
    dw 256 dup(?)           ; Резервируем 256 слов для стека
sseg ends

data segment                ; Сегмент данных
    lim dw 3                ; Константа LIM = 3 (теперь слово)
    msg1 db 10,13,'Programm: DEC_AND_JUMP',10,13,'$'
    msg2 db 10,13,'CX = 5, LIM = 3',10,13,'$'
    msg3 db 10,13,'CX after decrement: ','$'
data ends

code segment                ; Сегмент кода
assume cs:code, ds:data, ss:sseg

start: 
    mov ax, data            ; Загружаем адрес сегмента данных в AX
    mov ds, ax              ; Устанавливаем DS на сегмент данных

    ; Выводим сообщение о программе
    lea dx, msg1
    call print_msg

    ; Выводим начальные значения
    lea dx, msg2
    call print_msg

    ; Инициализируем CX = 5
    mov cx, 5

begin: 
    ; Выводим текущее значение CX
    lea dx, msg3
    call print_msg
    call show_cx

    ; Вызов макроса: уменьшаем CX на 1, переходим к exit, если CX == LIM
    dec_and_jump cx, lim, exit

    ; Возвращаемся к метке begin
    jmp begin

exit: 
    ; Завершение программы
    mov ah, 4ch
    int 21h

; Процедура для вывода сообщения
print_msg proc
    push ax
    mov ah, 09h             ; Функция DOS для вывода строки
    int 21h
    pop ax
    ret
print_msg endp

; Процедура для вывода значения CX
show_cx proc
    push ax
    push dx
    mov ah, 02h             ; Функция DOS для вывода символа
    mov dl, ch              ; Выводим старший байт CX (если нужно)
    add dl, 30h             ; Преобразуем число в символ
    int 21h
    mov dl, cl              ; Выводим младший байт CX
    add dl, 30h             ; Преобразуем число в символ
    int 21h
    pop dx
    pop ax
    ret
show_cx endp

; Макрос для декремента и перехода
dec_and_jump macro reg, lim, dest_label
    local skip_jump         ; Локальная метка
    dec reg                 ; Уменьшаем регистр на 1
    cmp reg, lim            ; Сравниваем с LIM
    je dest_label           ; Переходим к метке, если равны
skip_jump:
endm

code ends
end start