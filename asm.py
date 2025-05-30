def ins_blanks(s, k):
    if not s:
        return s if k <= 0 else ' ' * k
    
    # Нормализация строки (удаление лишних пробелов)
    normalized = []
    in_word = False
    for char in s:
        if char == ' ':
            if in_word:
                normalized.append(' ')
                in_word = False
        else:
            normalized.append(char)
            in_word = True
    
    # Удаляем последний пробел если есть
    if normalized and normalized[-1] == ' ':
        normalized.pop()
    normalized = ''.join(normalized)
    
    n = len(normalized)
    if n >= k:
        return normalized
    
    # Подсчет слов
    words = normalized.split() if normalized else []
    word_count = len(words)
    
    if word_count == 0:
        return ' ' * k
    if word_count == 1:
        return words[0] + (' ' * (k - len(words[0])))
    
    # Вычисление дополнительных пробелов
    total_spaces = k - n
    gaps = word_count - 1
    base_spaces = total_spaces // gaps
    extra_spaces = total_spaces % gaps
    
    # Построение результата
    result = []
    for i, word in enumerate(words):
        result.append(word)
        if i < gaps:
            # Базовые пробелы + дополнительный если нужно
            spaces = base_spaces + 1 if i < extra_spaces else base_spaces
            result.append(' ' * spaces)
    
    return ''.join(result)

# Тестирование как в оригинальной программе
def main():
    test_cases = [
        ("Hello man cycle", 26),  # Исходный тест
        ("", 10),                # Пустая строка
        ("Single", 10),          # Одно слово
        ("   ", 5),              # Только пробелы
        ("a  b   c", 15),        # С лишними пробелами
    ]
    
    for s, k in test_cases:
        print(f"Ввод: '{s}', k={k}")
        result = ins_blanks(s, k)
        print(f"Результат: '{result}' (длина={len(result)})\n")

if __name__ == "__main__":
    main()