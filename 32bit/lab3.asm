includelib import32.lib
.386
.model flat, stdcall

; Подключение внешней функции завершения процесса
extern ExitProcess: PROC

.data
    ; Коэффициенты уравнения a*z² + b*z + c = 0 (комплексные числа)
    a_re dq 1.0      ; Действительная часть a
    a_im dq 2.0      ; Мнимая часть a
    b_re dq 3.0      ; Действительная часть b
    b_im dq -4.0     ; Мнимая часть b
    c_re dq 2.0      ; Действительная часть c
    c_im dq 1.0      ; Мнимая часть c

    ; Временные переменные для вычислений
    b_sq_re dq ?     ; Вещественная часть b²
    b_sq_im dq ?     ; Мнимая часть b²
    ac_re   dq ?     ; Вещественная часть a*c
    ac_im   dq ?     ; Мнимая часть a*c
    four_ac_re dq ?  ; Вещественная часть 4ac
    four_ac_im dq ?  ; Мнимая часть 4ac
    D_re    dq ?     ; Вещественная часть дискриминанта
    D_im    dq ?     ; Мнимая часть дискриминанта
    sqrt_mod dq ?    ; Модуль корня из D
    theta    dq ?    ; Угол θ для полярной формы D
    theta_half dq ?  ; θ/2
    cos_half dq ?    ; cos(θ/2)
    sin_half dq ?    ; sin(θ/2)
    sqrt_re dq ?     ; Вещественная часть sqrt(D)
    sqrt_im dq ?     ; Мнимая часть sqrt(D)
    root1_num_re dq ? ; Числитель 1-го корня (вещественная)
    root1_num_im dq ? ; Числитель 1-го корня (мнимая)
    root2_num_re dq ? ; Числитель 2-го корня (вещественная)
    root2_num_im dq ? ; Числитель 2-го корня (мнимая)
    denom_re dq ?    ; Знаменатель (вещественная часть 2a)
    denom_im dq ?    ; Знаменатель (мнимая часть 2a)
    denom_mod_sq dq ? ; Квадрат модуля знаменателя
    root1_re dq ?    ; Итоговый корень 1 (вещественная)
    root1_im dq ?    ; Итоговый корень 1 (мнимая)
    root2_re dq ?    ; Итоговый корень 2 (вещественная)
    root2_im dq ?    ; Итоговый корень 2 (мнимая)

