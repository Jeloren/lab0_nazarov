include lab_8.inc

.386
.model FLAT, STDCALL

; Константы
TRUE  EQU 1
FALSE EQU 0
QUOTE EQU 22H ; "
SPACE EQU 20H ; Пробел
TAB   EQU 09H ; Табуляция
NULL  EQU 0
MOVEFILE_REPLACE_EXISTING EQU 1
STD_OUTPUT_HANDLE EQU -11  ; Дескриптор вывода консоли

.DATA
    SourcePath DB 260 DUP (0)
    NewPath    DB 260 DUP (0)
    FlagBuf    DB 10  DUP (0)
    
    ; --- Переменные для консоли ---
    hStdOut      DD ?              ; Хранитель дескриптора консоли
    BytesWritten DD ?              ; Сюда WriteConsole запишет сколько байт вывела
    
    ; --- Сообщения ---
    MsgSuccess   DB "OK: File moved successfully.", 0Dh, 0Ah, 0
    MsgSrcError  DB "FAIL: Source file not found.", 0Dh, 0Ah, 0
    MsgExistErr  DB "FAIL: Target file exists (use flag 1 to overwrite).", 0Dh, 0Ah, 0
    MsgPathErr   DB "FAIL: Invalid paths or access denied.", 0Dh, 0Ah, 0
    MsgUnknown   DB "FAIL: Unknown system error.", 0Dh, 0Ah, 0
    
.CODE
START:
    ; --- 0. Инициализация консоли ---
    PUSH STD_OUTPUT_HANDLE
    CALL GetStdHandle
    MOV hStdOut, EAX        ; Сохраняем дескриптор, чтобы использовать при выводе

    ; --- 1. Получение командной строки ---
    CALL GetCommandLineA
    MOV ESI, EAX
    
    ; =============================================================
    ; ПАРСИНГ АРГУМЕНТОВ
    ; =============================================================
    CALL Skip_Whitespace
    CMP BYTE PTR [ESI], QUOTE
    JNE Skip_Prog_NoQuote
    INC ESI 
Skip_Prog_Quote_Loop:
    MOV AL, [ESI]
    CMP AL, NULL
    JE  Parse_Args_Done
    CMP AL, QUOTE
    JE  Skip_Prog_Quote_End
    INC ESI
    JMP Skip_Prog_Quote_Loop
Skip_Prog_Quote_End:
    INC ESI
    JMP Parse_Arg_1
Skip_Prog_NoQuote:
    MOV AL, [ESI]
    CMP AL, NULL
    JE  Parse_Args_Done
    CMP AL, SPACE
    JE  Parse_Arg_1
    CMP AL, TAB
    JE  Parse_Arg_1
    INC ESI
    JMP Skip_Prog_NoQuote

Parse_Arg_1:
    CALL Skip_Whitespace
    CMP BYTE PTR [ESI], NULL
    JE Parse_Args_Done
    MOV EDI, OFFSET SourcePath
    CALL Parse_Token

Parse_Arg_2:
    CALL Skip_Whitespace
    CMP BYTE PTR [ESI], NULL
    JE Parse_Args_Done
    MOV EDI, OFFSET NewPath
    CALL Parse_Token

Parse_Arg_3:
    CALL Skip_Whitespace
    CMP BYTE PTR [ESI], NULL
    JE Parse_Args_Done
    MOV EDI, OFFSET FlagBuf
    CALL Parse_Token

Parse_Args_Done:

    ; --- 2. ПРОВЕРКА ПУТЕЙ ---
    CMP BYTE PTR [SourcePath], 0
    JE Handle_Path_Error
    CMP BYTE PTR [NewPath], 0
    JE Handle_Path_Error

    ; --- 3. ЛОГИКА ФЛАГА ---
    MOV EDX, 0
    MOV AL, [FlagBuf]
    CMP AL, '1'
    JNE Do_Move
    MOV EDX, MOVEFILE_REPLACE_EXISTING

