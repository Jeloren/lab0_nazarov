;▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
;▓▓                                                      ▓▓
;▓▓         ┌─────────────────────────────────┐          ▓▓
;▓▓         │ П Р О Г Р А М М А   L O C K E R │          ▓▓
;▓▓         │      (MODIFIED: YARIK )       │          ▓▓
;▓▓         └─────────────────────────────────┘          ▓▓
;▓▓                                                      ▓▓
;▓▓ Это резидентная программа COM типа, "запирающая" на  ▓▓
;▓▓ время  клавиатуру.                                   ▓▓
;▓▓                                                      ▓▓
;▓▓ [ИЗМЕНЕНИЯ]:                                         ▓▓
;▓▓ 1. Блокировка: <Ctrl> + <LeftShift> + <B>            ▓▓
;▓▓ 2. Разблокировка: Ввод пароля "YARIK"                ▓▓
;▓▓ 3. Исправлен баг с появлением последнего символа     ▓▓
;▓▓    пароля в командной строке (WaitRelease).          ▓▓
;▓▓                                                      ▓▓
;▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

PROGRAM   segment
          assume CS:PROGRAM
          org   100h         ;пропуск PSP для COM-программы

Start:    jmp   InitProc     ;переход на инициализацию


;░░░░░░░░░ Р Е З И Д Е Н Т Н Ы Е   Д А Н Н Ы Е ░░░░░░░░░░░░

FuncNum   equ   0EEh           ;несуществующая функция пре-
                               ;рывания BIOS Int16h
CodeOut   equ   2D0Ch          ;код,возвращаемый нашим об-
                               ;работчиком Int16h
TestInt09 equ   9D0Ah          ;слово перед Int09h
TestInt16 equ   3AFAh          ;слово перед Int16h

OldInt09  label dword          ;сохраненный вектор Int09h:
 OfsInt09 dw    ?              ;   его смещение
 SegInt09 dw    ?              ;   и сегмент

OldInt16  label dword          ;сохраненный вектор Int16h:
 OfsInt16 dw    ?              ;   его смещение
 SegInt16 dw    ?              ;   и сегмент

OK_Text   db    0              ;признак гашения экрана
VideoLen  equ   800h           ;длина видеобуфера

; Данные для проверки пароля
; Пароль: Y A R I K
; Скан-коды (Set 1): 15h(Y), 1Eh(A), 13h(R), 17h(I), 25h(K)
PwdSeq    db  15h,1Eh,13h,17h,25h  
PwdLen    equ 5                  ; Длина пароля
KeyPos    db  0                  ; Текущая позиция ввода пароля

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

AttrBuf   db    VideoLen dup(07h)  ;атрибуты экрана
VideoBeg  dw    0B800h         ;адрес начала видеообласти
VideoOffs dw    ?              ;смещение активной страницы
CurSize   dw    ?              ;сохраненный размер курсора


;░░░░░░ Р Е З И Д Е Н Т Н Ы Е   П Р О Ц Е Д У Р Ы ░░░░░░░░░

;ПОДПРОГРАММА ОБМЕНА ВИДЕООБЛАСТИ С БУФЕРОМ ПРОГРАММЫ

VideoXcg proc
    lea   DI,VideoBuf   ;в DI - адрес буфера символов
    lea   SI,AttrBuf    ;в SI - адрес буфера атрибутов

    mov   AX,VideoBeg   ;┐в ES - сегментный адрес
    mov   ES,AX         ;┘начала видеообласти

    mov   CX,VideoLen   ;в CX - длина видеобуфера
    mov   BX,VideoOffs  ;в BX - нач. смещение строки

  Draw:
    mov   AX,ES:[BX]    ;┐обменять символ/атрибут на
    xchg  AH,DS:[SI]    ;│экране с символом и атрибу-
    xchg  AL,DS:[DI]    ;│том из буферов
    mov   ES:[BX],AX    ;┘

    inc   SI            ;┐увеличить адрес
    inc   DI            ;┘в буферах

    inc   BX            ;┐увеличить адрес
    inc   BX            ;┘в видеобуфере

    loop  Draw          ;сделать для всей видеообласти
    ret                 ;возврат
