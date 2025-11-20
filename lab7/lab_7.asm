; -----------------------------------------------------------
; LOCKER_YARIK_FINAL.asm
; Пароль: Y A R I K (скан-коды Set1)
; Блокировка: Ctrl + LeftShift + B
; Исправлено: Ожидание отпускания последней клавиши (Fix 'k' bug)
; -----------------------------------------------------------

PROGRAM   segment
assume CS:PROGRAM
org   100h         

Start:    jmp   InitProc     

;░░░░░░░░░ Р Е З И Д Е Н Т Н Ы Е   Д А Н Н Ы Е ░░░░░░░░░░░░

FuncNum   equ   0EEh           
CodeOut   equ   2D0Ch          
TestInt09 equ   9D0Ah          
TestInt16 equ   3AFAh          

OldInt09  label dword          
 OfsInt09 dw    ?              
 SegInt09 dw    ?

OldInt16  label dword          
 OfsInt16 dw    ?              
 SegInt16 dw    ?

OK_Text   db    0              
VideoLen  equ   800h           

; Пароль: Y A R I K
PwdSeq    db  15h,1Eh,13h,17h,25h  
PwdLen    equ 5                  
KeyPos    db  0                  

VideoBuf  db    160 dup(' ')
db  13 dup(' ')
db '======================================================'
db  26 dup(' ')
db '|                                                    |'
db  26 dup(' ')
db '|                For unblock input                   |'
db  26 dup(' ')
db '|                     <YARIK>                        |'
db  26 dup(' ')
db '|                                                    |'
db  26 dup(' ')
db '======================================================'
db  2000 dup(' ')

AttrBuf   db    VideoLen dup(07h)  
VideoBeg  dw    0B800h         
VideoOffs dw    ?              
CurSize   dw    ?              

;░░░░░░ Р Е З И Д Е Н Т Н Ы Е   П Р О Ц Е Д У Р Ы ░░░░░░░░░

VideoXcg proc
    lea   DI,VideoBuf   
    lea   SI,AttrBuf    
    mov   AX,VideoBeg   
    mov   ES,AX         
    mov   CX,VideoLen   
    mov   BX,VideoOffs  
Draw:
    mov   AX,ES:[BX]    
    xchg  AH,DS:[SI]    
    xchg  AL,DS:[DI]    
    mov   ES:[BX],AX    
    inc   SI            
    inc   DI            
    inc   BX            
    inc   BX            
    loop  Draw          
    ret                 
VideoXcg endp

; ОБРАБОТЧИК ПРЕРЫВАНИЯ Int09h 
    dw    TestInt09     

Int09Hand proc
    push  AX            
    push  BX            
    push  CX            
    push  DI            
    push  SI            
    push  DS            
    push  ES            

    push  CS            
    pop   DS            

    in    AL,60h        ; скан-код

    ; Проверка нажатия Ctrl+Shift+B
    cmp   AL,30h        ; Клавиша <B>?
    je    CheckFlags    
    jmp   Exit09        ; Дальний прыжок, если не B

CheckFlags:
    xor   AX,AX         
    mov   ES,AX         
    mov   AL,ES:[417h]  
    
    ; Ctrl + LeftShift
    and   AL, 00000110b 
    cmp   AL, 00000110b 
    je    Cont          ; Блокируем
    
    jmp   Exit09        

Cont:
    sti                 

    mov   AH,0Fh        
    int   10h           
    cmp   AL,2          
    je    InText        
    cmp   AL,3          
    je    InText        
    cmp   AL,7          
    je    InText        

    jmp   short SwLoop1 

InText:
    xor   AX,AX         
    mov   ES,AX         

    mov   AX,ES:[44Eh]  
    mov   VideoOffs,AX  

    mov   AX,ES:[44Ch]  
    cmp   AX,1000h      
    je    SaveCursor    
    jmp   Exit009       

SaveCursor:
    mov   AH,03h        
    int   10h           
    mov   CurSize,CX    

    mov   AH,01h        
    mov   CH,20h        
    int   10h           

    mov   OK_Text,01h   
    call  VideoXcg      

; --- ЦИКЛ ОЖИДАНИЯ ПАРОЛЯ ---
SwLoop1:
KbdWait:                
    in    AL,64h
    test  AL,01h
    jz    KbdWait

    in    AL,60h

    cmp   AL,0E0h
    je    SwLoop1
    cmp   AL,0E1h
    je    SwLoop1
    test  AL,80h         
    jnz   SwLoop1

    ; YARIK Check
    xor   BH,BH
    mov   BL,KeyPos
    cmp   AL, PwdSeq[BX]
    jne   PwdNotMatch   

    inc   BL            
    mov   KeyPos,BL
    cmp   BL,PwdLen     
    jne   SwLoop1       

    ; =================================================
    ; ПАРОЛЬ ВЕРЕН. ЖДЕМ ОТПУСКАНИЯ КЛАВИШИ (FIX)
    ; =================================================
WaitRelease:
    in    AL, 64h       ; Читаем статус
    test  AL, 01h       ; Есть данные?
    jz    WaitRelease   ; Ждем данные

    in    AL, 60h       ; Читаем данные
    test  AL, 80h       ; Это код отпускания (Break code, бит 7 = 1)?
    jz    WaitRelease   ; Если 0 (нажатие), значит идет автоповтор -> игнорируем и ждем дальше
                        ; Если 1 (отпускание), выходим из цикла и разблокируем

    ; --- РАЗБЛОКИРОВКА ---
    mov   KeyPos,0      
    cmp   OK_Text,01h   
    jne   UnlockDone    

    call  VideoXcg      

    mov   AH,01h        
    mov   CX,CurSize    
    int   10h           

    mov   OK_Text,0     