Do_Move:
    PUSH EDX
    PUSH OFFSET NewPath
    PUSH OFFSET SourcePath
    CALL MoveFileExA
    
    CMP EAX, 0
    JE Handle_Move_Error    ; Если 0 - ошибка, идем разбираться какая
    
    ; --- УСПЕХ ---
    MOV EAX, OFFSET MsgSuccess
    CALL PrintStr
    
    PUSH 0
    CALL ExitProcess

; =============================================================
; ОБРАБОТКА ОШИБОК
; =============================================================

Handle_Path_Error:
    MOV EAX, OFFSET MsgPathErr
    CALL PrintStr
    PUSH 1
    CALL ExitProcess

Handle_Move_Error:
    CALL GetLastError   ; Код ошибки в EAX
    
    ; Проверка: Файл не найден (Код 2)
    CMP EAX, 2
    JE Err_Source_Missing
    
    ; Проверка: Путь не найден (Код 3)
    CMP EAX, 3
    JE Err_Source_Missing

    ; Проверка: Файл существует (Код 183 = 0B7h)
    CMP EAX, 0B7h 
    JE Err_Target_Exists
    
    ; Проверка: Отказано в доступе (Код 5)
    CMP EAX, 5
    JE Err_Path_Access

    ; Иначе неизвестная ошибка
    MOV EAX, OFFSET MsgUnknown
    CALL PrintStr
    JMP Final_Err_Exit

Err_Source_Missing:
    MOV EAX, OFFSET MsgSrcError
    CALL PrintStr
    JMP Final_Err_Exit

Err_Target_Exists:
    MOV EAX, OFFSET MsgExistErr
    CALL PrintStr
    JMP Final_Err_Exit

Err_Path_Access:
    MOV EAX, OFFSET MsgPathErr
    CALL PrintStr
    JMP Final_Err_Exit

Final_Err_Exit:
    PUSH 1
    CALL ExitProcess


; =============================================================
; ПРОЦЕДУРЫ ПОМОЩНИКИ
; =============================================================

; --- Процедура вывода строки на экран ---
; Вход: EAX - адрес строки
PrintStr PROC
    PUSH EDI
    PUSH ESI
    PUSH ECX
    
    MOV ESI, EAX    ; Сохраняем адрес строки
    
    ; Подсчет длины строки
    MOV EDI, EAX
    xor AL, AL
    MOV ECX, -1
    REPNE SCASB     ; Ищем 0
    NOT ECX
    DEC ECX         ; В ECX теперь длина строки
    
    ; Вывод: WriteConsoleA(hStdOut, Addr, Len, AddrWritten, 0)
    PUSH 0
    PUSH OFFSET BytesWritten
    PUSH ECX        ; Длина
    PUSH ESI        ; Адрес текста
    PUSH hStdOut    ; Хендл консоли
    CALL WriteConsoleA
    
    POP ECX
    POP ESI
    POP EDI
    RET
PrintStr ENDP

Skip_Whitespace PROC
Skip_WS_Loop:
    MOV AL, [ESI]
    CMP AL, SPACE
    JE  Skip_WS_Next
    CMP AL, TAB
    JE  Skip_WS_Next
    RET
Skip_WS_Next:
    INC ESI
    JMP Skip_WS_Loop
Skip_Whitespace ENDP

Parse_Token PROC
    CMP BYTE PTR [ESI], QUOTE
    JNE Parse_Token_Simple
    INC ESI 
Parse_Token_Quote_Loop:
    MOV AL, [ESI]
    CMP AL, NULL
    JE  Parse_Token_End
    CMP AL, QUOTE
    JE  Parse_Token_Quote_Done
    MOV [EDI], AL
    INC ESI
    INC EDI
    JMP Parse_Token_Quote_Loop
Parse_Token_Quote_Done:
    INC ESI
    JMP Parse_Token_End
Parse_Token_Simple:
    MOV AL, [ESI]
    CMP AL, NULL
    JE  Parse_Token_End
    CMP AL, SPACE
    JE  Parse_Token_End
    CMP AL, TAB
    JE  Parse_Token_End
    MOV [EDI], AL
    INC ESI
    INC EDI
    JMP Parse_Token_Simple
Parse_Token_End:
    MOV BYTE PTR [EDI], 0
    RET
Parse_Token ENDP

END START