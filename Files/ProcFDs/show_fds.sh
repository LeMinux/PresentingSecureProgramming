source="print_paths_of_standard_descriptors.c"
exec="print_fds.out"
redir_file="empty_file.txt"
output_file="fd_output.txt"
device="/dev/tty"
directory="TestDir"

printIfSuccess(){
    if [[ $? == 0 ]]; then
        cat "$output_file"
    else
        echo "Uh oh something went wrong"
    fi
}


main() {
    if  [[ ! -f "$exec"  ]]; then
        gcc -Wall -Werror -Wpedantic "$source" -o "$exec"
    fi

    if  [[ ! -f "$redir_file"  ]]; then
        touch "$redir_file"
    fi

    echo "$exec"
    ./"$exec"
    printIfSuccess

    echo ""

    echo "$exec > $redir_file"
    ./"$exec" > "$redir_file"
    printIfSuccess


    echo ""

    echo "$exec < $redir_file"
    ./"$exec" < "$redir_file"
    printIfSuccess

    echo ""

    echo "$exec 2> $redir_file"
    ./"$exec" 2> "$redir_file"
    printIfSuccess

    echo ""

    echo "cat $redir_file | $exec"
    cat "$redir_file" | ./"$exec"
    printIfSuccess

    echo ""

    echo "$exec > $device"
    ./"$exec" > "$device"
    printIfSuccess
}

main
