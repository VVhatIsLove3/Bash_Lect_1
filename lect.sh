#!/bin/bash

function users() {
    file="/etc/passwd" 
    list=$(grep home $file)  
    touch file.txt
    for i in $list; do
        echo $i >> file.txt  
    done
    sort file.txt -o sort_file.txt  
    file2=sort_file.txt
    while read -r str; do  
        echo $str
    done < $file2
    rm file.txt sort_file.txt  
}

function processes() {
    ps -a
}

function help() {
    echo "-u | --users      Displays a list of users and their home directories"
    echo "-p | --processes  Displays a list of running processes"
    echo "-h | --help       Displays help with a list of arguments and stops execution"
    echo "-l PATH | --log PATH  Redirects standard output to the file at the given PATH"
    echo "-e PATH | --error PATH  Redirects error output (stderr) to the file at the given PATH"
    exit 0
}

function output() {
    if [ -f "$1" ] && [ -w "$1" ]; then
        exec 1>"$1"  
    else
        echo "The file does not exist or you do not have permission to write to it" >&2
    fi
}

function output_err() {
    if [ -f "$1" ] && [ -w "$1" ]; then
        exec 2>"$1"  
    else
        echo "The file does not exist or you do not have permission to write to it" >&2
    fi
}

count=2
for arg in "$@"; do
    if [ "$arg" == "-e" ] || [ "$arg" == "--errors" ]; then
        file_name=${!count}
        output_err "$file_name"
        break
    fi
    count=$((count + 1))
done

count=2
for arg in "$@"; do
    if [ "$arg" == "-l" ] || [ "$arg" == "--log" ]; then
        file_name=${!count}
        output "$file_name"
        break
    fi
    count=$((count + 1))
done

TEMP=$(getopt -o uphle --long users,processes,help,log:,errors: -- "$@")
eval set -- "$TEMP"

while [ -n "$1" ]; do
    case "$1" in
    -u | --users)
        users
        shift
        ;;
    -p | --processes)
        processes
        shift
        ;;
    -h | --help)
        help
        shift
        ;;
    --)
        shift
        ;;
    esac
done
