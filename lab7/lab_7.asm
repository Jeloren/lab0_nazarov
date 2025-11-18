; -----------------------------------------------------------
; LOCKER_YARIK.asm
; Модифицированный LOCKER.asm с паролем Y A R I K (скан-коды Set1)
; minimal changes: заменена только секция ожидания последовательности клавиш
; -----------------------------------------------------------

PROGRAM   segment
assume CS:PROGRAM
org   100h         ; пропуск PSP для COM-программы

Start:    jmp   InitProc     ; переход на инициализацию


;░░░░░░░░░ Р Е З И Д Е Н Т Н Ы Е   Д А Н Н Ы Е ░░░░░░░░░░░░

FuncNum   equ   0EEh           ; несуществующая функция пре-
                               ; рывания BIOS Int16h
CodeOut   equ   2D0Ch          ; код, возвращаемый нашим об-
                               ; работчиком Int16h
TestInt09 equ   9D0Ah          ; слово перед Int09h
TestInt16 equ   3AFAh          ; слово перед Int16h

OldInt09  label dword          ; сохраненный вектор Int09h:
 OfsInt09 dw    ?              ;   его смещение
 SegInt09 dw    ?              ;   и сегмент

OldInt16  label dword          ; сохраненный вектор Int16h:
 OfsInt16 dw    ?              ;   его смещение
 SegInt16 dw    ?              ;   и сегмент

OK_Text   db    0              ; признак гашения экрана
Sign      db    ?              ; количество нажатий Ctrl
VideoLen  equ   800h           ; длина видеобуфера

; -------------------------------
; ПАРОЛЬ И ПОЛЕ ДЛЯ ОТСЛЕЖИВАНИЯ
; -------------------------------
; Пароль: Y A R I K (скан-коды Set1)
; Y = 15h, A = 1Eh, R = 13h, I = 17h, K = 25h
PwdSeq    db  15h,1Eh,13h,17h,25h  ; последовательность скан-кодов пароля
PwdLen    equ 5                  ; длина пароля
KeyPos    db  0                  ; текущая позиция вводимого пароля (0 - ничего не введено)

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

AttrBuf   db    VideoLen dup(07h)  ; атрибуты экрана
VideoBeg  dw    0B800h         ; адрес начала видеообласти
VideoOffs dw    ?              ; смещение активной страницы
CurSize   dw    ?              ; сохраненный размер курсора

;░░░░░░ Р Е З И Д Е Н Т Н Ы Е   П Р О Ц Е Д У Р Ы ░░░░░░░░░

;ПОДПРОГРАММА ОБМЕНА ВИДЕООБЛАСТИ С БУФЕРОМ ПРОГРАММЫ
VideoXcg proc
    lea   DI,VideoBuf   ; Установка адреса буфера символов
    lea   SI,AttrBuf    ; Установка адреса буфера атрибутов

    mov   AX,VideoBeg   ; ┐в ES - сегментный адрес
    mov   ES,AX         ; ┘начала видеообласти

    mov   CX,VideoLen   ; в CX - длина видеобуфера
    mov   BX,VideoOffs  ; в BX - нач. смещение строки

Draw:
    mov   AX,ES:[BX]    ; ┐обменять символ/атрибут на
    xchg  AH,DS:[SI]    ; │экране с символом и атрибу-
    xchg  AL,DS:[DI]    ; │том из буферов
    mov   ES:[BX],AX    ; ┘

    inc   SI            ; ┐увеличить адрес
    inc   DI            ; ┘в буферах
    inc   BX            ; ┐увеличить адрес
    inc   BX            ; ┘в видеобуфере

    loop  Draw          ; сделать для всей видеообласти
    ret                 ; возврат из процедуры
VideoXcg endp

;ОБРАБОТЧИК ПРЕРЫВАНИЯ Int09h (ПРЕРЫВАНИЕ ОТ КЛАВИАТУРЫ)
    dw    TestInt09     ; слово для обнаружения перехвата

Int09Hand proc
    push  AX            ; ┐
    push  BX            ; │
    push  CX            ; │сохранить
    push  DI            ; │используемые
    push  SI            ; │регистры
    push  DS            ; │
    push  ES            ; ┘

    push  CS            ; ┐указать DS на
    pop   DS            ; ┘нашу программу

    in    AL,60h        ; получить скан-код нажатой клавиши

    cmp   AL,30h        ; проверить на скан-код клавиши <B>
    jne   Exit_09       ; ┘и выйти, если не он (в оригинале была <L>)

    xor   AX,AX         ; ┐
    mov   ES,AX         ; │проверить флаги клавиатуры на
    mov   AL,ES:[417h]  ; │нажатие <Ctrl+LeftShift>
                        ; │(оригинал проверял Ctrl+Alt)
    and   AL, 00000110b ; требуем Ctrl + LeftShift (флаги 02h и 04h)
    cmp   AL, 00000110b ; 
    je    Cont          ; ┘

