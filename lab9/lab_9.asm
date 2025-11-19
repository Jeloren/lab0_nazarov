; lab9.asm
; Вариант 10: Установка задержки и скорости повтора клавиатуры
include lab_9.inc

.386
.model FLAT, STDCALL

.DATA
    ; Сообщения пользователю
    msgTitle    DB "Lab 9, Var 10: Keyboard Control", 0Dh, 0Ah, 0
    msgDelay    DB 0Dh, 0Ah, "Enter Delay (0=250ms to 3=1sec): ", 0
    msgSpeed    DB "Enter Speed (0=Slow to 31=Fast): ", 0
    msgDone     DB 0Dh, 0Ah, "Settings applied successfully!", 0Dh, 0Ah, 0
    msgError    DB 0Dh, 0Ah, "Error applying settings.", 0Dh, 0Ah, 0
    
    ; Буферы
    hStdOut     DD ?
    hStdIn      DD ?
    ReadBuf     DB 10 DUP(0)
    BytesRead   DD ?
    BytesWritten DD ?
    
    ; Переменные для хранения введенных чисел
    ValDelay    DD ?
    ValSpeed    DD ?

.CODE
Start:
    ; 1. Получение дескрипторов ввода и вывода [cite: 11, 193]
    PUSH STD_OUTPUT_HANDLE
    CALL GetStdHandle
    MOV hStdOut, EAX

    PUSH STD_INPUT_HANDLE
    CALL GetStdHandle
    MOV hStdIn, EAX

    ; 2. Вывод заголовка
    PUSH OFFSET msgTitle
    CALL PrintStr

    ; ---------------------------------------------------------
    ; 3. Ввод и установка ЗАДЕРЖКИ (Delay)
    ; ---------------------------------------------------------
    PUSH OFFSET msgDelay
    CALL PrintStr

    CALL ReadNum        ; Читаем число в EAX
    MOV ValDelay, EAX   ; Сохраняем

    ; Вызов SystemParametersInfo для Delay
    ; BOOL SystemParametersInfoA(uiAction, uiParam, pvParam, fWinIni);
    PUSH SPIF_SENDCHANGE      ; Обновить сразу
    PUSH NULL                 ; pvParam (не используется для этой команды)
    PUSH ValDelay             ; uiParam (наше значение 0-3)
    PUSH SPI_SETKEYBOARDDELAY ; uiAction
    CALL SystemParametersInfo
    
    CMP EAX, 0
    JE ShowError              ; Если вернул 0 - ошибка

    ; ---------------------------------------------------------
    ; 4. Ввод и установка СКОРОСТИ (Speed)
    ; ---------------------------------------------------------
    PUSH OFFSET msgSpeed
    CALL PrintStr

    CALL ReadNum        ; Читаем число в EAX
    MOV ValSpeed, EAX   ; Сохраняем

    ; Вызов SystemParametersInfo для Speed
    PUSH SPIF_SENDCHANGE
    PUSH NULL
    PUSH ValSpeed             ; uiParam (наше значение 0-31)
    PUSH SPI_SETKEYBOARDSPEED ; uiAction
    CALL SystemParametersInfo

    CMP EAX, 0
    JE ShowError

    ; 5. Успешное завершение
    PUSH OFFSET msgDone
    CALL PrintStr
    JMP ExitApp

ShowError:
    PUSH OFFSET msgError
    CALL PrintStr

ExitApp:
    PUSH 0
    CALL ExitProcess

; ---------------------------------------------------------
; ПРОЦЕДУРА: PrintStr
; Выводит строку, адрес которой лежит в стеке или передается через переменную
; В данном упрощенном варианте ожидает смещение в стеке перед вызовом
; НО для простоты используем передачу через PUSH + регистры внутри макро/вызова
; Чтобы соответствовать стилю:
; Вход: В стеке адрес строки (push offset String)
; ---------------------------------------------------------
PrintStr PROC
    POP ECX         ; Адрес возврата
    POP ESI         ; Адрес строки
    PUSH ECX        ; Вернули адрес возврата

    ; Подсчет длины строки (ищем 0)
    MOV EDI, ESI
    XOR AL, AL
    MOV ECX, 0FFFFFFFFh
    REPNE SCASB
    NOT ECX
    DEC ECX         ; В ECX длина строки

    ; Вывод 
    PUSH 0              ; Reserved
    PUSH OFFSET BytesWritten
    PUSH ECX            ; Длина
    PUSH ESI            ; Адрес буфера
    PUSH hStdOut        ; Handle
    CALL WriteConsole
    RET
PrintStr ENDP

; ---------------------------------------------------------
; ПРОЦЕДУРА: ReadNum
; Считывает строку и преобразует в число (EAX)
; Упрощенная версия: работает с 1-2 цифрами
; ---------------------------------------------------------
ReadNum PROC
    ; Чтение строки 
    PUSH 0              ; Reserved
    PUSH OFFSET BytesRead
    PUSH 5              ; Максимум символов
    PUSH OFFSET ReadBuf ; Куда читать
    PUSH hStdIn         ; Handle
    CALL ReadConsole

    ; Преобразование ASCII в Число (ATOI)
    XOR EAX, EAX    ; Результат
    XOR ECX, ECX    ; Счетчик
    MOV ESI, OFFSET ReadBuf
    
LoopParse:
    MOV BL, [ESI]
    CMP BL, 0Dh     ; Конец ввода (CR)
    JE EndParse
    CMP BL, 0Ah     ; Line Feed
    JE EndParse
    CMP BL, '0'     ; Проверка на цифры
    JB EndParse
    CMP BL, '9'
    JA EndParse

    SUB BL, '0'     ; '0' -> 0
    IMUL EAX, 10    ; Сдвиг разряда
    MOVZX EBX, BL
    ADD EAX, EBX    ; Добавление цифры
    
    INC ESI
    JMP LoopParse

EndParse:
    RET
ReadNum ENDP

END Start