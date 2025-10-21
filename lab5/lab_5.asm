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

    XOR     BL, BL          ; BL = текущий байт результата (аккумулятор)
    XOR     BP, BP          ; BP = счётчик бита источника (0..7) [ИЗМЕНЕНО]
    MOV     DH, 0           ; DH = счётчик бита приёмника (0..7)

    MOV     AL, [SI]        ; Загружаем первый байт источника
    XOR     AH, AH          ; Очищаем AH, т.к. BT работает с AX [ДОБАВЛЕНО]

EXPAND_LOOP:
    OR      CX, CX
    JZ      WRITE_LAST      ; Если CX=0, биты кончились, выходим

    ; --- Извлекаем бит номер BP из AX с помощью BT ---
    ; BT (Bit Test) - команда 80386
    ; Синтаксис: BT r/m16, r16 
    ; Мы используем: BT AX, BP
    ; AX (r/m16) содержит байт (в AL)
    ; BP (r16) содержит номер бита (0-7)
    BT      AX, BP          ; [ИЗМЕНЕНО, было BT AL, BH]

    ; --- Преобразуем: 0 -> 01 (1), 1 -> 10 (2) ---
    JC      SET_10          ; Если CF=1 (бит был 1), идем ставить 2 (10b)
    MOV     AH, 1           ; CF=0 (бит был 0). AH = 1 (01b)
    JMP     INSERT
SET_10:
    MOV     AH, 2           ; CF=1 (бит был 1). AH = 2 (10b)

INSERT:
    ; --- Вставляем AH (2 бита: 01b или 10b) в BL на позицию DH ---
    PUSH    CX              ; Сохраняем CX, так как CL нужен для SHL
    MOV     CL, DH
    SHL     AH, CL          ; Сдвигаем 2 бита (01 или 10) на нужную позицию
    POP     CX              ; Восстанавливаем CX
    OR      BL, AH          ; Вставляем биты в байт-аккумулятор

    ; --- Обновляем счётчики ---
    INC     BP              ; Следующий бит источника [ИЗМЕНЕНО, было INC BH]
    CMP     BP, 8           ; [ИЗМЕНЕНО, было CMP BH, 8]
    JB      NO_SRC_NEXT
    ; Нужен следующий байт источника
    INC     SI
    MOV     AL, [SI]        ; Загружаем следующий байт
    XOR     AH, AH          ; Снова очищаем AH [ДОБАВЛЕНО]
    XOR     BP, BP          ; Сбрасываем счётчик битов источника [ИЗМЕНЕНО]
NO_SRC_NEXT:

    ADD     DH, 2           ; Мы вставили 2 бита
    CMP     DH, 8
    JB      NO_DST_WRITE
    ; Байт приёмника (BL) заполнен, записываем его
    MOV     FS:[DI], BL
    INC     DI
    XOR     BL, BL          ; Очищаем аккумулятор результата
    XOR     DH, DH          ; Сбрасываем счётчик битов приёмника
NO_DST_WRITE:

    DEC     CX              ; Уменьшаем счетчик обработанных бит
    JMP     EXPAND_LOOP

WRITE_LAST:
    ; Записываем последний неполный байт, если он есть
    CMP     DH, 0
    JE      DONE
    MOV     FS:[DI], BL     ; Записываем остаток

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