Exit_09:
    jmp   Exit09        ; выход

Cont:
    sti                 ; разрешить прерывания

    mov   AH,0Fh        ; ┐получить текущий
    int   10h           ; ┘видеорежим
    cmp   AL,2          ; ┐
    je    InText        ; │перейти на InText
    cmp   AL,3          ; │если режим
    je    InText        ; │текстовый 80#25
    cmp   AL,7          ; │
    je    InText        ; ┘

    jmp   short SwLoop1 ; иначе - пропустить

InText:
    xor   AX,AX         ; ┐установить сегментный
    mov   ES,AX         ; ┘адрес в 0000h

    mov   AX,ES:[44Eh]  ; ┐получить смещение активной
    mov   VideoOffs,AX  ; ┘страницы в VideoOffs

    mov   AX,ES:[44Ch]  ; ┐сравнить длину видеобуфера
    cmp   AX,1000h      ; │с 1000h.Если не равно,
    jne   Exit009       ; │то режим EGA Lines (экран тушить не надо)
                        ; ┘
    mov   AH,03h        ; ┐иначе сохранить
    int   10h           ; │размер курсора
    mov   CurSize,CX    ; ┘в CurSize

    mov   AH,01h        ; ┐
    mov   CH,20h        ; │и подавить его
    int   10h           ; ┘

    mov   OK_Text,01h   ; установить признак гашения
                        ; экрана
    call  VideoXcg      ; и вызвать процедуру гашения

; ---- ВАЖНО: дальше заменена логика ожидания последовательности клавиш ----
; Вместо оригинальной логики <Ctrl> x 3 используется пароль Y A R I K (5 символов)

SwLoop1:
KbdWait:                ; ждем, пока в порту 64h появится код (OBF)
    in    AL,64h
    test  AL,01h
    jz    KbdWait

    ; получить код
    in    AL,60h

    ; игнорировать E0/E1 префиксы и break-коды
    cmp   AL,0E0h
    je    SwLoop1
    cmp   AL,0E1h
    je    SwLoop1
    test  AL,80h         ; break-код ? (высокий бит)
    jnz   SwLoop1

    ; --- Теперь проверяем ввод пароля Y A R I K ---
    ; AL содержит скан-код нажатия (Set1)

    ; Сравниваем с текущим ожидаемым символом пароля
    xor   BH,BH
    mov   BL,KeyPos
    cmp   AL, PwdSeq[BX]
    jne   PwdNotMatch   ; если не совпало - сбросить или проверить первый символ

    ; совпало
    inc   BL            ; увеличить позицию в пароле
    mov   KeyPos,BL
    cmp   BL,PwdLen     ; проверим, введен ли весь пароль
    jne   SwLoop1       ; если нет, то ждем следующую клавишу

    ; введены все символы пароля
    mov   KeyPos,0      ; сбросить позицию пароля
    cmp   OK_Text,01h   ; ┐если экран не был выключен,
    jne   SwLoop1       ; ┘то продолжить ожидание (ошибка, не должно быть)

    call  VideoXcg      ; иначе включить экран

    mov   AH,01h        ; ┐
    mov   CX,CurSize    ; │восстановить курсор
    int   10h           ; ┘

    mov   OK_Text,0     ; сбросить признак гашения экрана
    jmp   SwLoop1

PwdNotMatch:
    ; если не совпало ? если это первая буква пароля, то установить pos=1
    cmp   AL, PwdSeq        ; сравнить с первым символом пароля
    jne   ResetPwdTo0       ; если не первый, то сбросить ввод
    mov   KeyPos,1          ; если совпал первый, то начать ввод (KeyPos = 1)
    jmp   SwLoop1

ResetPwdTo0:
    mov   KeyPos,0          ; сбросить позицию пароля
    jmp   SwLoop1

; ---- конец заменённого блока ----

Exit009:
    xor   AX,AX         ; ┐
    mov   ES,AX         ; │очистить флаги нажатия
    mov   AL,ES:[417h]  ; │<Control+Alt> по адресу
    and   AL,11110011b  ; │0000h:0417h и флаги
    mov   ES:[417h],AL  ; │<LeftControl+LeftAlt>
    mov   AL,ES:[418h]  ; │по адресу 0000h:0418h (оригинал)
    and   AL,11111100b  ; │
    mov   ES:[418h],AL  ; ┘

    mov   AL,20h        ; ┐обслужить контроллер
    out   20h,AL        ; ┘прерываний

    cli                 ; запретить прерывания
    pop   ES            ; ┐
    pop   DS            ; │
    pop   SI            ; │восстановить
    pop   DI            ; │используемые
    pop   CX            ; │регистры
    pop   BX            ; │
    pop   AX            ; ┘
    iret                ; выйти из прерывания