VideoXcg endp

;ОБРАБОТЧИК ПРЕРЫВАНИЯ Int09h (ПРЕРЫВАНИЕ ОТ КЛАВИАТУРЫ)

    dw    TestInt09     ;слово для обнаружения перехвата

Int09Hand proc
    push  AX            ;┐
    push  BX            ;│
    push  CX            ;│сохранить
    push  DI            ;│используемые
    push  SI            ;│регистры
    push  DS            ;│
    push  ES            ;┘

    push  CS            ;┐указать DS на
    pop   DS            ;┘нашу программу

    in    AL,60h        ;получить скан код нажатой клавиши

    ; Проверка комбинации блокировки
    ; Скан-код 30h соответствует клавише <B>
    cmp   AL,30h        ;┐проверить на скан-код клавиши
    je    CheckFlags    ;┘<B> и перейти на проверку флагов
    jmp   Exit09        ;иначе выход "по цепочке"

CheckFlags:
    xor   AX,AX         ;┐
    mov   ES,AX         ;│проверить флаги клавиатуры
    mov   AL,ES:[417h]  ;│по адресу 0000h:0417h
    
    ; [ИЗМЕНЕНО] Маска 00000110b (06h):
    ; Бит 2 = 1 (Ctrl нажат)
    ; Бит 1 = 1 (LeftShift нажат)
    and   AL, 00000110b ;│выделяем биты Ctrl и LeftShift
    cmp   AL, 00000110b ;│
    je    Cont          ;┘если совпало - БЛОКИРУЕМ
    
    jmp   Exit09        ;иначе выход

  Cont:
    sti                 ;разрешить прерывания

    mov   AH,0Fh        ;┐получить текущий
    int   10h           ;┘видеорежим
    cmp   AL,2          ;┐
    je    InText        ;│перейти на InText
    cmp   AL,3          ;│если режим
    je    InText        ;│текстовый 80#25
    cmp   AL,7          ;│
    je    InText        ;┘

    jmp   short SwLoop1 ;иначе - пропустить (не сохранять экран)

  InText:
    xor   AX,AX         ;┐установить сегментный
    mov   ES,AX         ;┘адрес в 0000h

    mov   AX,ES:[44Eh]  ;┐получить смещение активной
    mov   VideoOffs,AX  ;┘страницы в VideoOffs

    mov   AX,ES:[44Ch]  ;┐сравнить длину видеобуфера
    cmp   AX,1000h      ;│с 1000h.Если не равно,
    je    SaveCursor    ;│то сохраняем курсор
    jmp   Exit009       ;┘иначе выход (EGA Lines и т.д.)

  SaveCursor:
    mov   AH,03h        ;┐сохранить
    int   10h           ;│размер курсора
    mov   CurSize,CX    ;┘в CurSize

    mov   AH,01h        ;┐
    mov   CH,20h        ;│и подавить его (скрыть)
    int   10h           ;┘

    mov   OK_Text,01h   ;установить признак гашения экрана
    call  VideoXcg      ;и вызвать процедуру гашения (вывод заставки)