UnlockDone:
    jmp   Exit009       

PwdNotMatch:
    cmp   AL, PwdSeq        
    jne   ResetPwdTo0       
    mov   KeyPos,1          
    jmp   SwLoop1

ResetPwdTo0:
    mov   KeyPos,0          
    jmp   SwLoop1

Exit009:
    xor   AX,AX         
    mov   ES,AX         
    mov   AL,ES:[417h]  
    and   AL,11110000b  ; Очистка Shift/Ctrl
    mov   ES:[417h], AL 

    mov   AL,20h        
    out   20h,AL        

    cli                 
    pop   ES            
    pop   DS            
    pop   SI            
    pop   DI            
    pop   CX            
    pop   BX            
    pop   AX            
    iret                

Exit09:
    cli                 
    pop   ES            
    pop   DS            
    pop   SI            
    pop   DI            
    pop   CX            
    pop   BX            
    pop   AX            
    jmp   CS:OldInt09   
Int09Hand endp

    dw    TestInt16     
Presense proc
    cmp   AH,FuncNum    
    jne   Pass          
    mov   AX,CodeOut    
    iret                
Pass:
    jmp   CS:OldInt16   
Presense endp

ResEnd      db    ?    
On          equ   1    
Off         equ   0    
Bell        equ   7    
CR          equ   13   
LF          equ   10   
MinDosVer   equ   2    

InstFlag    db    ?    
SaveCS      dw    ?    

Copyright   db CR,LF,' LOCKER YARIK v3 (Fixed) ',CR,LF,LF,'$'
VerDosMsg   db 'Wrong DOS ver',Bell,CR,LF,'$'
InstMsg     db 'Installed! Ctrl+LeftShift+B to Lock',CR,LF,'$'
AlreadyMsg  db 'Already Installed',Bell,CR,LF,'$'
UninstMsg   db 'Uninstalled',CR,LF,'$'
NotInstMsg  db 'Not Installed',Bell,CR,LF,'$'
NotSafeMsg  db 'Cannot Uninstall safely',Bell,CR,LF,'$'

Locker      equ   0      
include     INFO.INC     

InitProc proc
    mov   AH,09h          
    lea   DX,Copyright    
    int   21h             

    lea   DX,VerDosMsg    
    call  ChkDosVer       
    jc    Output          

    call  PresentTest     

    mov   BL,DS:[5Dh]     
    and   BL,11011111b    
    cmp   BL,'I'          
    je    Install         
    cmp   BL,'U'          
    je    Uninst          

    jmp   Install         

Install:
    lea   DX,AlreadyMsg
    cmp   InstFlag,On     
    je    Output          

    xor   AX,AX           
    mov   ES,AX           
    mov   AL,ES:[411h]    
    and   AL,30h          
    cmp   AL,30h          
    jne   Vid1            
    mov   VideoBeg,0B000h 

Vid1:
    call  GrabIntVec      

    mov   AX,DS:[2Ch]     
    mov   ES,AX           
    mov   AH,49h          
    int   21h             

    mov   AH,09h          
    lea   DX,InstMsg      
    int   21h             

    lea   DX,ResEnd       
    int   27h             

Uninst:
    lea   DX,NotInstMsg   
    cmp   InstFlag,Off    
    je    Output          

    lea   DX,NotSafeMsg   
    call  TestIntVec      
    jc    Output          

    call  FreeIntVec      

    mov   AH,49h          
    mov   ES,SaveCS       
    int   21h             

    lea   DX,UninstMsg

Output:
    mov   AH,09h          
    int   21h             

ToDos:
    mov   AX,4C00h        
    int   21h             
    ret                   
InitProc endp

ChkDosVer proc
    mov   AH,30h         
    int   21h            
    cmp   AL,MinDosVer   
    clc                  
    jge   Norma          
    stc                  
Norma:
    ret                  
ChkDosVer endp

PresentTest proc
    mov   InstFlag,Off   
    mov   AH,FuncNum     
    int   16h            
    cmp   AX,CodeOut     
    jne   Return         
    mov   InstFlag,On    
Return:
    ret                  
PresentTest endp

GrabIntVec proc
    mov   AX,3509h       
    int   21h            
    mov   OfsInt09,BX    
    mov   SegInt09,ES    

    mov   AX,3516h       
    int   21h            
    mov   OfsInt16,BX    
    mov   SegInt16,ES    

    mov   AX,2509h       
    lea   DX,Int09Hand   
    int   21h            

    mov   AX,2516h       
    lea   DX,Presense    
    int   21h            
    ret
GrabIntVec endp

TestIntVec proc
    mov   AX,3509h            
    int   21h                 
    cmp   ES:[BX-2],TestInt09 
    stc                       
    jne   Cant                

    mov   AX,3516h            
    int   21h                 
    cmp   ES:[BX-2],TestInt16 
    stc                       
    jne   Cant                

    mov   SaveCS,ES           
    clc                       
Cant:
    ret                       
TestIntVec endp

FreeIntVec proc
    push  DS             

    mov   AX,2509h       
    mov   DS,ES:SegInt09 
    mov   DX,ES:OfsInt09 
    int   21h            

    mov   AX,2516h       
    mov   DS,ES:SegInt16 
    mov   DX,ES:OfsInt16 
    int   21h            

    pop   DS             
    ret                  
FreeIntVec endp

PROGRAM   ends
      end   Start