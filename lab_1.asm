sseg segment stack 'stack'
    dw 256 dup(?)
sseg ends

data segment
    start_value db 5   
    current_value db ? 
    
data ends

code segment
assume cs:code, ds:data, ss:sseg

DEC_AND_JMP MACRO reg, lim, label
    dec reg
    cmp reg, lim
    je label
ENDM

start:
    mov ax, data
    mov ds, ax

    mov cl, start_value  
    mov current_value, cl 

BEGIN_LOOP:
    DEC_AND_JMP current_value, 2, END_LOOP
    ; mov current_value, cl 
    jmp BEGIN_LOOP

END_LOOP:
    ; mov current_value, cl 
    mov ax, 4C00h  
    int 21h

code ends
end start
