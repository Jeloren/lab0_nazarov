.386
.model flat, stdcall
option casemap :none

includelib kernel32.lib
includelib msvcrt.lib

extern ExitProcess@4: PROC
extern printf: PROC
extern _getch: PROC

; Макрос для вывода комплексного числа
print_complex MACRO real_part, imag_part
    pushad
    fld real_part
    fstp qword ptr [esp-8]
    fld imag_part
    fstp qword ptr [esp-16]
    sub esp, 16
    push offset fmt_complex
    call printf
    add esp, 20
    popad
ENDM

.data
    ; Форматы вывода
    fmt_complex  db "%.4f %+.4fi", 0Ah, 0
    fmt_root1    db "Root 1: ", 0
    fmt_root2    db "Root 2: ", 0
    fmt_pause    db "Press any key to exit...", 0

    ; Комплексные коэффициенты квадратного уравнения
    ; Пример: (1+0i)x² + (0+0i)x + (-1+0i) = 0 -> Корни: 1, -1
    A_real dq  1.0   ; Действительная часть A
    A_imag dq  0.0   ; Мнимая часть A
    B_real dq  0.0   ; Действительная часть B
    B_imag dq  0.0   ; Мнимая часть B
    C_real dq -1.0   ; Действительная часть C
    C_imag dq  0.0   ; Мнимая часть C

    ; Промежуточные переменные
    four      dq 4.0
    two       dq 2.0
    neg_one   dq -1.0

    ; Результаты вычислений
    D_real    dq ?   ; Действительная часть дискриминанта
    D_imag    dq ?   ; Мнимая часть дискриминанта
    sqrtD_real dq ?  ; Действительная часть sqrt(D)
    sqrtD_imag dq ?  ; Мнимая часть sqrt(D)
    root1_real dq ?  ; Действительная часть корня 1
    root1_imag dq ?  ; Мнимая часть корня 1
    root2_real dq ?  ; Действительная часть корня 2
    root2_imag dq ?  ; Мнимая часть корня 2

.code
main PROC
    ; Инициализация FPU
    finit

    ; Вычисление дискриминанта D = B² - 4AC
    ; Шаг 1: Вычисление B²
    call calc_B_square   ; Результат: D_real, D_imag (пока содержит B²)

    ; Шаг 2: Вычисление 4AC
    call calc_4AC        ; Результат: root1_real, root1_imag (временное хранение)

    ; Шаг 3: D = B² - 4AC
    fld D_real
    fsub root1_real
    fstp D_real          ; D_real = B²_real - 4AC_real

    fld D_imag
    fsub root1_imag
    fstp D_imag          ; D_imag = B²_imag - 4AC_imag

    ; Вычисление квадратного корня из дискриминанта
    movsd xmm0, D_real
    movsd xmm1, D_imag
    call complex_sqrt    ; Результат: xmm0 = sqrtD_real, xmm1 = sqrtD_imag
    movsd sqrtD_real, xmm0
    movsd sqrtD_imag, xmm1

    ; Вычисление корней уравнения:
    ; root1 = (-B + sqrt(D)) / (2A)
    ; root2 = (-B - sqrt(D)) / (2A)

    ; Вычисление -B
    fld B_real
    fchs
    fstp root1_real      ; -B_real
    fld B_imag
    fchs
    fstp root1_imag      ; -B_imag

    ; Вычисление (-B + sqrt(D))
    fld root1_real
    fadd sqrtD_real
    fstp root1_real      ; numerator1_real = -B_real + sqrtD_real
    fld root1_imag
    fadd sqrtD_imag
    fstp root1_imag      ; numerator1_imag = -B_imag + sqrtD_imag

    ; Делим на 2A
    movsd xmm0, root1_real
    movsd xmm1, root1_imag
    movsd xmm2, A_real
    movsd xmm3, A_imag
    movsd xmm4, two
    call complex_div      ; Результат: xmm0 = root1_real, xmm1 = root1_imag
    movsd root1_real, xmm0
    movsd root1_imag, xmm1

    ; Вычисление (-B - sqrt(D))
    fld root1_real       ; Временно сохраняем -B_real
    fsub sqrtD_real
    fstp root2_real      ; numerator2_real = -B_real - sqrtD_real
    fld root1_imag       ; Временно сохраняем -B_imag
    fsub sqrtD_imag
    fstp root2_imag      ; numerator2_imag = -B_imag - sqrtD_imag

    ; Делим на 2A
    movsd xmm0, root2_real
    movsd xmm1, root2_imag
    movsd xmm2, A_real
    movsd xmm3, A_imag
    movsd xmm4, two
    call complex_div      ; Результат: xmm0 = root2_real, xmm1 = root2_imag
    movsd root2_real, xmm0
    movsd root2_imag, xmm1

    ; Вывод результатов
    push offset fmt_root1
    call printf
    add esp, 4
    print_complex root1_real, root1_imag

    push offset fmt_root2
    call printf
    add esp, 4
    print_complex root2_real, root2_imag

    ; Ожидание нажатия клавиши
    push offset fmt_pause
    call printf
    add esp, 4
    call _getch

    ; Завершение программы
    push 0
    call ExitProcess@4

