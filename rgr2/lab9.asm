; nasm -f elf64 lab9_fixed.asm -o lab9.o
; ld lab9.o -o lab9
; Запуск: sudo ./lab9

section .data
    dev_console db "/dev/console", 0
    prompt_delay db "Enter Delay (ms) [250-1000]: ", 0
    prompt_rate  db "Enter Period (ms) [33-500]: ", 0
    msg_open_err db "Error: Cannot open /dev/console. Are you root?", 10, 0
    msg_done     db "Settings applied via /dev/console!", 10, 0
    
    kb_struct:
        dd 0 ; delay
        dd 0 ; period

    buffer db 32 dup(0)

section .text
    global _start

_start:
    ; --- 1. Открываем /dev/console ---
    ; int open(const char *pathname, int flags);
    mov rax, 2          ; sys_open
    mov rdi, dev_console
    mov rsi, 2          ; O_RDWR (чтение и запись)
    mov rdx, 0
    syscall

    cmp rax, 0
    jl open_failed      ; Если RAX < 0, ошибка открытия
    mov r15, rax        ; Сохраняем дескриптор консоли в R15 (надежный регистр)

    ; --- 2. Ввод Delay ---
    mov rsi, prompt_delay
    call print_string
    call read_int
    mov [kb_struct], eax 

    ; --- 3. Ввод Period ---
    mov rsi, prompt_rate
    call print_string
    call read_int
    mov [kb_struct + 4], eax 

    ; --- 4. Вызов ioctl KDKBDREP (0x4B52) ---
    ; ioctl(fd, cmd, arg)
    mov rax, 16         ; sys_ioctl
    mov rdi, r15        ; ИСПОЛЬЗУЕМ ДЕСКРИПТОР /dev/console
    mov rsi, 0x4B52     ; KDKBDREP
    mov rdx, kb_struct
    syscall

    ; --- 5. Закрываем /dev/console ---
    mov rax, 3          ; sys_close
    mov rdi, r15
    syscall

    ; Успех
    mov rsi, msg_done
    call print_string
    jmp exit_ok

open_failed:
    mov rsi, msg_open_err
    call print_string

exit_ok:
    mov rax, 60
    xor rdi, rdi
    syscall

print_string:
    push rax
    push rdi
    push rdx
    push rcx
    mov rdx, 0
.len_loop:
    cmp byte [rsi + rdx], 0
    je .print
    inc rdx
    jmp .len_loop
.print:
    mov rax, 1
    mov rdi, 1
    syscall
    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret

read_int:
    push rdi
    push rsi
    push rdx
    push rcx
    push rbx
    mov rax, 0
    mov rdi, 0      ; Читаем из stdin (клавиатуры пользователя)
    mov rsi, buffer
    mov rdx, 30
    syscall
    xor rax, rax
    xor rcx, rcx
    mov rbx, 10
.next_digit:
    movzx rdx, byte [buffer + rcx]
    cmp rdx, 10
    je .done
    cmp rdx, '0'
    jl .done
    cmp rdx, '9'
    jg .done
    sub rdx, '0'
    imul rax, rbx
    add rax, rdx
    inc rcx
    jmp .next_digit
.done:
    pop rbx
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ret