Exit09:
    cli                 ; запретить прерывания
    pop   ES            ; ┐
    pop   DS            ; │
    pop   SI            ; │восстановить
    pop   DI            ; │используемые
    pop   CX            ; │регистры
    pop   BX            ; │
    pop   AX            ; ┘
    jmp   CS:OldInt09   ; ┐передать управление "по цепочке"
                        ; ┘следующему обработчику Int09h
Int09Hand endp

;ОБРАБОТЧИК ПРЕРЫВАНИЯ Int16h (ВИДЕО ФУНКЦИИ BIOS)
    dw    TestInt16     ; слово для обнаружения перехвата
Presense proc
    cmp   AH,FuncNum    ; обращение от нашей программы?
    jne   Pass          ; если нет то ничего не делать
    mov   AX,CodeOut    ; иначе в AX условленный код
    iret                ; и возвратиться
Pass:
    jmp   CS:OldInt16   ; передать управление "по цепочке"
                        ; следующему обработчику Int16h
Presense endp


;░░░░░░░░ Н Е Р Е З И Д Е Н Т Н Ы Е   Д А Н Н Ы Е ░░░░░░░░░

ResEnd      db    ?    ; байт для определения границы ре-
                       ; зидентной части программы
On          equ   1    ; значение "установлен" для флагов
Off         equ   0    ; значение "сброшен" для флагов
Bell        equ   7    ; код символа BELL
CR          equ   13   ; код символа CR
LF          equ   10   ; код символа LF
MinDosVer   equ   2    ; минимальная возможная версия DOS

InstFlag    db    ?    ; флаг наличия программы в памяти
SaveCS      dw    ?    ; сохраненный CS резидентной прог-
                       ; раммы

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


;░░░░░░ Н Е Р Е З И Д Е Н Т Н Ы Е   П Р О Ц Е Д У Р Ы ░░░░░

;ВКЛЮЧАЕМЫЙ ФАЙЛ ДЛЯ ВЫПОЛНЕНИЯ ПРОЦЕДУРЫ ВЫВОДА ИНФОРМАЦИИ
Locker      equ   0      ; имя для идентификации пpогpаммы
                         ; во включаемом файле
include     INFO.INC     ; включаемый файл с процедурой вы-
                         ; вода информации

;ГЛАВНАЯ ПРОЦЕДУРА ИНИЦИАЛИЗАЦИИ
InitProc proc
    mov   AH,09h          ; ┐
    lea   DX,Copyright    ; │вывести начальное сообщение
    int   21h             ; ┘

    lea   DX,VerDosMsg    ; ┐проверить версию DOS и вы-
    call  ChkDosVer       ; │вести сообщение,если непод-
    jc    Output          ; ┘ходящая

    call  PresentTest     ; проверить наличие в памяти

    mov   BL,DS:[5Dh]     ; ┐
    and   BL,11011111b    ; │
    cmp   BL,'I'          ; │разобрать ключ (заносится
    je    Install         ; │в область FCB1 PSP)
    cmp   BL,'U'          ; │
    je    Uninst          ; ┘

    call  @InfoAbout      ; вывести информацию
    jmp   short ToDos     ; и вернуться в DOS
                          ; если ключ не тот
Install:
    lea   DX,AlreadyMsg
    cmp   InstFlag,On     ; ┐если уже установлена,то
    je    Output          ; ┘перейти на вывод сообщения

    xor   AX,AX           ; ┐иначе получить начало
    mov   ES,AX           ; │видеообласти : если в байте по
    mov   AL,ES:[411h]    ; │адресу 0000h:0411h установлен
    and   AL,30h          ; │3-й бит,то сегментный адрес на-
    cmp   AL,30h          ; │чала видеообласти 0B000h иначе
    jne   Vid1            ; │сегментный адрес равен 0B800h
    mov   VideoBeg,0B000h ; ┘

Vid1:
    call  GrabIntVec      ; захватить нужные вектора

    mov   AX,DS:[2Ch]     ; ┐освободить окружение,выделен-
    mov   ES,AX           ; │ное программе для уменьшения
    mov   AH,49h          ; │занимаемой в резиденте памяти
    int   21h             ; ┘

    mov   AH,09h          ; ┐вывести сообщение об установке
    lea   DX,InstMsg      ; │в резидент
    int   21h             ; ┘

    lea   DX,ResEnd       ; ┐завершить и оставить програм-
    int   27h             ; ┘му в резиденте