main ENDP

; Вычисление B²
calc_B_square PROC
    ; Действительная часть: B_real² - B_imag²
    fld B_real
    fmul B_real
    fld B_imag
    fmul B_imag
    fsub
    fstp D_real

    ; Мнимая часть: 2 * B_real * B_imag
    fld B_real
    fmul B_imag
    fadd st, st
    fstp D_imag
    ret
calc_B_square ENDP

; Вычисление 4AC
calc_4AC PROC
    ; Умножение A на C
    ; Действительная часть: A_real*C_real - A_imag*C_imag
    fld A_real
    fmul C_real
    fld A_imag
    fmul C_imag
    fsub
    fstp root1_real   ; временное хранение (A*C)_real

    ; Мнимая часть: A_real*C_imag + A_imag*C_real
    fld A_real
    fmul C_imag
    fld A_imag
    fmul C_real
    fadd
    fstp root1_imag   ; (A*C)_imag

    ; Умножение на 4
    fld four
    fmul root1_real
    fstp root1_real   ; 4*(A*C)_real

    fld four
    fmul root1_imag
    fstp root1_imag   ; 4*(A*C)_imag
    ret
calc_4AC ENDP

; Вычисление квадратного корня комплексного числа
; Вход: xmm0 = real, xmm1 = imag
; Выход: xmm0 = sqrt_real, xmm1 = sqrt_imag
complex_sqrt PROC
    ; Сохранение в стеке
    sub esp, 16
    movsd [esp], xmm0
    movsd [esp+8], xmm1

    ; Вычисление модуля r = sqrt(real² + imag²)
    fld qword ptr [esp]      ; real
    fmul st, st
    fld qword ptr [esp+8]    ; imag
    fmul st, st
    fadd                     ; real² + imag²
    fsqrt                    ; r = sqrt(real² + imag²)
    fst qword ptr [esp]      ; сохраняем r (временно)

    ; Вычисление действительной части корня
    ; x = sqrt((r + real) / 2)
    fld qword ptr [esp]      ; r
    fadd qword ptr [esp]     ; r + real (оригинальный real сохранен в [esp+0]?)
    fdiv two
    fsqrt
    fstp qword ptr [esp+8]   ; сохраняем x (временное хранение)

    ; Вычисление мнимой части корня
    ; y = sqrt((r - real) / 2) * sign(imag)
    fld qword ptr [esp]      ; r
    fsub qword ptr [esp]     ; r - real (оригинальный real)
    fdiv two
    fsqrt                    ; y_temp
    ; Учет знака мнимой части
    fld qword ptr [esp+8]    ; оригинальный imag
    ftst
    fstsw ax
    sahf
    jae positive
    fchs                     ; если imag < 0, меняем знак y
positive:
    fstp qword ptr [esp]     ; сохраняем y

    ; Загрузка результатов
    movsd xmm0, [esp+8]      ; x (действительная часть)
    movsd xmm1, [esp]        ; y (мнимая часть)

    add esp, 16
    ret
complex_sqrt ENDP

; Деление комплексного числа на комплексное
; Вход: 
;   xmm0, xmm1 = num_real, num_imag
;   xmm2, xmm3 = den_real, den_imag
;   xmm4 = scalar (скаляр для деления)
; Выход: xmm0, xmm1 = res_real, res_imag
complex_div PROC
    ; Вычисление знаменателя: den_real² + den_imag²
    movsd xmm5, xmm2
    mulsd xmm5, xmm5
    movsd xmm6, xmm3
    mulsd xmm6, xmm6
    addsd xmm5, xmm6   ; denom = den_real² + den_imag²

    ; Умножаем знаменатель на скаляр
    mulsd xmm5, xmm4   ; denom_scaled = denom * scalar

    ; Вычисление действительной части результата:
    ; (num_real*den_real + num_imag*den_imag) / denom_scaled
    movsd xmm6, xmm0   ; num_real
    mulsd xmm6, xmm2   ; num_real * den_real
    movsd xmm7, xmm1   ; num_imag
    mulsd xmm7, xmm3   ; num_imag * den_imag
    addsd xmm6, xmm7   ; real_numerator
    divsd xmm6, xmm5   ; res_real = real_numerator / denom_scaled

    ; Вычисление мнимой части результата:
    ; (num_imag*den_real - num_real*den_imag) / denom_scaled
    movsd xmm7, xmm1   ; num_imag
    mulsd xmm7, xmm2   ; num_imag * den_real
    mulsd xmm0, xmm3   ; num_real * den_imag
    subsd xmm7, xmm0   ; imag_numerator
    divsd xmm7, xmm5   ; res_imag = imag_numerator / denom_scaled

    ; Возврат результатов
    movsd xmm0, xmm6   ; res_real
    movsd xmm1, xmm7   ; res_imag
    ret
complex_div ENDP

END main