; --- [НОВОЕ] ЦИКЛ ОЖИДАНИЯ ПАРОЛЯ "YARIK" ---
  SwLoop1:
  KbdWait:                
    in    AL,64h        ;читать статус контроллера
    test  AL,01h        ;есть данные в буфере?
    jz    KbdWait       ;если нет, ждем

    in    AL,60h        ;читать скан-код

    cmp   AL,0E0h       ;игнорировать префиксы расширенных
    je    SwLoop1       ;клавиш
    cmp   AL,0E1h       
    je    SwLoop1
    test  AL,80h        ;проверить бит отпускания (7-й бит)
    jnz   SwLoop1       ;если клавиша отпущена - игнорировать

    ; Проверка последовательности пароля
    xor   BH,BH
    mov   BL,KeyPos     ;загрузить текущий индекс символа
    cmp   AL, PwdSeq[BX];сравнить скан-код с эталоном
    jne   PwdNotMatch   ;если не совпало - сброс

    inc   BL            ;перейти к следующему символу
    mov   KeyPos,BL     ;сохранить позицию
    cmp   BL,PwdLen     ;проверить, введен ли весь пароль?
    jne   SwLoop1       ;если нет - ждем следующую клавишу

    ; =================================================
    ; ПАРОЛЬ ВЕРЕН. ЖДЕМ ОТПУСКАНИЯ КЛАВИШИ
    ; =================================================
    ; Если не ждать отпускания, код последней клавиши 'K'
    ; (код break) попадет в буфер BIOS/DOS после выхода,
    ; и в командной строке напечатается 'k'.
    ; =================================================
  WaitRelease:
    in    AL, 64h       ; Читаем статус
    test  AL, 01h       ; Есть данные?
    jz    WaitRelease   ; Ждем данные

    in    AL, 60h       ; Читаем данные
    test  AL, 80h       ; Это код отпускания (Break code, бит 7 = 1)?
    jz    WaitRelease   ; Если 0 (нажатие), значит идет автоповтор -> ждем дальше
                        ; Если 1 (отпускание), выходим из цикла и разблокируем

    ; --- РАЗБЛОКИРОВКА ---
    mov   KeyPos,0      ;сбросить позицию ввода
    cmp   OK_Text,01h   ;если экран не был выключен
    jne   UnlockDone    ;то пропустить восстановление

    call  VideoXcg      ;восстановить экран из буфера

    mov   AH,01h        ;┐
    mov   CX,CurSize    ;│восстановить курсор
    int   10h           ;┘

    mov   OK_Text,0     ;сбросить признак гашения

  UnlockDone:
    jmp   Exit009       ;на выход с очисткой флагов

  PwdNotMatch:
    cmp   AL, PwdSeq    ;если нажата первая буква 'Y' после ошибки
    jne   ResetPwdTo0   
    mov   KeyPos,1      ;начать ввод заново с 1-й позиции
    jmp   SwLoop1

  ResetPwdTo0:
    mov   KeyPos,0      ;сброс ввода в начало
    jmp   SwLoop1

  Exit009:
    xor   AX,AX         ;┐
    mov   ES,AX         ;│очистить флаги нажатия
    mov   AL,ES:[417h]  ;│Shift/Ctrl, чтобы система не думала,
    and   AL,11111001b  ;│что они все еще зажаты
    mov   ES:[417h], AL ;┘

    mov   AL,20h        ;┐обслужить контроллер
    out   20h,AL        ;┘прерываний

    cli                 ;запретить прерывания
    pop   ES            ;┐
    pop   DS            ;│
    pop   SI            ;│восстановить
    pop   DI            ;│используемые
    pop   CX            ;│регистры
    pop   BX            ;│
    pop   AX            ;┘
    iret                ;выйти из прерывания

  Exit09:
    cli                 ;запретить прерывания
    pop   ES            ;┐
    pop   DS            ;│
    pop   SI            ;│восстановить
    pop   DI            ;│используемые
    pop   CX            ;│регистры
    pop   BX            ;│
    pop   AX            ;┘
    jmp   CS:OldInt09   ;┐;передать управление "по цепочке"
                        ;┘;следующему обработчику Int09h
Int09Hand endp

;ОБРАБОТЧИК ПРЕРЫВАНИЯ Int16h (ВИДЕО ФУНКЦИИ BIOS)

    dw    TestInt16     ;слово для обнаружения перехвата
Presense proc
    cmp   AH,FuncNum    ;обращение от нашей программы?
    jne   Pass          ;если нет то ничего не делать
    mov   AX,CodeOut    ;иначе в AX условленный код
    iret                ;и возвратиться

  Pass:
    jmp   CS:OldInt16   ;передать управление "по цепочке"
                        ;следующему обработчику Int16h
Presense endp


;░░░░░░░░ Н Е Р Е З И Д Е Н Т Н Ы Е   Д А Н Н Ы Е ░░░░░░░░░

ResEnd      db    ?    ;байт для определения границы ре-
                       ;зидентной части программы
On          equ   1    ;значение "установлен" для  флагов
Off         equ   0    ;значение "сброшен" для флагов
Bell        equ   7    ;код символа BELL
CR          equ   13   ;код символа CR
LF          equ   10   ;код символа LF
MinDosVer   equ   2    ;минимальная возможная версия DOS

