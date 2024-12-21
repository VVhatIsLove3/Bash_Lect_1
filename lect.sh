#!/bin/bash

# Функция для вывода справки
display_help() {
    echo "Использование: \\\\$0 [опции]"
    echo ""
    echo "Опции"
    echo "  -u, --users            Показывает список пользователей и их домашние директории."
    echo "  -p, --processes        Показывает список активных процессов."
    echo "  -h, --help             Показывает эту справку."
    echo "  -l ПУТЬ, --log ПУТЬ    Записывает вывод в указанный файл."
    echo "  -e ПУТЬ, --errors ПУТЬ Записывает ошибки в указанный файл."
}

# Инициализация переменных для хранения путей
log_file=""
error_file=""
selected_action=""

# Функция для проверки существования директории и создания файла
check_and_create_file() {
    local path="\$1"
    if [[ ! -d "$(dirname "$path")" ]]; then
        echo "Ошибка: Директория '$path' не найдена." >&2
        exit 1
    fi

    if [[ -f "$path" ]]; then
        echo "Внимание: Файл '$path' уже существует. Он будет перезаписан." >&2
    fi
    touch "$path" # Создаем файл, если его нет.
    # Проверяем права на запись
    if [[ ! -w "$path" ]]; then
        echo "Ошибка: Нет прав на запись в '$path'" >&2
        exit 1
    fi
}

# Функция для отображения пользователей и их домашних директорий
show_users() {
    awk -F: '\$3>=1000 { print \$1 " " \$6 }' /etc/passwd | sort
}

# Функция для отображения активных процессов
show_processes() {
    ps -Ao pid,comm --sort=pid
}

# Функция для перенаправления стандартного вывода
redirect_stdout() {
    local log_file="\$1"
    check_and_create_file "$log_file"
    exec > "$log_file"
}

# Функция для перенаправления стандартного потока ошибок
redirect_stderr() {
    local error_file="\$1"
    check_and_create_file "$error_file"
    exec 2>"$error_file"
}

# Обработка аргументов командной строки
while getopts ":uphl:e:-:" opt; do
    case $opt in
        u)
            selected_action="users"
            ;;
        p)
            selected_action="processes"
            ;;
        h)
            selected_action="help"
            display_help
            exit 0
            ;;
        l)
            log_file="$OPTARG"
            redirect_stdout "$log_file"
            ;;
        e)
            error_file="$OPTARG"
            redirect_stderr "$error_file"
            ;;
        -)
            case "${OPTARG}" in
                users)
                    selected_action="users"
                    ;;
                processes)
                    selected_action="processes"
                    ;;
                help)
                    selected_action="help"
                    display_help
                    exit 0
                    ;;
                log)
                    log_file="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                    redirect_stdout "$log_file"
                    ;;
                errors)
                    error_file="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                    redirect_stderr "$error_file"
                    ;;
                *)
                    error_msg="Неизвестный флаг: --${OPTARG}"
                    if [ -n "$error_file" ]; then
                        echo "$error_msg" >> "$error_file"  # Запись ошибки в файл ошибок
                    else
                        echo "$error_msg" >&2  # Вывод ошибки в терминал
                    fi
                    exit 1
                    ;;
            esac
            ;;
        \?)
            error_msg="Неизвестный флаг: -$OPTARG"
            if [ -n "$error_file" ]; then
                echo "$error_msg" >> "$error_file"  # Запись ошибки в файл ошибок
            else
                echo "$error_msg" >&2  # Вывод ошибки в терминал
            fi
            exit 1
            ;;
        :)
            error_msg="Отсутствует аргумент для флага: -$OPTARG"
            if [ -n "$error_file" ]; then
                echo "$error_msg" >> "$error_file"  # Запись ошибки в файл ошибок
            else
                echo "$error_msg" >&2  # Вывод ошибки в терминал
            fi
            exit 1
            ;;
    esac
done

# Выполнение действия в зависимости от выбранного аргумента
perform_action() {
    case $selected_action in
        users) show_users ;;
        processes) show_processes ;;
        help) display_help ;;
        *)
            echo "Не указано корректное действие." >&2
            exit 1
            ;;
    esac
}

# Проверка на отсутствие действия (если ни один флаг не был указан)
if [[ -z "$selected_action" ]]; then
    error_msg="Ошибка: Не указано действие."
    if [ -n "$error_file" ]; then
        echo "$error_msg" >> "$error_file"  # Запись ошибки в файл ошибок
    else
        echo "$error_msg" >&2  # Вывод ошибки в терминал
    fi
    exit 1
fi

if [ -n "$log_file" ]; then
    if [ -w "$log_file" ] || [ ! -e "$log_file" ]; then
        perform_action > "$log_file"
    else
        echo "Ошибка: Невозможно записать в файл логов $log_file" >&2
        exit 1
    fi
fi

# Если не указаны флаги -l или -e, выводим результат в терминал
if [ -z "$log_file" ] && [ -z "$error_file" ]; then
    perform_action
fi

# Обработка случая, когда не указано действие (selected_action пуст)
if [ -z "$selected_action" ]; then
    error_msg="Ошибка: Не указано действие."
    if [ -n "$error_file" ]; then
        echo "$error_msg" >> "$error_file"  # Запись ошибки в файл ошибок
    else
        echo "$error_msg" >&2  # Вывод ошибки в терминал
    fi
    exit 1
fi
