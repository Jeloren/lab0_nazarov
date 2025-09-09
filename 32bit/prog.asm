.386
.model flat, stdcall
public InsBlanks

.code
InsBlanks proc
    push ebp
    mov ebp, esp
    pushad

    ; Загрузка параметров:
    ; [ebp+8]  = input_string
    ; [ebp+12] = k
    ; [ebp+16] = result_buffer
    ; [ebp+20] = words_buffer
    ; [ebp+24] = temp_buffer

    ; 1. Разбиваем строку на слова
    mov esi, [ebp+8]   ; ESI = input_string
    mov edi, [ebp+20]  ; EDI = words_buffer
    xor ecx, ecx       ; ECX = счётчик слов

skip_spaces:
    lodsb              ; Читаем символ
    cmp al, 0          ; Конец строки?
    je split_end
    cmp al, ' '        ; Пропускаем пробелы
    je skip_spaces

    ; Начало слова
    dec esi            ; Возвращаемся к первому символу
    mov [edi], esi     ; Сохраняем указатель
    add edi, 4         ; Следующий элемент массива (4 байта)
    inc ecx            ; Увеличиваем счётчик слов

read_word:
    lodsb              ; Читаем символ
    cmp al, 0          ; Конец строки?
    je word_end
    cmp al, ' '        ; Конец слова?
    jne read_word
    mov byte ptr [esi-1], 0 ; Заменяем пробел на 0
    jmp skip_spaces

word_end:
    dec esi            ; Корректируем указатель
split_end:
    push ecx           ; Сохраняем количество слов

    ; 2. Собираем нормализованную строку
    mov edi, [ebp+24]  ; EDI = temp_buffer
    pop ecx            ; Восстанавливаем ECX (количество слов)
    jcxz empty_temp    ; Если слов нет

    ; Копируем первое слово
    mov esi, [ebp+20]  ; ESI = words_buffer
    mov esi, [esi]     ; ESI = адрес первого слова
copy_first:
    mov al, [esi]
    test al, al        ; Конец слова?
    jz first_done
    mov [edi], al      ; Копируем символ
    inc edi
    inc esi
    jmp copy_first

first_done:
    push ecx           ; Сохраняем количество слов
    pop ecx            ; Восстанавливаем ECX
    dec ecx            ; Оставшиеся слова
    jz temp_done       ; Если только одно слово

    mov esi, [ebp+20]  ; ESI = words_buffer
    add esi, 4         ; Переходим ко второму слову (4 байта)
next_temp_word:
    mov al, ' '        ; Добавляем пробел
    mov [edi], al
    inc edi
    mov ebx, [esi]     ; EBX = адрес слова
    add esi, 4         ; Следующее слово (4 байта)
copy_word_temp:
    mov al, [ebx]
    test al, al        ; Конец слова?
    jz word_done_temp
    mov [edi], al      ; Копируем символ
    inc edi
    inc ebx
    jmp copy_word_temp

word_done_temp:
    loop next_temp_word ; Повторяем для всех слов

temp_done:
    mov byte ptr [edi], 0 ; Завершаем строку
    jmp after_build

empty_temp:
    mov byte ptr [edi], 0 ; Пустая строка

after_build:
    ; 3. Вставляем пробелы для достижения длины k
    mov esi, [ebp+24]  ; ESI = temp_buffer
    mov edi, [ebp+16]  ; EDI = result_buffer
    mov ebx, [ebp+12]  ; EBX = k

    ; Проверка на пустую строку
    cmp byte ptr [esi], 0
    je copy_direct

    ; Подсчёт длины и количества слов
    xor ecx, ecx       ; Длина строки
    xor edx, edx       ; Количество слов
    mov ah, 0          ; Флаг внутри слова
count_loop:
    mov al, [esi]
    cmp al, 0          ; Конец строки?
    je end_count
    inc ecx            ; Увеличиваем длину
    cmp al, ' '        ; Пробел?
    je space_char

    ; Обработка буквы
    test ah, ah        ; Уже внутри слова?
    jnz not_new_word
    inc edx            ; Новое слово
    mov ah, 1          ; Устанавливаем флаг
not_new_word:
    jmp next_char

space_char:
    mov ah, 0          ; Сбрасываем флаг
next_char:
    inc esi
    jmp count_loop

end_count:
    mov esi, [ebp+24]  ; Восстанавливаем начало строки
    cmp ecx, ebx       ; Текущая длина >= k?
    jae copy_direct
    test edx, edx      ; Нет слов?
    jz copy_direct
    cmp edx, 1         ; Одно слово?
    je handle_single_word

    ; Вычисляем пробелы для добавления
    mov eax, ebx       ; EAX = k
    sub eax, ecx       ; EAX = всего пробелов
    mov ecx, edx       ; ECX = количество слов
    dec ecx            ; Промежутки = слов - 1
    xor edx, edx
    div ecx            ; EAX = p, EDX = q

    ; Вставляем пробелы
    xor ecx, ecx       ; Счётчик промежутков
    mov ebx, eax       ; EBX = p
copy_loop:
    mov al, [esi]      ; Читаем символ
    inc esi
    test al, al        ; Конец строки?
    jz end_ins
    cmp al, ' '        ; Пробел?
    jne copy_char

    ; Обработка пробела
    push ecx           ; Сохраняем счётчик
    mov ecx, 1         ; Базовый пробел
    add ecx, ebx       ; + p пробелов
    pop eax            ; EAX = текущий промежуток
    cmp eax, edx       ; Сравниваем с q
    jae no_extra
    inc ecx            ; Добавляем дополнительный пробел
no_extra:
    push eax           ; Сохраняем обратно
    mov al, ' '        ; Вставляем пробелы
insert_spaces:
    mov [edi], al
    inc edi
    loop insert_spaces
    pop ecx            ; Восстанавливаем счётчик
    inc ecx            ; Следующий промежуток
    jmp copy_loop

copy_char:
    mov [edi], al      ; Копируем символ
    inc edi
    jmp copy_loop

end_ins:
    mov byte ptr [edi], 0 ; Конец строки
    jmp done_ins

handle_single_word:
    ; Обработка одного слова
    mov esi, [ebp+24]  ; Начало строки
    xor ecx, ecx       ; Длина слова
count_single_len:
    cmp byte ptr [esi], 0
    je end_count_single
    inc ecx
    inc esi
    jmp count_single_len
end_count_single:
    mov esi, [ebp+24]  ; Восстанавливаем начало
copy_single_word:
    mov al, [esi]
    test al, al        ; Конец слова?
    jz add_tail_spaces
    mov [edi], al
    inc edi
    inc esi
    jmp copy_single_word

add_tail_spaces:
    mov eax, [ebp+12]  ; EAX = k
    sub eax, ecx       ; Пробелы для добавления
    mov ecx, eax
    jle done_tail      ; Если <=0, пропускаем
    mov al, ' '
    rep stosb          ; Заполняем пробелами
done_tail:
    mov byte ptr [edi], 0 ; Конец строки
    jmp done_ins

copy_direct:
    ; Простое копирование
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    test al, al
    jnz copy_direct

done_ins:
    popad              ; Восстанавливаем регистры
    pop ebp
    ret 20             ; Возврат с очисткой стека (5 аргументов * 4 байта)
InsBlanks endp

end