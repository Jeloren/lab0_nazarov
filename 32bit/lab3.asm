includelib import32.lib

.386
.model flat, stdcall

extern ExitProcess: PROC

.data
    ; Коэффициенты (a, b, c) как комплексные числа
    a_re dq 1.0
    a_im dq 2.0
    b_re dq 3.0
    b_im dq -4.0
    c_re dq 2.0
    c_im dq 1.0

    ; Переменные для промежуточных вычислений
    b_sq_re dq ?
    b_sq_im dq ?
    ac_re   dq ?
    ac_im   dq ?
    four_ac_re dq ?
    four_ac_im dq ?
    D_re    dq ?
    D_im    dq ?
    sqrt_mod dq ?
    theta    dq ?
    theta_half dq ?
    cos_half dq ?
    sin_half dq ?
    sqrt_re dq ?
    sqrt_im dq ?
    root1_num_re dq ?
    root1_num_im dq ?
    root2_num_re dq ?
    root2_num_im dq ?
    denom_re dq ?
    denom_im dq ?
    denom_mod_sq dq ?
    root1_re dq ?
    root1_im dq ?
    root2_re dq ?
    root2_im dq ?

.code
main:
    FINIT

    ; Вычисление дискриминанта D = b² - 4ac

    ; b² = (b_re^2 - b_im^2) + 2*b_re*b_im*i
    FLD b_re
    FMUL ST(0), ST(0)
    FLD b_im
    FMUL ST(0), ST(0)
    FSUB
    FSTP b_sq_re

    FLD b_re
    FLD b_im
    FMUL
    FADD ST(0), ST(0)
    FSTP b_sq_im

    ; a*c = (a_re*c_re - a_im*c_im) + (a_re*c_im + a_im*c_re)*i
    FLD a_re
    FMUL c_re
    FLD a_im
    FMUL c_im
    FSUB
    FSTP ac_re

    FLD a_re
    FMUL c_im
    FLD a_im
    FMUL c_re
    FADD
    FSTP ac_im

    ; 4ac
    FLD ac_re
    FADD ST(0), ST(0)
    FADD ST(0), ST(0)
    FSTP four_ac_re

    FLD ac_im
    FADD ST(0), ST(0)
    FADD ST(0), ST(0)
    FSTP four_ac_im

    ; D = b² - 4ac
    FLD b_sq_re
    FLD four_ac_re
    FSUB
    FSTP D_re

    FLD b_sq_im
    FLD four_ac_im
    FSUB
    FSTP D_im

    ; Вычисление sqrt(D) через полярные координаты
    ; Модуль D
    FLD D_re
    FMUL ST(0), ST(0)
    FLD D_im
    FMUL ST(0), ST(0)
    FADD
    FSQRT
    FSQRT
    FSTP sqrt_mod

    ; Угол θ = arctan2(D_im, D_re)
    FLD D_re
    FLD D_im
    FPATAN
    FSTP theta

    ; θ/2
    FLD theta
    FLD1
    FADD ST(0), ST(0)
    FDIV
    FSTP theta_half

    ; cos(theta/2) и sin(theta/2)
    FLD theta_half
    FCOS
    FSTP cos_half

    FLD theta_half
    FSIN
    FSTP sin_half

    ; sqrt(D) = sqrt_mod*(cos(theta/2) + i*sin(theta/2))
    FLD sqrt_mod
    FMUL cos_half
    FSTP sqrt_re

    FLD sqrt_mod
    FMUL sin_half
    FSTP sqrt_im

    ; Вычисление корней: (-b ± sqrt(D)) / (2a)

    ; Числитель для root1: -b + sqrt(D)
    FLD sqrt_re
    FLD b_re
    FCHS
    FADD
    FSTP root1_num_re

    FLD sqrt_im
    FLD b_im
    FCHS
    FADD
    FSTP root1_num_im

    ; Числитель для root2: -b - sqrt(D)
    FLD sqrt_re
    FLD b_re
    FCHS
    FSUB
    FSTP root2_num_re

    FLD sqrt_im
    FLD b_im
    FCHS
    FSUB
    FSTP root2_num_im

    ; Знаменатель: 2a
    FLD a_re
    FADD ST(0), ST(0)
    FSTP denom_re

    FLD a_im
    FADD ST(0), ST(0)
    FSTP denom_im

    ; Модуль знаменателя в квадрате
    FLD denom_re
    FMUL ST(0), ST(0)
    FLD denom_im
    FMUL ST(0), ST(0)
    FADD
    FSTP denom_mod_sq

    ; Корень 1: (num_re + num_im*i) / denom
    ; Действительная часть
    FLD root1_num_re
    FMUL denom_re
    FLD root1_num_im
    FMUL denom_im
    FADD
    FDIV denom_mod_sq
    FSTP root1_re

    ; Мнимая часть
    FLD root1_num_im
    FMUL denom_re
    FLD root1_num_re
    FMUL denom_im
    FSUB
    FDIV denom_mod_sq
    FSTP root1_im

    ; Корень 2
    ; Действительная часть
    FLD root2_num_re
    FMUL denom_re
    FLD root2_num_im
    FMUL denom_im
    FADD
    FDIV denom_mod_sq
    FSTP root2_re

    ; Мнимая часть
    FLD root2_num_im
    FMUL denom_re
    FLD root2_num_re
    FMUL denom_im
    FSUB
    FDIV denom_mod_sq
    FSTP root2_im

    ; Результаты сохранены в root1_re, root1_im, root2_re, root2_im

    call ExitProcess, 0
END main