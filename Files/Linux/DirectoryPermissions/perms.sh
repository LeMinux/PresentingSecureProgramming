#colors
cyan="\033[0;36m"
nocolor="\033[0m"
green="\033[0;32m"
red="\033[0;31m"

dir="TestDir"
file="file.txt"
rename="renamed.txt"
known="cheese.txt"

printOffStatus() {
    $@
    if [[ $? == 0 ]]; then
        echo -e "${green}Success: $@${nocolor}"
    else
        echo -e "${red}Failed: $@${nocolor}"
    fi
}

printOffStatusBackground() {
    $@
    if [[ $! == 0 ]]; then
        echo -e "${green}Success: $@${nocolor}\n"
    else
        echo -e "${red}Failed: $@${nocolor}\n"
    fi
}

runTests() {
     printOffStatus touch "$dir/$file"
     printOffStatus mv "$dir/$file" "$dir/$rename" && rm "$dir/$rename"
     printOffStatus ls "$dir"
     printOffStatus ls -al "$dir"
     printOffStatus cat "$dir/$known"
     printOffStatus echo "I am cheese" > "$dir/$known"
     printOffStatusBackground cd "$dir" &
     echo ""
}

main() {
    if [[ ! -d "$dir" ]]; then
        mkdir "$dir"
    fi

    #rwx
    chmod 700 "$dir"
    echo -e "${cyan}700 (rwx)$nocolor"
    runTests

    #rw-
    chmod 600 "$dir"
    echo -e "${cyan}600 (rw-)$nocolor"
    runTests

    #r-x
    chmod 500 "$dir"
    echo -e "${cyan}500 (r-x)$nocolor"
    runTests

    #r--
    chmod 400 "$dir"
    echo -e "${cyan}400 (r--)$nocolor"
    runTests

    #-wx
    chmod 300 "$dir"
    echo -e "${cyan}300 (-wx)$nocolor"
    runTests

    #-w-
    chmod 200 "$dir"
    echo -e "${cyan}200 (-w-)$nocolor"
    runTests

    #--x
    chmod 100 "$dir"
    echo -e "${cyan}100 (--x)$nocolor"
    runTests

    #---
    chmod 000 "$dir"
    echo -e "${cyan}000 (---)$nocolor"
    runTests

    #give all permissions if user wants to do own testing
    chmod 700 "$dir"
}

main
