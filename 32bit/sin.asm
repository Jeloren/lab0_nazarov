includelib import32.lib

.386
.model flat, stdcall

extern ExitProcess: PROC

.data
    y       dq 1.0       ; Начальное значение x
    eps     dq 1e-4      ; Порог
    z       dq ?         ; Результат
    count   dd ?         ; Счётчик итераций

.code
main:
    FINIT                ; Инициализация FPU
    FLD eps              ; ST(0) = eps
    FLD y                ; ST(0) = y, ST(1) = eps
    mov ecx, 0           ; Инициализация счётчика

loop_start:
    FSIN                 ; ST(0) = sin(ST(0))
    inc ecx              ; Увеличить счётчик
    FLD ST(0)            ; Дублировать ST(0)
    FABS                 ; ST(0) = |ST(0)|
    FCOMP ST(2)          ; Сравнить с eps (ST(2))
    FSTSW AX             ; Сохранить статус FPU
    SAHF                 ; Загрузить флаги
    FSTP ST(0)           ; Очистить лишнее значение (|y|)
    JAE loop_start       ; Если |y| >= eps, повторить

    FSTP z               ; Сохранить результат (sin^{(n)}(x))
    mov [count], ecx     ; Сохранить число итераций

    call ExitProcess, 0
END main