.386
CSEG    SEGMENT PARA USE16 'CODE'
    ASSUME  CS:CSEG,DS:CSEG,SS:CSEG
    ORG     100h

start:
    ; Инициализация сегментов
    MOV     AX, CS
    MOV     DS, AX
    MOV     ES, AX
    MOV     FS, AX

    ; Подготовка параметров для процедуры
    MOV     BX, OFFSET SOURCE_STR   ; DS:BX - адрес исходной строки
    MOV     DX, OFFSET RESULT_STR   ; FS:DX - адрес результирующей строки
    MOV     CX, 5                   ; Длина в битах
    
    CALL    BIT_EXPAND_PROC

    ; Завершение программы
    MOV     AX, 4C00h
    INT     21h

; ---------------------------------------------------------------
; ПРОЦЕДУРА РАСШИРЕНИЯ БИТОВОЙ СТРОКИ (Вариант 5)
; Вход:
;   DS:BX - исходная строка
;   FS:DX - результирующая строка
;   CX    - длина в битах [cite: 260]
; ---------------------------------------------------------------
BIT_EXPAND_PROC PROC
    PUSH    AX
    PUSH    BX
    PUSH    CX
    PUSH    DX
    PUSH    SI
    PUSH    DI
    PUSH    BP              ; Сохраняем BP, т.к. используем его для счетчика

    MOV     SI, BX          ; источник: DS:SI
    MOV     DI, DX          ; приёмник: FS:DI

    XOR     BX, BX          ; Bx = номер бита результата (аккумулятор)
    XOR     BP, BP          ; BP = счётнмоер бита чик бита источника (0..7) [ИЗМЕНЕНО]

    JCXZ DONE
EXPAND_LOOP:
    BT     [SI], BP
    JC      SET_10         
    BTR [DI], BX
    INC BX 
    BTS [DI], BX
    JMP NEXT
SET_10:
    BTS [DI], BX
    INC BX 
    BTR [DI], BX


NEXT:
    INC    BX         
    INC BP     ; Увеличиваем номер бита приёмника на 1
    LOOP    EXPAND_LOOP

DONE:
    POP     BP              ; Восстанавливаем BP
    POP     DI
    POP     SI
    POP     DX
    POP     CX
    POP     BX
    POP     AX
    RET
BIT_EXPAND_PROC ENDP

; -----------------------------
; Данные
; -----------------------------
SOURCE_STR  DB  15h, 0      ; 00010101b.
RESULT_STR  DB  3 DUP(0)    ; Буфер для результата (5 бит -> 10 бит -> 2 байта)
                            ; 3 байта - с запасом

CSEG    ENDS
END start