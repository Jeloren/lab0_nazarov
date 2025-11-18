PROGRAM   segment 
assume CS:PROGRAM 
org   100h;пропуск PSP для COM-программы 
Start: jmp InitProc; переход на инициализацию 
;Р Е З И Д Е Н Т Н Ы Е   Д А Н Н Ы Е  
FuncNum equ 0EEh;несуществующая функция 
;прерывания BIOS Int16h 
CodeOut   equ   2D0Ch           
;код, возвращаемый нашим обработчиком Int16h 
TestInt09 equ   9D0Ah; слово перед Int09h 
TestInt16 equ  3AFAh; слово перед Int16h  


 OldInt09  label dword; сохраненный вектор 
Int09h: 
  OfsInt09 dw    ?    ;   его смещение 
  SegInt09 dw    ?    ;   и сегмент 
 
 OldInt16  label dword; сохраненный вектор 
Int16h: 
  OfsInt16 dw    ?    ;   его смещение 
  SegInt16 dw    ?    ;   и сегмент 
 
 OK_Text   db    0    ; признак гашения экрана 
 Sign      db    ?    ; количество нажатий Ctrl 
 VideoLen  equ   800h ; длина видеобуфера 
 
VideoBuf  db    160 dup(' ') 
 db  13 dup(' ') 
 db '======================================================' 
 db  26 dup(' ') 
 db '|                                                    |' 
 db  26 dup(' ') 
 db '|                For unblock input                   |' 
 db  26 dup(' ') 
 db '|                     <MAKS>                       |' 
 db  26 dup(' ') 
 db '|                                                    |' 
 db  26 dup(' ') 
 db '======================================================' 
 db  2000 dup(' ') 
 
 AttrBuf db VideoLen dup(07h)	; атрибуты экрана 
 VideoBeg dw 0B800h				; адрес начала видеообласти 
 VideoOffs dw ?					; смещение активной страницы 
 CurSize   dw ?					;сохраненный размер курсора 
 
 ; Р Е З И Д Е Н Т Н Ы Е   П Р О Ц Е Д У Р Ы  
;ПОДПРОГРАММА ОБМЕНА ВИДЕООБЛАСТИ С БУФЕРОМ 
;ПРОГРАММЫ 
 
VideoXcg proc
    lea   DI,VideoBuf   ; Установка адреса буфера символов
    lea   SI,AttrBuf    ; Установка адреса буфера атрибутов
    mov   AX,VideoBeg   ; Установка сегментного адреса начала видеообласти
    mov   ES,AX         ; Установка сегмента видеообласти
    mov   CX,VideoLen   ; Установка длины видеобуфера
    mov   BX,VideoOffs  ; Установка начального смещения строки

Draw:
    mov   AX,ES:[BX]    ; Получение символа и атрибута из видеобуфера
    xchg  AH,DS:[SI]    ; Обмен атрибута с буфером атрибутов
    xchg  AL,DS:[DI]    ; Обмен символа с буфером символов
    mov   ES:[BX],AX    ; Установка нового символа и атрибута в видеобуфер

    inc   SI            ; Увеличение адреса в буфере атрибутов
    inc   DI            ; Увеличение адреса в буфере символов
    inc   BX            ; Увеличение адреса в видеобуфере
    inc   BX            ; Увеличение адреса в видеобуфере

    loop  Draw          ; Повторение для всей видеообласти
    ret                 ; Возврат из процедуры
