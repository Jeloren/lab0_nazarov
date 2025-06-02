dw double word
db define byte 1 байт
dup инициализ символами

в ds дата сегмент 
mov из 2 в 1 
push занос в стек
pop выносит из стека
call вызывает процедуру
lea сравнить с mov
near процедура внутрисегментная
far межсегментная
pusha
si source источник
di destination назначения (результата)
cx регистр счетчика
xor
lodsb загружает из si в ax
cmp сравнение
je jump equal
jcxz jump cx zero
ret
byte ptr явно с байтом данных

si значение
[si] адрес



je/jz	ZF=1	Jump if Equal/Zero
jne/jnz	ZF=0	Jump if Not Equal/Not Zero
ja/jnbe	CF=0 и ZF=0	Jump if Above (беззнаковое >)
jae/jnb	CF=0	Jump if Above or Equal (беззнаковое ≥)
jb/jnae	CF=1	Jump if Below (беззнаковое <)
jbe/jna	CF=1 или ZF=1	Jump if Below or Equal (беззнаковое ≤)
jg/jnle	ZF=0 и SF=OF	Jump if Greater (знаковое >)
jge/jnl	SF=OF	Jump if Greater or Equal (знаковое ≥)
jl/jnge	SF≠OF	Jump if Less (знаковое <)
jle/jng	ZF=1 или SF≠OF	Jump if Less or Equal (знаковое ≤)
jc	CF=1	Jump if Carry
jnc	CF=0	Jump if No Carry
jo	OF=1	Jump if Overflow
jno	OF=0	Jump if No Overflow
js	SF=1	Jump if Sign (отрицательное)
jns	SF=0	Jump if No Sign (положительное)
jp/jpe	PF=1	Jump if Parity/Even
jnp/jpo	PF=0	Jump if No Parity/Odd
lodsb — для чтения символов по одному;
rep stosb (в комбинации) — для массовой записи пробелов в конец строки.