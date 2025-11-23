; nasm -f elf64 lab8.asm -o lab8.o
; ld lab8.o -o lab8
; Запуск: ./lab8 <source> <target> <overwrite_flag>
; <overwrite_flag>: 0 - ошибка, если файл существует; 1 - перезаписать.

section .data
    err_msg  db "Usage: ./lab8 <src> <dst> <1=overwrite|0=no_overwrite>", 10
    err_len  equ $ - err_msg
    
    fail_msg db "Error: Could not move file (Target exists or other error).", 10
    fail_len equ $ - fail_msg
    
    ok_msg   db "Success: File moved.", 10
    ok_len   equ $ - ok_msg

    ; Константы для renameat2
    AT_FDCWD equ -100        ; Использовать текущую директорию
    RENAME_NOREPLACE equ 1   ; Флаг: Не перезаписывать, если файл есть

section .text
    global _start

_start:
    ; --- 1. Разбор аргументов ---
    ; Стек: [argc], [argv0], [argv1], [argv2], [argv3]
    pop rcx             ; argc
    cmp rcx, 4          ; Нужно 4 аргумента (программа + src + dst + flag)
    jne print_usage

    pop rdi             ; argv[0] - пропускаем
    
    pop rsi             ; argv[1] -> Исходный путь (Source)
    pop rdx             ; argv[2] -> Целевой путь (Target)
    pop rbx             ; argv[3] -> Флаг ("0" или "1")

    ; --- 2. Анализ флага перезаписи ---
    ; RBX сейчас содержит адрес строки с флагом. Читаем первый символ.
    mov al, [rbx]       ; Загружаем символ '0' или '1'
    
    cmp al, '1'         
    je set_overwrite    ; Если '1', то флаги = 0 (стандартное поведение)
    
    ; Если не '1' (значит '0'), устанавливаем RENAME_NOREPLACE
    mov r8, RENAME_NOREPLACE ; Флаг R8 = 1
    jmp do_syscall

set_overwrite:
    xor r8, r8          ; Флаг R8 = 0 (перезаписывать)

do_syscall:
    ; --- 3. Вызов sys_renameat2 (номер 316) ---
    ; Прототип: 
    ; int renameat2(int olddirfd, const char *oldpath, 
    ;               int newdirfd, const char *newpath, unsigned int flags);
    
    ; Аргументы syscall (x64):
    ; RAX = 316
    ; RDI = olddirfd (-100)
    ; RSI = oldpath  (уже лежит в RSI из стека, но мы его перекладывали, проверим)
    ; RDX = newdirfd (-100)
    ; R10 = newpath  (ВНИМАНИЕ: 4-й аргумент в syscall это R10, а не RCX/RDX)
    ; R8  = flags    (уже установлен выше)

    ; RSI = argv[1] (Source)
    ; R10 = argv[2] (Target) - переносим из RDX (где он был после pop)
    
    mov r10, rdx        ; Перемещаем Target в R10 (4-й аргумент)
    
    mov rax, 316        ; sys_renameat2
    mov rdi, AT_FDCWD   ; (-100) Текущая директория для Source
    mov rdx, AT_FDCWD   ; (-100) Текущая директория для Target
                        ; RSI уже указывает на Source
                        ; R8 уже содержит флаги
    syscall

    ; --- 4. Проверка результата ---
    test rax, rax
    js move_failed      ; Ошибка (например, файл существует и флаг=0)

    ; Успех
    mov rax, 1
    mov rdi, 1
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
    mov rdi, 1
    jmp do_exit

print_usage:
    mov rax, 1
    mov rdi, 1
    mov rsi, err_msg
    mov rdx, err_len
    syscall
    mov rdi, 1

exit_app:
    mov rdi, 0

do_exit:
    mov rax, 60
    syscall