VideoXcg endp

 
  ;ОБРАБОТЧИК ПРЕРЫВАНИЯ Int09h (ПРЕРЫВАНИЕ ОТ  
; КЛАВИАТУРЫ) 
 
  dw TestInt09; слово для обнаружения перехвата 
 
 Int09Hand proc 
     push  AX            ;¬ 
     push  BX            ;¦ 
     push  CX            ;¦сохранить 
     push  DI            ;¦используемые 
     push  SI            ;¦регистры 
     push  DS            ;¦ 
     push  ES            ;- 
 
     push  CS            ;¬указать DS на 
     pop   DS            ;-нашу программу 
     in AL,60h			 ; получить скан код нажатой клавиши 
     cmp AL,30h			 ; проверить на скан-код клавиши <B>
     jne Exit_09		 ; и выйти, если не он 
     xor AX,AX    
     mov   ES,AX 		 ; проверить флаги клавиатуры на 
     mov AL,ES:[417h]
	 
	 and   AL, 00000110b      ;  Ctrl + LeftShift
     cmp   AL, 00000110b      
     je    Cont
 
   Exit_09: 
     jmp   Exit09        ;выход 
 
   Cont: 
	 sti                 ;разрешить прерывания 
	 mov   AH,0Fh        ;¬получить текущий 
     int   10h         	 ;-видеорежим 
     cmp   AL,2          ;¬ 
     je    InText        ;¦перейти на InText 
     cmp   AL,3          ;¦если режим 
     je    InText        ;¦текстовый 80#25 
     cmp   AL,7          ;¦ 
     je    InText        ;- 
 
     jmp   short SwLoop1 ;иначе - пропустить 
 
  InText: 
     xor   AX,AX         ;¬установить сегментный 
     mov   ES,AX         ;-адрес в 0000h 
 
  mov AX,ES:[44Eh]    ;¬получить смещение активной 
  mov VideoOffs,AX    ;-страницы в VideoOffs 
 
  mov AX,ES:[44Ch]    ;¬сравнить длину видеобуфера 
  cmp AX,1000h        ;¦с 1000h.Если не равно, 
  jne Exit009         ;¦то режим EGA Lines 
                      ;-(экран тушить не надо) 
  mov   AH,03h        ;¬иначе сохранить 
  int   10h           ;¦размер курсора 
  mov   CurSize,CX    ;-в CurSize 
 
  mov   AH,01h        ;¬ 
  mov   CH,20h        ;¦и подавить его 
  int   10h           ;- 
 
  mov OK_Text,01h; установить признак гашения 
                 ; экрана 
  call  VideoXcg  ;и вызвать процедуру гашения 
 
SwLoop1:
    ; Y1: Ожидание нажатия Y (15h)
    Y1:
        in  AL, 60h
        cmp AL, 15h         ; нажата Y
        je  Y2
        jmp Y1              ; продолжаем ждать Y

    ; Y2: Ожидание отпускания Y (95h)
    Y2:
        in  AL, 60h
        cmp AL, 95h         ; отпущена Y
        je  A1_New
        jmp Y2              ; продолжаем ждать отпускания Y

    ; A1_New: Ожидание нажатия A (1Eh)
    A1_New:
        in  AL, 60h
        cmp AL, 1Eh         ; нажата A
        je  A2_New
        cmp AL, 95h         ; Отпускание Y (если нажат Y, а затем A до отпускания Y, то A1_New пропустится)
        je  A1_New
        jmp Y1              ; Сброс, если нажата другая клавиша

    ; A2_New: Ожидание отпускания A (9Eh)
    A2_New:
        in  AL, 60h
        cmp AL, 9Eh         ; отпущена A
        je  R1
        jmp A2_New
        
    ; R1: Ожидание нажатия R (13h)
    R1:
        in  AL, 60h
        cmp AL, 13h         ; нажата R
        je  R2
        cmp AL, 9Eh         ; Отпускание A
        je  R1
        jmp Y1              ; Сброс
        
    ; R2: Ожидание отпускания R (93h)
    R2:
        in  AL, 60h
        cmp AL, 93h         ; отпущена R
        je  I1
        jmp R2
        
    ; I1: Ожидание нажатия I (17h)
    I1:
        in  AL, 60h
        cmp AL, 17h         ; нажата I
        je  I2
        cmp AL, 93h         ; Отпускание R
        je  I1
        jmp Y1              ; Сброс
        
    ; I2: Ожидание отпускания I (97h)
    I2:
        in  AL, 60h
        cmp AL, 97h         ; отпущена I
        je  C1
        jmp I2
        
    ; C1: Ожидание нажатия C (2Eh)
    C1:
        in  AL, 60h
        cmp AL, 2Eh         ; нажата C
        je  C2
        cmp AL, 97h         ; Отпускание I
        je  C1
        jmp Y1              ; Сброс
        
    ; C2: Ожидание отпускания C (AEh)
    C2:
        in  AL, 60h
        cmp AL, 0AEh        ; отпущена C
        je  EndName
        jmp C2
	        
