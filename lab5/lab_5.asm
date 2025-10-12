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
; ПРОЦЕДУРА РАСШИРЕНИЯ БИТОВОЙ СТРОКИ
; Вход:
;   DS:BX - исходная строка
;   FS:DX - результирующая строка
;   [cite_start]CX    - длина в битах [cite: 260]
; ---------------------------------------------------------------
BIT_EXPAND_PROC PROC
    PUSH    AX
    PUSH    BX
    PUSH    CX
    PUSH    DX
    PUSH    SI
    PUSH    DI

    MOV     SI, BX          ; источник: DS:SI
    MOV     DI, DX          ; приёмник: FS:DI

    XOR     BL, BL          ; BL = текущий байт результата
    XOR     BH, BH          ; BH = счётчик бита источника (0..7)
    MOV     DH, 0           ; DH = счётчик бита приёмника (0..7)

    MOV     AL, [SI]        ;  Загружаем первый байт источника

EXPAND_LOOP:
    OR      CX, CX
    JZ      WRITE_LAST

    ; --- Извлекаем бит номер BH из AL ---
    MOV     AH, AL
    PUSH    CX              ;  Сохраняем CX перед использованием CL
    MOV     CL, BH
    SHR     AH, CL
    POP     CX              ;  Восстанавливаем CX
    AND     AH, 1

    ; --- Преобразуем: 0 -> 01 (1), 1 -> 10 (2) ---
    CMP     AH, 0
    JNE     SET_10
    MOV     AH, 1
    JMP     INSERT
SET_10:
    MOV     AH, 2

INSERT:
    ; --- Вставляем AH (2 бита) в BL на позицию DH ---
    PUSH    CX              ;  Снова сохраняем CX
    MOV     CL, DH
    SHL     AH, CL
    POP     CX              ;  Снова восстанавливаем CX
    OR      BL, AH

    ; --- Обновляем счётчики ---
    INC     BH              ; Следующий бит источника
    CMP     BH, 8
    JB      NO_SRC_NEXT
    ; Нужен следующий байт источника
    INC     SI
    MOV     AL, [SI]        ;  Загружаем следующий байт
    XOR     BH, BH          ; Сбрасываем счётчик битов источника
NO_SRC_NEXT:

    ADD     DH, 2           ; Мы вставили 2 бита
    CMP     DH, 8
    JB      NO_DST_WRITE
    ; Байт приёмника заполнен, записываем его
    MOV     FS:[DI], BL
    INC     DI
    XOR     BL, BL          ; Очищаем аккумулятор результата
    XOR     DH, DH          ; Сбрасываем счётчик битов приёмника
NO_DST_WRITE:

    DEC     CX
    JMP     EXPAND_LOOP

WRITE_LAST:
    ; Записываем последний неполный байт, если он есть
    CMP     DH, 0
    JE      DONE
    MOV     FS:[DI], BL

DONE:
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
SOURCE_STR  DB  15h, 0      ; 00010101b
RESULT_STR  DB  3 DUP(0)    ; Буфер для результата

CSEG    ENDS
END start