Uninst:
    lea   DX,NotInstMsg   ; ┐если программа не установлена,
    cmp   InstFlag,Off    ; │то вывести сообщение об этом
    je    Output          ; ┘

    lea   DX,NotSafeMsg   ; ┐если программу невозможно
    call  TestIntVec      ; │снять с резидента,то вывести
    jc    Output          ; ┘сообщение об этом

    call  FreeIntVec      ; освободить вектора прерываний

    mov   AH,49h          ; ┐освободить память,занимаемую
    mov   ES,SaveCS       ; │резидентной частью программы
    int   21h             ; ┘

    lea   DX,UninstMsg

Output:
    mov   AH,09h          ; ┐вывести нужное сообщение
    int   21h             ; ┘

ToDos:
    mov   AX,4C00h        ; ┐вернуться в DOS с кодом
    int   21h             ; ┘завершения 0
    ret                   ; возврат
InitProc endp

;ПРОЦЕДУРА ПРОВЕРКИ ВЕРСИИ DOS
;возвращает установленный флаг переноса,если
;версия DOS меньше заданной в MinDosVer
ChkDosVer proc
    mov   AH,30h         ; ┐получить в AX номер версии
    int   21h            ; ┘DOS
    cmp   AL,MinDosVer   ; сравнить ее с минимальной

    clc                  ; сбросить флаг переноса (CF)
    jge   Norma          ; если версия подходящая
    stc                  ; иначе установить флаг переноса

Norma:
    ret                  ; возврат
ChkDosVer endp

;ПРОЦЕДУРА ОПРЕДЕЛЕНИЯ НАЛИЧИЯ ПРОГРАММЫ В ПАМЯТИ
PresentTest proc
    mov   InstFlag,Off   ; сбросить флаг наличия в резиденте
    mov   AH,FuncNum     ; ┐обратиться к нашему процессу
    int   16h            ; ┘
    cmp   AX,CodeOut     ; получили ответ?
    jne   Return         ; если нет,то конец
    mov   InstFlag,On    ; иначе установить флаг наличия
Return:
    ret                  ; возврат
PresentTest endp

;ПРОЦЕДУРА ЗАХВАТА ВЕКТОРОВ ПРЕРЫВАНИЙ
GrabIntVec proc
    mov   AX,3509h       ; ┐сохранить во внутренних пере-
    int   21h            ; │менных старый вектор прерыва-
    mov   OfsInt09,BX    ; │ния Int09h
    mov   SegInt09,ES    ; ┘

    mov   AX,3516h       ; ┐сохранить во внутренних пере-
    int   21h            ; │менных старый вектор прерыва-
    mov   OfsInt16,BX    ; │ния Int16h
    mov   SegInt16,ES    ; ┘

    mov   AX,2509h       ; ┐установить Int09Hand в качестве
    lea   DX,Int09Hand   ; │нового обработчика прерывания
    int   21h            ; ┘Int09

    mov   AX,2516h       ; ┐установить Presense в качестве
    lea   DX,Presense    ; │нового обработчика прерывания
    int   21h            ; ┘Int16h
    ret
GrabIntVec endp

;ПРОЦЕДУРА ПРОВЕРКИ ПЕРЕХВАТА ВЕКТОРОВ ПРЕРЫВАНИЙ
;возвращает установленный флаг переноса в случае перехвата
;хотя бы одного вектора прерывания
TestIntVec proc
    mov   AX,3509h            ; ┐проверить,находится ли ко-
    int   21h                 ; │довое слово перед обработ-
    cmp   ES:[BX-2],TestInt09 ; ┘чиком прерывания Int09
    stc                       ; установить флаг переноса CF,
    jne   Cant                ; если прерывание перехватили

    mov   AX,3516h            ; ┐проверить,находится ли ко-
    int   21h                 ; │довое слово поред обработ-
    cmp   ES:[BX-2],TestInt16 ; ┘чиком прерывания Int16h
    stc                       ; установить флаг переноса CF,
    jne   Cant                ; если прерывание перехватили

    mov   SaveCS,ES           ; запомнить CS резидентной
    clc                       ; программы,сбросить флаг
                              ; переноса
Cant:
    ret                       ; возврат
TestIntVec endp

;ПРОЦЕДУРА ВОССТАНОВЛЕНИЯ ЗАХВАЧЕННЫХ ВЕКТОРОВ ПРЕРЫВАНИЙ
FreeIntVec proc
    push  DS             ; сохранить DS

    mov   AX,2509h       ; ┐восстановить вектор прерывания
    mov   DS,ES:SegInt09 ; │Int09h из внутренних переменных
    mov   DX,ES:OfsInt09 ; │резидентной программы
    int   21h            ; ┘

    mov   AX,2516h       ; ┐восстановить вектор прерывания
    mov   DS,ES:SegInt16 ; │Int16h из внутренних переменных
    mov   DX,ES:OfsInt16 ; │резидентной программы
    int   21h            ; ┘

    pop   DS             ; восстановить DS
    ret                  ; возврат
FreeIntVec endp

PROGRAM   ends
      end   Start