EndName:
	cmp   OK_Text,01h	
	jne   Exit009	 

	call  VideoXcg	 
	mov   AH,01h	 
	mov   CX,CurSize	
	int   10h		

	mov   OK_Text,0h
  
  Exit009: 
   xor  AX, AX 
   mov  ES, AX 
   mov AL,ES:[417h];
   and AL,11110011b;
   mov ES:[417h],AL;
 
   mov   AL,20h        ; в этой команде мы сообщаем, что прерывания закончились 
   out   20h,AL        ; это слово сбрасывает установленный бит соответсвующий максимальному приоритету
 
   cli                 ;запретить прерывания 
   pop   ES            ;¬ 
   pop   DS            ;¦ 
   pop   SI            ;¦восстановить 
   pop   DI            ;¦используемые 
   pop   CX            ;¦регистры 
   pop   BX            ;¦ 
   pop   AX            ;- 
   iret                ;выйти из прерывания 
 
  Exit09: cli          ;запретить прерывания 
   pop   ES            ;¬ 
   pop   DS            ;¦ 
   pop   SI            ;¦восстановить 
   pop   DI            ;¦используемые 
   pop   CX            ;¦регистры 
   pop   BX            ;¦ 
   pop   AX            ;- 
 jmp CS:OldInt09;¬;передать управление 
; "по цепочке" следующему обработчику Int09h 
 Int09Hand endp 
 
;ОБРАБОТЧИК ПРЕРЫВАНИЯ Int16h (ВИДЕО ФУНКЦИИ 
;BIOS) 
 
  dw TestInt16; слово для обнаружения перехвата 
  Presense proc 
  cmp AH,FuncNum; обращение от нашей программы? 
  jne Pass; если нет то ничего не делать 
  mov AX,CodeOut; иначе в AX условленный код 
  iret          ;и возвратиться 
 Pass: jmp   CS:OldInt16   ;передать управление 
;"по цепочке";следующему обработчику Int16h 
 Presense endp 
 
 ;=============================================================================
 ResEnd      db    ?	
			
 On	     	 equ   1	
 Off	     equ   0	
 Bell	     equ   7	
 CR	     	 equ   13	
 LF	     	 equ   10	
 MinDosVer   equ   2	

 InstFlag    db    ?	
 SaveCS      dw    ?	
			

 Copyright   db CR,LF,' L O C K E R '
			 db '',CR,LF,LF,'$'
 VerDosMsg   db ''
			 db Bell,CR,LF,'$'
 InstMsg     db ''
			 db '',CR,LF
			 db 'ENTER <Ctrl + LeftShift + B>',CR,LF
			 db CR,LF,'$'
 AlreadyMsg  db ': LOCKER  AlreadyMsg '
			 db Bell,CR,LF,'$'
 UninstMsg   db ' LOCKER  UninstMsg '
			 db CR,LF,'$'
 NotInstMsg  db ' LOCKER  NotInstMsg'
			 db Bell,CR,LF,'$'
 NotSafeMsg  db 'LOCKER NotSafeMsg'
			 db '',Bell,CR,LF,'$'


 Locker      equ   0	  
 include     INFO.INC	  


 InitProc proc
    mov   AH,09h
    lea   DX,Copyright     ; Вывод сообщения о копирайте
    int   21h

    lea   DX,VerDosMsg     ; Проверка версии DOS
    call  ChkDosVer
    jc    Output          ; Если версия DOS не подходит, выйти

    call  PresentTest     ; Проверка наличия программы в памяти

    mov   BL,DS:[5Dh]     ; Получение параметра командной строки
    and   BL,11011111b
    cmp   BL,'I'          ; Проверка на установку (I)
    je    Install
    cmp   BL,'U'          ; Проверка на удаление (U)
    je    Uninst

    call  @InfoAbout      ; Вывод информации о программе
    jmp   short ToDos

Install:
    lea   DX,AlreadyMsg   ; Проверка, установлена ли уже программа
    cmp   InstFlag,On
    je    Output

    xor   AX,AX
    mov   ES,AX
    mov   AL,ES:[411h]    ; Проверка видеорежима
    and   AL,30h
    cmp   AL,30h
    jne   Vid1
    mov   VideoBeg,0B000h ; Установка начального адреса видеобуфера

Vid1:
    call  GrabIntVec      ; Захват векторов прерываний

    mov   AX,DS:[2Ch]     ; Освобождение памяти
    mov   ES,AX
    mov   AH,49h
    int   21h

    mov   AH,09h          ; Вывод сообщения об установке
    lea   DX,InstMsg
    int   21h

    lea   DX,ResEnd       ; Установка программы в память
    int   27h