.code
main:
    FINIT                ; Инициализация FPU

    ; === Вычисление дискриминанта D = b² - 4ac ===
    
    ; --- Вычисление b² = (b_re + i*b_im)² ---
    FLD b_re             ; ST(0) = b_re
    FMUL ST(0), ST(0)    ; ST(0) = b_re²
    FLD b_im             ; ST(0) = b_im, ST(1) = b_re²
    FMUL ST(0), ST(0)    ; ST(0) = b_im²
    FSUB                 ; ST(0) = b_re² - b_im² (вещественная часть b²)
    FSTP b_sq_re         ; Сохранить в b_sq_re

    FLD b_re             ; ST(0) = b_re
    FLD b_im             ; ST(0) = b_im, ST(1) = b_re
    FMUL                 ; ST(0) = b_re * b_im
    FADD ST(0), ST(0)    ; ST(0) = 2*b_re*b_im (мнимая часть b²)
    FSTP b_sq_im         ; Сохранить в b_sq_im

    ; --- Вычисление 4ac = 4*(a*c) ---
    ; Произведение a*c = (a_re + i*a_im)*(c_re + i*c_im)
    FLD a_re             ; ST(0) = a_re
    FMUL c_re            ; ST(0) = a_re*c_re
    FLD a_im             ; ST(0) = a_im, ST(1) = a_re*c_re
    FMUL c_im            ; ST(0) = a_im*c_im
    FSUB                 ; ST(0) = a_re*c_re - a_im*c_im (вещественная часть a*c)
    FSTP ac_re           ; Сохранить в ac_re

    FLD a_re             ; ST(0) = a_re
    FMUL c_im            ; ST(0) = a_re*c_im
    FLD a_im             ; ST(0) = a_im, ST(1) = a_re*c_im
    FMUL c_re            ; ST(0) = a_im*c_re
    FADD                 ; ST(0) = a_re*c_im + a_im*c_re (мнимая часть a*c)
    FSTP ac_im           ; Сохранить в ac_im

    ; Умножение на 4
    FLD ac_re            ; ST(0) = ac_re
    FADD ST(0), ST(0)    ; ST(0) *= 2
    FADD ST(0), ST(0)    ; ST(0) *= 2 (итого *4)
    FSTP four_ac_re      ; Сохранить в four_ac_re

    FLD ac_im            ; ST(0) = ac_im
    FADD ST(0), ST(0)    ; ST(0) *= 2
    FADD ST(0), ST(0)    ; ST(0) *= 2 (итого *4)
    FSTP four_ac_im      ; Сохранить в four_ac_im

    ; --- D = b² - 4ac ---
    FLD b_sq_re          ; ST(0) = b_sq_re
    FLD four_ac_re       ; ST(0) = four_ac_re, ST(1) = b_sq_re
    FSUB                 ; ST(0) = b_sq_re - four_ac_re
    FSTP D_re            ; Сохранить вещественную часть D

    FLD b_sq_im          ; ST(0) = b_sq_im
    FLD four_ac_im       ; ST(0) = four_ac_im, ST(1) = b_sq_im
    FSUB                 ; ST(0) = b_sq_im - four_ac_im
    FSTP D_im            ; Сохранить мнимую часть D

    ; === Вычисление sqrt(D) через полярные координаты ===
    ; --- Модуль D ---
    FLD D_re             ; ST(0) = D_re
    FMUL ST(0), ST(0)    ; ST(0) = D_re²
    FLD D_im             ; ST(0) = D_im, ST(1) = D_re²
    FMUL ST(0), ST(0)    ; ST(0) = D_im²
    FADD                 ; ST(0) = D_re² + D_im²
    FSQRT                ; ST(0) = sqrt(D_re² + D_im²) (модуль D)
    FSQRT                ; ST(0) = sqrt(модуля) (т.к. sqrt(D) = sqrt(|D|))
    FSTP sqrt_mod        ; Сохранить модуль корня

    ; --- Угол θ = arctan2(D_im, D_re) ---
    FLD D_re             ; ST(0) = D_re
    FLD D_im             ; ST(0) = D_im, ST(1) = D_re
    FPATAN               ; ST(0) = arctan(D_im/D_re) (угол θ)
    FSTP theta           ; Сохранить θ

    ; --- θ/2 ---
    FLD theta            ; ST(0) = θ
    FLD1                 ; ST(0) = 1.0, ST(1) = θ
    FADD ST(0), ST(0)    ; ST(0) = 2.0
    FDIV                 ; ST(0) = θ / 2
    FSTP theta_half      ; Сохранить θ/2

    ; --- cos(θ/2) и sin(θ/2) ---
    FLD theta_half       ; ST(0) = θ/2
    FCOS                 ; ST(0) = cos(θ/2)
    FSTP cos_half        ; Сохранить cos(θ/2)

    FLD theta_half       ; ST(0) = θ/2
    FSIN                 ; ST(0) = sin(θ/2)
    FSTP sin_half        ; Сохранить sin(θ/2)

    ; --- sqrt(D) = sqrt_mod*(cos(θ/2) + i*sin(θ/2)) ---
    FLD sqrt_mod         ; ST(0) = sqrt_mod
    FMUL cos_half        ; ST(0) = sqrt_mod * cos(θ/2)
    FSTP sqrt_re         ; Сохранить вещественную часть sqrt(D)

    FLD sqrt_mod         ; ST(0) = sqrt_mod
    FMUL sin_half        ; ST(0) = sqrt_mod * sin(θ/2)
    FSTP sqrt_im         ; Сохранить мнимую часть sqrt(D)

    ; === Вычисление корней: (-b ± sqrt(D)) / (2a) ===
    ; --- Числитель для первого корня: (-b + sqrt(D)) ---
    FLD sqrt_re          ; ST(0) = sqrt_re
    FLD b_re             ; ST(0) = b_re, ST(1) = sqrt_re
    FCHS                 ; ST(0) = -b_re
    FADD                 ; ST(0) = -b_re + sqrt_re
    FSTP root1_num_re    ; Сохранить вещественную часть числителя 1

    FLD sqrt_im          ; ST(0) = sqrt_im
    FLD b_im             ; ST(0) = b_im, ST(1) = sqrt_im
    FCHS                 ; ST(0) = -b_im
    FADD                 ; ST(0) = -b_im + sqrt_im
    FSTP root1_num_im    ; Сохранить мнимую часть числителя 1

    ; --- Числитель для второго корня: (-b - sqrt(D)) ---
    FLD sqrt_re          ; ST(0) = sqrt_re
    FLD b_re             ; ST(0) = b_re, ST(1) = sqrt_re
    FCHS                 ; ST(0) = -b_re
    FSUB                 ; ST(0) = -b_re - sqrt_re
    FSTP root2_num_re    ; Сохранить вещественную часть числителя 2

    FLD sqrt_im          ; ST(0) = sqrt_im
    FLD b_im             ; ST(0) = b_im, ST(1) = sqrt_im
    FCHS                 ; ST(0) = -b_im
    FSUB                 ; ST(0) = -b_im - sqrt_im
    FSTP root2_num_im    ; Сохранить мнимую часть числителя 2

    ; --- Знаменатель: 2a ---
    FLD a_re             ; ST(0) = a_re
    FADD ST(0), ST(0)    ; ST(0) = 2*a_re
    FSTP denom_re        ; Сохранить вещественную часть знаменателя

    FLD a_im             ; ST(0) = a_im
    FADD ST(0), ST(0)    ; ST(0) = 2*a_im
    FSTP denom_im        ; Сохранить мнимую часть знаменателя

    ; --- Квадрат модуля знаменателя для деления ---
    FLD denom_re         ; ST(0) = denom_re
    FMUL ST(0), ST(0)    ; ST(0) = denom_re²
    FLD denom_im         ; ST(0) = denom_im, ST(1) = denom_re²
    FMUL ST(0), ST(0)    ; ST(0) = denom_im²
    FADD                 ; ST(0) = denom_re² + denom_im²
    FSTP denom_mod_sq    ; Сохранить квадрат модуля знаменателя

    ; --- Корень 1: (root1_num_re + i*root1_num_im) / (denom_re + i*denom_im) ---
    ; Вещественная часть:
    FLD root1_num_re     ; ST(0) = root1_num_re
    FMUL denom_re        ; ST(0) = root1_num_re * denom_re
    FLD root1_num_im     ; ST(0) = root1_num_im, ST(1) = (root1_num_re * denom_re)
    FMUL denom_im        ; ST(0) = root1_num_im * denom_im
    FADD                 ; ST(0) = root1_num_re*denom_re + root1_num_im*denom_im
    FDIV denom_mod_sq    ; ST(0) = (root1_num_re*denom_re + root1_num_im*denom_im) / denom_mod_sq
    FSTP root1_re        ; Сохранить вещественную часть корня 1

    ; Мнимая часть:
    FLD root1_num_im     ; ST(0) = root1_num_im
    FMUL denom_re        ; ST(0) = root1_num_im * denom_re
    FLD root1_num_re     ; ST(0) = root1_num_re, ST(1) = (root1_num_im * denom_re)
    FMUL denom_im        ; ST(0) = root1_num_re * denom_im
    FSUB                 ; ST(0) = root1_num_im*denom_re - root1_num_re*denom_im
    FDIV denom_mod_sq    ; ST(0) = (root1_num_im*denom_re - root1_num_re*denom_im) / denom_mod_sq
    FSTP root1_im        ; Сохранить мнимую часть корня 1

    ; --- Корень 2: аналогично корню 1 ---
    ; Вещественная часть:
    FLD root2_num_re     ; ST(0) = root2_num_re
    FMUL denom_re        ; ST(0) = root2_num_re * denom_re
    FLD root2_num_im     ; ST(0) = root2_num_im, ST(1) = (root2_num_re * denom_re)
    FMUL denom_im        ; ST(0) = root2_num_im * denom_im
    FADD                 ; ST(0) = root2_num_re*denom_re + root2_num_im*denom_im
    FDIV denom_mod_sq    ; ST(0) = (root2_num_re*denom_re + root2_num_im*denom_im) / denom_mod_sq
    FSTP root2_re        ; Сохранить вещественную часть корня 2

    ; Мнимая часть:
    FLD root2_num_im     ; ST(0) = root2_num_im
    FMUL denom_re        ; ST(0) = root2_num_im * denom_re
    FLD root2_num_re     ; ST(0) = root2_num_re, ST(1) = (root2_num_im * denom_re)
    FMUL denom_im        ; ST(0) = root2_num_re * denom_im
    FSUB                 ; ST(0) = root2_num_im*denom_re - root2_num_re*denom_im
    FDIV denom_mod_sq    ; ST(0) = (root2_num_im*denom_re - root2_num_re*denom_im) / denom_mod_sq
    FSTP root2_im        ; Сохранить мнимую часть корня 2

    ; Завершение программы
    call ExitProcess, 0  ; Выход из программы
END main