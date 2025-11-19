@ECHO OFF
CHCP 65001
CLS

:: --- 1. Ассемблирование ---
ECHO [1] Ассемблирование lab_8.asm...
tasm32 /ml /l lab_8.asm > tasm_log.txt 2>&1
IF ERRORLEVEL 1 (
    TYPE tasm_log.txt
    PAUSE
    GOTO :EOF
)

:: --- 2. Компоновка (ВАЖНО: /ap вместо /aa) ---
ECHO [2] Компоновка lab_8.obj -> lab_8.exe...
:: ИСПОЛЬЗУЕМ /ap (Console), ЧТОБЫ БАТНИК ЖДАЛ ЗАВЕРШЕНИЯ ПРОГРАММЫ
tlink32 lab_8.obj /Tpe /ap /c > tlink_log.txt 2>&1
IF ERRORLEVEL 1 (
    TYPE tlink_log.txt
    PAUSE
    GOTO :EOF
)

ECHO Сборка успешна.

:: --- 3. Подготовка файлов ---
ECHO [3] Подготовка тестовой среды (Disk C:)...

IF EXIST "C:\TempTest" ( RMDIR /S /Q "C:\TempTest" )
MKDIR "C:\TempTest\Source"
MKDIR "C:\TempTest\Target"

ECHO Test Content > "C:\TempTest\Source\test.txt"

IF NOT EXIST "C:\TempTest\Source\test.txt" (
    ECHO ОШИБКА: Не удалось создать тестовый файл!
    PAUSE
    GOTO :EOF
)

:: --- 4. Запуск теста ---
ECHO.
ECHO [4] Запуск lab_8.exe...
ECHO Аргументы: "C:\TempTest\Source\test.txt" "C:\TempTest\Target\moved_file.txt"
ECHO.
PAUSE

:: Запуск программы
lab_8.exe "C:\TempTest\Source\test.txt" "C:\TempTest\Target\moved_file.txt"

:: Сохраняем код возврата сразу!
SET ERR=%ERRORLEVEL%

ECHO.
ECHO Программа завершилась с кодом: %ERR%

IF "%ERR%"=="0" (
    ECHO [УСПЕХ] Файл перемещен.
    IF EXIST "C:\TempTest\Target\moved_file.txt" ( ECHO Проверка: Файл найден в Target. ) ELSE ( ECHO ОШИБКА: Код 0, но файла нет! )
) ELSE (
    ECHO [ОШИБКА] Код ошибки не равен 0.
    ECHO Возможные причины:
    ECHO  - Ошибка парсинга путей (кавычки/пробелы)
    ECHO  - Файл уже существует в Target
    ECHO  - Нет прав доступа
)

ECHO.
ECHO Содержимое папок:
ECHO Source:
DIR "C:\TempTest\Source" /B
ECHO Target:
DIR "C:\TempTest\Target" /B

ECHO.
PAUSE