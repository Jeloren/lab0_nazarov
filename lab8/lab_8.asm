; lab_8.asm
; Лабораторная работа №8, Вариант 10: Перемещение файла
; ИСПРАВЛЕННЫЙ ПАРСИНГ ДЛЯ АРГУМЕНТОВ В КАВЫЧКАХ

include lab_8.inc

.386
.model FLAT, STDCALL

; Константы для внутреннего использования
TRUE EQU 1
FALSE EQU 0
QUOTE EQU 22H ; ASCII-код для символа '"'
SPACE EQU 20H ; ASCII-код для символа ' '
NULL EQU 0

.DATA
    ; Буферы для хранения аргументов командной строки (максимум 256 символов)
    SourcePath DB 256 DUP (0)
    NewPath    DB 256 DUP (0)
    
.CODE
START:
    
    ; --- 1. Извлечение аргументов командной строки ---
    
    CALL GetCommandLineA        ; EAX = указатель на командную строку
    MOV ESI, EAX                ; ESI - наш текущий указатель
    
    ; ==========================================================
    ; Пропускаем 1-й аргумент (Имя программы)
    ; ==========================================================
    CMP BYTE PTR [ESI], QUOTE
    JNE Skip_Prog_No_Quote
    
    ; Случай: имя программы в кавычках
    INC ESI ; Пропускаем открывающую кавычку
Skip_Prog_Quote_Loop:
    CMP BYTE PTR [ESI], NULL
    JE Skip_Prog_End
    CMP BYTE PTR [ESI], QUOTE
    JE Skip_Prog_Quote_End
    INC ESI
    JMP Skip_Prog_Quote_Loop
Skip_Prog_Quote_End:
    INC ESI ; Пропускаем закрывающую кавычку
    JMP Skip_Spaces_1

Skip_Prog_No_Quote:
    ; Ищем первый пробел или конец строки
Skip_Prog_NoQuote_Loop:
    CMP BYTE PTR [ESI], NULL
    JE Skip_Prog_End
    CMP BYTE PTR [ESI], SPACE
    JE Skip_Prog_NoQuote_End
    INC ESI
    JMP Skip_Prog_NoQuote_Loop
Skip_Prog_NoQuote_End:
    
Skip_Prog_End:
    
Skip_Spaces_1:
    ; Пропускаем пробелы после 1-го аргумента
Skip_Spaces_1_Loop:
    CMP BYTE PTR [ESI], SPACE
    JNE Skip_Spaces_1_End
    INC ESI
    JMP Skip_Spaces_1_Loop
Skip_Spaces_1_End:
    
    ; ==========================================================
    ; Копируем 2-й аргумент (SourcePath)
    ; ==========================================================
    MOV EDI, OFFSET SourcePath
    
    ; Проверяем, начинается ли аргумент с кавычки
    CMP BYTE PTR [ESI], QUOTE
    JNE Copy_Arg_2_No_Quote
    
    ; Случай с кавычками: копируем до закрывающей кавычки
    INC ESI ; Пропускаем открывающую кавычку
Copy_Arg_2_Quote_Loop:
    CMP BYTE PTR [ESI], NULL
    JE End_Copy_2
    CMP BYTE PTR [ESI], QUOTE
    JE Copy_Arg_2_Quote_End
    MOV AL, [ESI]
    MOV [EDI], AL
    INC ESI
    INC EDI
    CMP EDI, OFFSET SourcePath + 255
    JB Copy_Arg_2_Quote_Loop
    JMP End_Copy_2  ; Буфер заполнен
Copy_Arg_2_Quote_End:
    INC ESI ; Пропускаем закрывающую кавычку
    JMP End_Copy_2

Copy_Arg_2_No_Quote:
    ; Случай без кавычек: копируем до пробела или конца строки
Copy_Arg_2_NoQuote_Loop:
    CMP BYTE PTR [ESI], NULL
    JE End_Copy_2
    CMP BYTE PTR [ESI], SPACE
    JE End_Copy_2
    MOV AL, [ESI]
    MOV [EDI], AL
    INC ESI
    INC EDI
    CMP EDI, OFFSET SourcePath + 255
    JB Copy_Arg_2_NoQuote_Loop

End_Copy_2:
    MOV BYTE PTR [EDI], NULL
    
    ; Пропускаем пробелы после 2-го аргумента
Skip_Spaces_2_Loop:
    CMP BYTE PTR [ESI], SPACE
    JNE Skip_Spaces_2_End
    INC ESI
    JMP Skip_Spaces_2_Loop
Skip_Spaces_2_End:
    
    ; ==========================================================
    ; Копируем 3-й аргумент (NewPath)
    ; ==========================================================
    MOV EDI, OFFSET NewPath
    
    ; Проверяем, начинается ли аргумент с кавычки
    CMP BYTE PTR [ESI], QUOTE
    JNE Copy_Arg_3_No_Quote
    
    ; Случай с кавычками: копируем до закрывающей кавычки
    INC ESI ; Пропускаем открывающую кавычку
Copy_Arg_3_Quote_Loop:
    CMP BYTE PTR [ESI], NULL
    JE End_Copy_3
    CMP BYTE PTR [ESI], QUOTE
    JE Copy_Arg_3_Quote_End
    MOV AL, [ESI]
    MOV [EDI], AL
    INC ESI
    INC EDI
    CMP EDI, OFFSET NewPath + 255
    JB Copy_Arg_3_Quote_Loop
    JMP End_Copy_3  ; Буфер заполнен
Copy_Arg_3_Quote_End:
    INC ESI ; Пропускаем закрывающую кавычку
    JMP End_Copy_3

Copy_Arg_3_No_Quote:
    ; Случай без кавычек: копируем до пробела или конца строки
Copy_Arg_3_NoQuote_Loop:
    CMP BYTE PTR [ESI], NULL
    JE End_Copy_3
    CMP BYTE PTR [ESI], SPACE
    JE End_Copy_3
    MOV AL, [ESI]
    MOV [EDI], AL
    INC ESI
    INC EDI
    CMP EDI, OFFSET NewPath + 255
    JB Copy_Arg_3_NoQuote_Loop

End_Copy_3:
    MOV BYTE PTR [EDI], NULL
    
    ; --- 2. Проверка аргументов и Вызов MoveFileA ---
    
    ; Проверка, что 2-й аргумент (SourcePath) не пуст
    CMP BYTE PTR [OFFSET SourcePath], NULL
    JE END_FAIL
    
    ; Проверка, что 3-й аргумент (NewPath) не пуст
    CMP BYTE PTR [OFFSET NewPath], NULL
    JE END_FAIL

    ; BOOL MoveFileA(
    ;   LPCSTR lpExistingFileName, ; SourcePath
    ;   LPCSTR lpNewFileName       ; NewPath
    ; );
    PUSH OFFSET NewPath         ; 2. Новый путь/имя
    PUSH OFFSET SourcePath      ; 1. Исходный путь/имя
    CALL MoveFileA
    
    ; EAX содержит результат: TRUE (не ноль) или FALSE (ноль)
    CMP EAX, FALSE
    JE END_FAIL ; Переход, если MoveFileA вернула FALSE (ошибка)
    
    ; --- Успешное завершение ---
    PUSH 0 ; Код успешного завершения 0
    CALL ExitProcess

END_FAIL:
    ; --- Завершение с ошибкой ---
    ; Можно добавить вызов GetLastError для отладки
    ; CALL GetLastError
    ; Теперь EAX содержит код ошибки Windows
    PUSH 1 ; Код ошибки 1
    CALL ExitProcess
    
END START