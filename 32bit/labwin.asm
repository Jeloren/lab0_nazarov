includelib import32.lib ;Подключение библиотеки описния
 ;системных функций
.386 ;включение 32-битного режима
.model flat ;модель памяти FLAT
 extrn MessageBoxA:proc ;Внешние процедуры
 extrn ExitProcess:proc
.data
mb_text db 'Hello, World!',0 ;Текстовые константы
mb_title db 'My first program',0 ;для выполнения
;программы
.code
start: 
    push 0 ;Формирование
    push offset mb_title ;параметров
    push offset mb_text ;в стеке для;MessageBox -
    push 0 ;прямая передача
    call MessageBoxA ;Вызов MessageBox
    push 0 ;параметр для ExitProcess
    call ExitProcess ;завершение программы
    ends
end start