import cmath

# Сопроцессорный стек
fpu_stack = []

def fpu_push(value):
    """Помещает значение в стек сопроцессора (эмуляция FLD)"""
    fpu_stack.append(value)

def fpu_pop():
    """Извлекает значение из стека сопроцессора (эмуляция FSTP)"""
    return fpu_stack.pop()

def fpu_add():
    """Сложение ST(0) + ST(1) -> ST(1); Pop"""
    b = fpu_pop()
    a = fpu_pop()
    fpu_push(a + b)

def fpu_sub():
    """Вычитание ST(1) - ST(0) -> ST(1); Pop"""
    b = fpu_pop()
    a = fpu_pop()
    fpu_push(a - b)

def fpu_mul():
    """Умножение ST(0) * ST(1) -> ST(1); Pop"""
    b = fpu_pop()
    a = fpu_pop()
    fpu_push(a * b)

def fpu_div():
    """Деление ST(1) / ST(0) -> ST(1); Pop"""
    b = fpu_pop()
    a = fpu_pop()
    fpu_push(a / b)

def fpu_sqrt():
    """Корень из ST(0) -> ST(0)"""
    a = fpu_pop()
    fpu_push(cmath.sqrt(a))

# Коэффициенты квадратного трехчлена: az^2 + bz + c = 0
a = complex(1, 2)
b = complex(3, -4)
c = complex(2, 1)

# Вычисляем дискриминант: D = b^2 - 4ac
fpu_push(b)     # ST = b
fpu_push(b)     # ST = b, b
fpu_mul()       # ST = b*b

fpu_push(4)     # ST = b*b, 4
fpu_push(a)     # ST = b*b, 4, a
fpu_mul()       # ST = b*b, 4a
fpu_push(c)     # ST = b*b, 4a, c
fpu_mul()       # ST = b*b, 4ac

fpu_sub()       # ST = D = b*b - 4ac

# Извлекаем дискриминант
D = fpu_pop()

# Вычисляем корень из дискриминанта
fpu_push(D)
fpu_sqrt()
sqrt_D = fpu_pop()

# Вычисляем -b
fpu_push(-b)

# x1 = (-b + sqrt(D)) / (2a)
fpu_push(sqrt_D)
fpu_add()
fpu_push(2)
fpu_push(a)
fpu_mul()
fpu_div()
x1 = fpu_pop()

# x2 = (-b - sqrt(D)) / (2a)
fpu_push(-b)
fpu_push(sqrt_D)
fpu_sub()
fpu_push(2)
fpu_push(a)
fpu_mul()
fpu_div()
x2 = fpu_pop()

print(f"x1 = {x1}")
print(f"x2 = {x2}")