Uninst:
    lea   DX,NotInstMsg   ; Проверка, установлена ли программа
    cmp   InstFlag,Off
    je    Output

    lea   DX,NotSafeMsg   ; Проверка безопасности удаления
    call  TestIntVec
    jc    Output

    call  FreeIntVec      ; Освобождение векторов прерываний

    mov   AH,49h          ; Освобождение памяти
    mov   ES,SaveCS
    int   21h

    lea   DX,UninstMsg    ; Вывод сообщения об удалении

Output:
    mov   AH,09h          ; Вывод сообщения
    int   21h

ToDos:
    mov   AX,4C00h        ; Возврат в DOS
    int   21h
    ret
InitProc endp



ChkDosVer proc
    mov   AH,30h         ; Функция DOS для получения версии DOS
    int   21h            ; Вызов функции DOS
    cmp   AL,MinDosVer   ; Сравнение версии DOS с минимальной требуемой версией

    clc                  ; Очистка флага переноса (CF)
    jge   Norma          ; Если версия DOS >= MinDosVer, перейти к Norma
    stc                  ; Установка флага переноса (CF)

Norma:
    ret                  ; Возврат из процедуры
ChkDosVer endp



PresentTest proc
    mov   InstFlag,Off   ; Установка флага InstFlag в Off
    mov   AH,FuncNum     ; Установка номера функции для проверки
    int   16h            ; Вызов прерывания BIOS
    cmp   AX,CodeOut     ; Сравнение возвращаемого кода с ожидаемым кодом
    jne   Return         ; Если не совпадает, перейти к Return
    mov   InstFlag,On    ; Установка флага InstFlag в On

Return:
    ret                  ; Возврат из процедуры
PresentTest endp



GrabIntVec proc
    mov   AX,3509h       ; Функция DOS для получения вектора прерывания Int09h
    int   21h            ; Вызов функции DOS
    mov   OfsInt09,BX    ; Сохранение смещения вектора Int09h
    mov   SegInt09,ES    ; Сохранение сегмента вектора Int09h

    mov   AX,3516h       ; Функция DOS для получения вектора прерывания Int16h
    int   21h            ; Вызов функции DOS
    mov   OfsInt16,BX    ; Сохранение смещения вектора Int16h
    mov   SegInt16,ES    ; Сохранение сегмента вектора Int16h

    mov   AX,2509h       ; Функция DOS для установки нового вектора прерывания Int09h
    lea   DX,Int09Hand   ; Установка нового обработчика прерывания Int09h
    int   21h            ; Вызов функции DOS

    mov   AX,2516h       ; Функция DOS для установки нового вектора прерывания Int16h
    lea   DX,Presense    ; Установка нового обработчика прерывания Int16h
    int   21h            ; Вызов функции DOS

    ret                  ; Возврат из процедуры
GrabIntVec endp


TestIntVec proc
    mov   AX,3509h       ; Функция DOS для получения вектора прерывания Int09h
    int   21h            ; Вызов функции DOS
    cmp   ES:[BX-2],TestInt09 ; Сравнение слова перед вектором Int09h с TestInt09
    stc                  ; Установка флага переноса (CF)
    jne   Cant           ; Если не совпадает, перейти к Cant

    mov   AX,3516h       ; Функция DOS для получения вектора прерывания Int16h
    int   21h            ; Вызов функции DOS
    cmp   ES:[BX-2],TestInt16 ; Сравнение слова перед вектором Int16h с TestInt16
    stc                  ; Установка флага переноса (CF)
    jne   Cant           ; Если не совпадает, перейти к Cant

    mov   SaveCS,ES      ; Сохранение сегмента вектора Int16h
    clc                  ; Очистка флага переноса (CF)

Cant:
    ret                  ; Возврат из процедуры
TestIntVec endp


FreeIntVec proc
    push  DS            ; Сохранение регистра DS

    mov   AX,2509h       ; Функция DOS для установки оригинального вектора прерывания Int09h
    mov   DS,ES:SegInt09 ; Установка сегмента оригинального вектора Int09h
    mov   DX,ES:OfsInt09 ; Установка смещения оригинального вектора Int09h
    int   21h            ; Вызов функции DOS

    mov   AX,2516h       ; Функция DOS для установки оригинального вектора прерывания Int16h
    mov   DS,ES:SegInt16 ; Установка сегмента оригинального вектора Int16h
    mov   DX,ES:OfsInt16 ; Установка смещения оригинального вектора Int16h
    int   21h            ; Вызов функции DOS

    pop   DS             ; Восстановление регистра DS
    ret                  ; Возврат из процедуры
FreeIntVec endp


 PROGRAM   ends
	   end	 Start