InstFlag    db    ?    ;флаг наличия программы в памяти
SaveCS      dw    ?    ;сохраненный CS резидентной прог-
                       ;раммы

Copyright   db CR,LF,' LOCKER YARIK  ',CR,LF,LF,'$'
VerDosMsg   db 'Wrong DOS ver',Bell,CR,LF,'$'
InstMsg     db 'Installed! Ctrl+LeftShift+B to Lock',CR,LF,'$'
AlreadyMsg  db 'Already Installed',Bell,CR,LF,'$'
UninstMsg   db 'Uninstalled',CR,LF,'$'
NotInstMsg  db 'Not Installed',Bell,CR,LF,'$'
NotSafeMsg  db 'Cannot Uninstall safely',Bell,CR,LF,'$'

;░░░░░░ Н Е Р Е З И Д Е Н Т Н Ы Е   П Р О Ц Е Д У Р Ы ░░░░░

Locker      equ   0      ;имя для идентификации пpогpаммы
                         ;во включаемом файле
include     INFO.INC     ;включаемый файл с процедурой вы-
                         ;вода информации

;ГЛАВНАЯ ПРОЦЕДУРА ИНИЦИАЛИЗАЦИИ

InitProc proc
    mov   AH,09h          ;┐
    lea   DX,Copyright    ;│вывести начальное сообщение
    int   21h             ;┘

    lea   DX,VerDosMsg    ;┐проверить версию DOS и вы-
    call  ChkDosVer       ;│вести сообщение,если непод-
    jc    Output          ;┘ходящая

    call  PresentTest     ;проверить наличие в памяти

    mov   BL,DS:[5Dh]     ;┐
    and   BL,11011111b    ;│
    cmp   BL,'I'          ;│разобрать ключ (заносится
    je    Install         ;│в область FCB1 PSP)
    cmp   BL,'U'          ;│
    je    Uninst          ;┘

    jmp   Install         ;По умолчанию - установка

  Install:
    lea   DX,AlreadyMsg
    cmp   InstFlag,On     ;┐если уже установлена,то
    je    Output          ;┘перейти на вывод сообщения

    xor   AX,AX           ;┐иначе получить начало
    mov   ES,AX           ;│видеообласти : если в байте по
    mov   AL,ES:[411h]    ;│адресу 0000h:0411h установлен
    and   AL,30h          ;│3-й бит,то сегментный адрес на-
    cmp   AL,30h          ;│чала видеообласти 0B000h иначе
    jne   Vid1            ;│сегментный адрес равен 0B800h
    mov   VideoBeg,0B000h ;┘

  Vid1:
    call  GrabIntVec      ;захватить нужные вектора

    mov   AX,DS:[2Ch]     ;┐освободить окружение,выделен-
    mov   ES,AX           ;│ное программе для уменьшения
    mov   AH,49h          ;│занимаемой в резиденте памяти
    int   21h             ;┘

    mov   AH,09h          ;┐вывести сообщение об установке
    lea   DX,InstMsg      ;│в резидент
    int   21h             ;┘

    lea   DX,ResEnd       ;┐завершить и оставить програм-
    int   27h             ;┘му в резиденте

  Uninst:
    lea   DX,NotInstMsg   ;┐если программа не установлена,
    cmp   InstFlag,Off    ;│то вывести сообщение об этом
    je    Output          ;┘

    lea   DX,NotSafeMsg   ;┐если программу невозможно
    call  TestIntVec      ;│снять с резидента,то вывести
    jc    Output          ;┘сообщение об этом

    call  FreeIntVec      ;освободить вектора прерываний

    mov   AH,49h          ;┐освободить память,занимаемую
    mov   ES,SaveCS       ;│резидентной частью программы
    int   21h             ;┘

    lea   DX,UninstMsg

  Output:
    mov   AH,09h          ;┐вывести нужное сообщение
    int   21h             ;┘

  ToDos:
    mov   AX,4C00h        ;┐вернуться в DOS с кодом
    int   21h             ;┘завершения 0
    ret                   ;возврат
