#!/bin/bash

list_users() {
    awk -F: '$3>=1000 { print $1 " " $6 }' /etc/passwd | sort
}

print_help() {
    echo "Using: \\\\$0 [options]"
    echo ""
    echo "Options"
    echo "  -u, --users            Выводит перечень пользователей и их домашних директорий."
    echo "  -p, --processes        Выводит перечень запущенных процессов."
    echo "  -h, --help             Выводит данную справку."
    echo "  -l PATH, --log PATH    Записывает вывод в файл по заданному пути."
    echo "  -e PATH, --errors PATH Записывает ошибки в файл ошибок по заданному пути."
}
log_PATH=""
error_PATH=""
action=""
list_processes() {
    ps -Ao pid,comm --sort=pid
}
ch_and_create_file() {
    local path="$1"
    if [[ ! -d "$(dirname "$path")" ]]; then
        echo "Ошибка: Директория '$path' не существует." >&2
        exit 1
    fi

    if [[ -f "$path" ]]; then
        echo "Предупреждение: Файл '$path' существует. Будет перезаписан." >&2
    fi
    touch "$path" 
    if [[ ! -w "$path" ]]; then
        echo "Ошибка: Нет прав на запись в '$path'" >&2
        exit 1
    fi
}

r_stdout() {
    local log_PATH="$1"
    ch_and_create_file "$log_PATH"
    exec > "$log_PATH"
}

r_stderr() {
    local error_PATH="$1"
    ch_and_create_file "$error_PATH"
    exec 2>"$error_PATH"
}
while getopts ":uphl:e:-:" opt; do
    case $opt in
        u)
            action="users"

            ;;
        p)
            action="processes"

            ;;
        h)
            action="help"

            exit 0
            ;;
        l)
            log_PATH="$OPTARG"
            r_stdout "$log_PATH"
            ;;
        e)
            error_PATH="$OPTARG"
            r_stderr "$error_PATH"
            ;;
        -)
            case "${OPTARG}" in
                users)
                    action="users"

                    ;;
                processes)
                    action="processes"

                    ;;
                help)
                    action="help"
                    exit 0
                    ;;
                log)
                    log_PATH="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                    r_stdout "$log_PATH"
                    ;;
                errors)
                    error_PATH="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                    r_stderr "$error_PATH"
                    ;;
                *)
                    echo "Invalid option: --${OPTARG}" >&2
                    exit 1
                    ;;
            esac
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done
if [ -n "$error_PATH" ]; then
    if [[ "$error_PATH" == *.* ]]; then  # Проверка на расширение .*
        touch "$error_PATH"  # Создаем файл, если он не существует
        echo "Ошибка, действие не задано" > "$error_PATH"
    else
        echo "Error: Invalid file extension for error path $error_PATH" >&2
        exit 1
    fi
else
    # Если error_PATH не указан, создаем файл по умолчанию
    default_error_file="error_log.txt"
    touch "$default_error_file"  # Создаем файл, если он не существует
    echo "Ошибка, действие не задано" > "$default_error_file"
fi
execute_action() {
    case $action in
        users) list_users ;;
        processes) list_processes ;;
        help) print_help ;;
        *)
            echo "No valid action specified." >&2
            exit 1
            ;;
    esac
}
if [ -n "$log_PATH" ]; then
    if [ -w "$log_PATH" ] || [ ! -e "$log_PATH" ]; then
        execute_action > "$log_PATH"
    else
        echo "Error: Cannot write to log path $log_PATH" >&2
        exit 1
    fi
else
    execute_action
    default_log_file="logi.log"
    {
        execute_action
    } > "$default_log_file"
fi
