@ECHO OFF

:: --- УСТАНОВКА UTF-8 ДЛЯ КИРИЛЛИЦЫ ---
CHCP 65001

ECHO.
ECHO --- 1. Ассемблирование lab_8.asm ---
tasm32 /ml /l lab_8.asm > tasm_log.txt 2>&1

ECHO --- ОТЧЕТ TASM32: ---
TYPE tasm_log.txt
pause 
IF ERRORLEVEL 1 GOTO END_ERROR

ECHO.
ECHO --- 2. Компоновка lab_8.obj -> lab_8.exe ---
tlink32 lab_8.obj /Tpe /aa /c > tlink_log.txt 2>&1

ECHO --- ОТЧЕТ TLINK32: ---
TYPE tlink_log.txt
pause
IF ERRORLEVEL 1 GOTO END_ERROR

ECHO.
ECHO Сборка завершена. Файл lab_8.exe готов.
pause

ECHO --- 3. Подготовка тестовых файлов и папок: НАЧАЛО ---

:: Очистка старых файлов перед тестом
IF EXIST "D:\TempTest\Source\test.txt" (
    DEL "D:\TempTest\Source\test.txt"
    ECHO Удален старый test.txt.
)

IF EXIST "D:\TempTest\Target\moved_file.txt" (
    DEL "D:\TempTest\Target\moved_file.txt"
    ECHO Удален старый moved_file.txt.
)

:: Создание папки Source
IF NOT EXIST "D:\TempTest\Source" (
    mkdir "D:\TempTest\Source"
    ECHO Создана папка Source.
) ELSE (
    ECHO Папка Source уже существует.
)

:: Создание папки Target
IF NOT EXIST "D:\TempTest\Target" (
    mkdir "D:\TempTest\Target"
    ECHO Создана папка Target.
) ELSE (
    ECHO Папка Target уже существует.
)

:: Создание файла test.txt
ECHO This is a test file for lab 8. > "D:\TempTest\Source\test.txt"

IF EXIST "D:\TempTest\Source\test.txt" (
    ECHO Файл test.txt создан успешно.
) ELSE (
    ECHO !!! КРИТИЧЕСКАЯ ОШИБКА !!! Не удалось создать файл test.txt.
    GOTO CLEANUP
)

ECHO.
ECHO --- Проверка существования файлов перед тестом ---
IF EXIST "D:\TempTest\Source\test.txt" (
    ECHO Исходный файл существует
) ELSE (
    ECHO Исходный файл НЕ существует!
)

IF EXIST "D:\TempTest\Target" (
    ECHO Целевая папка существует
) ELSE (
    ECHO Целевая папка НЕ существует!
)

ECHO.
ECHO Содержимое папок перед тестом:
ECHO Source:
DIR "D:\TempTest\Source" /B
ECHO Target:
DIR "D:\TempTest\Target" /B
PAUSE

ECHO.
ECHO --- 4. Запуск программы (Тест №1: Успешное перемещение) ---
ECHO Вызов: lab_8.exe "D:\TempTest\Source\test.txt" "D:\TempTest\Target\moved_file.txt"
PAUSE

lab_8.exe "D:\TempTest\Source\test.txt" "D:\TempTest\Target\moved_file.txt"

IF ERRORLEVEL 1 (
    ECHO.
    ECHO !!! ОШИБКА !!! lab_8.exe завершилась с кодом ошибки (ERRORLEVEL 1). Файл не перемещен.
    ECHO.
    ECHO Содержимое папок ПОСЛЕ неудачного перемещения:
    ECHO Source:
    DIR "D:\TempTest\Source" /B
    ECHO Target:  
    DIR "D:\TempTest\Target" /B
    GOTO DEBUG_HELP
) ELSE (
    ECHO.
    ECHO Успешно! Файл перемещен. Проверка содержимого папок:
    ECHO.
    ECHO Source:
    DIR "D:\TempTest\Source" /B
    ECHO Target:
    DIR "D:\TempTest\Target" /B
)
PAUSE

ECHO.
ECHO --- 5. Тест №2: Простой тест в текущей папке ---
CD /D "D:\TempTest\Source"
ECHO Создан test2.txt для второго теста
ECHO Test file 2 > test2.txt
lab_8.exe test2.txt moved_file2.txt
IF ERRORLEVEL 1 (
    ECHO Ошибка в простом тесте
) ELSE (
    ECHO Простой тест прошел успешно
    ECHO Содержимое текущей папки:
    DIR /B
)
CD /D "%~dp0"
PAUSE

GOTO CLEANUP

:DEBUG_HELP
ECHO.
ECHO --- ДИАГНОСТИКА ОШИБКИ ---
ECHO Возможные причины:
ECHO 1. Файл уже существует в целевой папке
ECHO 2. Нет прав доступа
ECHO 3. Исходный файл не существует
ECHO 4. Проблема с парсингом аргументов
ECHO.
ECHO Проверка:
IF EXIST "D:\TempTest\Source\test.txt" (
    ECHO Исходный файл существует
) ELSE (
    ECHO Исходный файл НЕ существует!
)
IF EXIST "D:\TempTest\Target\moved_file.txt" (
    ECHO Целевой файл уже существует - ЭТО ПРОБЛЕМА!
) ELSE (
    ECHO Целевой файл не существует
)
PAUSE

:END_ERROR
ECHO.
ECHO !!! КРИТИЧЕСКАЯ ОШИБКА !!! Проверьте отчеты tasm_log.txt или tlink_log.txt выше.
ECHO.

:CLEANUP
ECHO.
CHCP 866 
ECHO --- Завершение скрипта ---
PAUSE