InitProc endp

;ПРОЦЕДУРА ПРОВЕРКИ ВЕРСИИ DOS
;возвращает установленный флаг переноса,если
;версия DOS меньше заданной в MinDosVer

ChkDosVer proc
    mov   AH,30h         ;┐получить в AX номер версии
    int   21h            ;┘DOS
    cmp   AL,MinDosVer   ;сравнить ее с минимальной
    clc                  ;сбросить флаг переноса (CF)
    jge   Norma          ;если версия подходящая
    stc                  ;иначе установить флаг переноса
  Norma:
    ret                  ;возврат
ChkDosVer endp

;ПРОЦЕДУРА ОПРЕДЕЛЕНИЯ НАЛИЧИЯ ПРОГРАММЫ В ПАМЯТИ

PresentTest proc
    mov   InstFlag,Off   ;сбросить флаг наличия в резиденте
    mov   AH,FuncNum     ;┐обратиться к нашему процессу
    int   16h            ;┘
    cmp   AX,CodeOut     ;получили ответ?
    jne   Return         ;если нет,то конец
    mov   InstFlag,On    ;иначе установить флаг наличия
  Return:
    ret                  ;возврат
PresentTest endp

;ПРОЦЕДУРА ЗАХВАТА ВЕКТОРОВ ПРЕРЫВАНИЙ

GrabIntVec proc
    mov   AX,3509h       ;┐сохранить во внутренних пере-
    int   21h            ;│менных старый вектор прерыва-
    mov   OfsInt09,BX    ;│ния Int09h
    mov   SegInt09,ES    ;┘

    mov   AX,3516h       ;┐сохранить во внутренних пере-
    int   21h            ;│менных старый вектор прерыва-
    mov   OfsInt16,BX    ;│ния Int16h
    mov   SegInt16,ES    ;┘

    mov   AX,2509h       ;┐установить Int09Hand в качестве
    lea   DX,Int09Hand   ;│нового обработчика прерывания
    int   21h            ;┘Int09

    mov   AX,2516h       ;┐установить Presense в качестве
    lea   DX,Presense    ;│нового обработчика прерывания
    int   21h            ;┘Int16h
    ret
GrabIntVec endp

;ПРОЦЕДУРА ПРОВЕРКИ ПЕРЕХВАТА ВЕКТОРОВ ПРЕРЫВАНИЙ
;возвращает установленный флаг переноса в случае перехвата
;хотя бы одного вектора прерывания

TestIntVec proc
    mov   AX,3509h            ;┐проверить,находится ли ко-
    int   21h                 ;│довое слово перед обработ-
    cmp   ES:[BX-2],TestInt09 ;┘чиком прерывания Int09
    stc                       ;установить флаг переноса CF,
    jne   Cant                ;если прерывание перехватили

    mov   AX,3516h            ;┐проверить,находится ли ко-
    int   21h                 ;│довое слово поред обработ-
    cmp   ES:[BX-2],TestInt16 ;┘чиком прерывания Int16h
    stc                       ;установить флаг переноса CF,
    jne   Cant                ;если прерывание перехватили

    mov   SaveCS,ES           ;запомнить CS резидентной
    clc                       ;программы,сбросить флаг
                              ;переноса
  Cant:
    ret                       ;возврат
TestIntVec endp

;ПРОЦЕДУРА ВОССТАНОВЛЕНИЯ ЗАХВАЧЕННЫХ ВЕКТОРОВ ПРЕРЫВАНИЙ

FreeIntVec proc
    push  DS             ;сохранить DS

    mov   AX,2509h       ;┐восстановить вектор прерывания
    mov   DS,ES:SegInt09 ;│Int09h из внутренних переменных
    mov   DX,ES:OfsInt09 ;│резидентной программы
    int   21h            ;┘

    mov   AX,2516h       ;┐восстановить вектор прерывания
    mov   DS,ES:SegInt16 ;│Int16h из внутренних переменных
    mov   DX,ES:OfsInt16 ;│резидентной программы
    int   21h            ;┘

    pop   DS             ;восстановить DS
    ret                  ;возврат
FreeIntVec endp

PROGRAM   ends
      end   Start