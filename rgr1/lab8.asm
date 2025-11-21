; nasm -f elf64 lab8.asm -o lab8.o
; ld lab8.o -o lab8

section .data
    err_msg db "Usage: ./lab8 <source> <target>", 10
    err_len equ $ - err_msg
    fail_msg db "Error: Could not move file.", 10
    fail_len equ $ - fail_msg
    ok_msg   db "Success: File moved.", 10
    ok_len   equ $ - ok_msg

section .text
    global _start

_start:
    ; --- 1. Получение аргументов из стека ---
    ; При старте стек выглядит так:
    ; [rsp]      = argc (количество аргументов)
    ; [rsp + 8]  = argv[0] (имя программы)
    ; [rsp + 16] = argv[1] (исходный файл)
    ; [rsp + 24] = argv[2] (новый путь)

    pop rcx         ; Достаем argc в RCX
    cmp rcx, 3      ; Должно быть 3 аргумента (программа + источник + цель)
    jne print_usage ; Если не 3, выводим инструкцию

    pop rdi         ; Пропускаем argv[0] (имя программы)
    
    pop rdi         ; argv[1] -> RDI (1-й аргумент sys_rename: oldname)
    pop rsi         ; argv[2] -> RSI (2-й аргумент sys_rename: newname)

    ; --- 2. Вызов sys_rename (номер 82) ---
    ; int rename(const char *oldname, const char *newname);
    mov rax, 82     ; Номер системного вызова sys_rename
    syscall         ; Вызов ядра

    ; --- 3. Проверка результата ---
    test rax, rax   ; Если RAX < 0, значит ошибка
    js move_failed

    ; Успех
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, ok_msg
    mov rdx, ok_len
    syscall
    jmp exit_app

move_failed:
    mov rax, 1
    mov rdi, 1
    mov rsi, fail_msg
    mov rdx, fail_len
    syscall
    mov rdi, 1      ; Код выхода 1 (ошибка)
    jmp do_exit

print_usage:
    mov rax, 1
    mov rdi, 1
    mov rsi, err_msg
    mov rdx, err_len
    syscall
    mov rdi, 1

exit_app:
    mov rdi, 0      ; Код выхода 0 (ок)

do_exit:
    mov rax, 60     ; sys_exit
    syscall