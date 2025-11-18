; lab_8_simple.asm
; Упрощенная версия для отладки

include lab_8.inc

.386
.model FLAT, STDCALL

.DATA
    SourcePath DB "test.txt", 0
    NewPath    DB "moved_file.txt", 0
    
.CODE
START:
    ; Простой тест с фиксированными путями
    PUSH OFFSET NewPath
    PUSH OFFSET SourcePath
    CALL MoveFileA
    
    CMP EAX, 0
    JE END_FAIL
    
    ; Успех
    PUSH 0
    CALL ExitProcess

END_FAIL:
    ; Ошибка
    PUSH 1
    CALL ExitProcess
    
END START