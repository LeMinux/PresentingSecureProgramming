#!/bin/bash

#This is a script to show how directory permissions determine what can be done to the directory
#there is also a file used as an example to show how a file's permissions appear to rebel against
#the directory's permissions, but remember the directory is a list of inodes.

#colors
cyan="\033[0;36m"
nocolor="\033[0m"
green="\033[0;32m"
red="\033[0;31m"

dir="ShowPerms"
file="file.txt"
rename="renamed.txt"
known="known.txt"
executable="some_script.sh"

printOffStatus() {
    #short hand if/else
    #&& excutes if the exit status is 0 (success)
    #if not it will go to the || and say it failed
    "$@" && echo -e "\t${green}Success: $@${nocolor}" || echo -e "\t${red}Failed: $@${nocolor}"
}

#These functions below have special behavior that the normal function can't account for
#back ground process enters later and prints so needs a wait
printCDStatus() {
    cd "$dir" &
    wait $!
    if [[ $? == 0 ]]; then
        echo -e "\t${green}Success: cd${nocolor}"
    else
        echo -e "\t${red}Failed: cd${nocolor}"
    fi
}

#redirection is applied to the function call not the command if used on one line
printEchoStatus() {
    echo "I am a known file by direct path" > "$dir/$known"
    if [[ $? == 0 ]]; then
        echo -e "\t${green}Success: echo${nocolor}"
    else
        echo -e "\t${red}Failed: echo${nocolor}"
    fi
}

runTests() {
    echo  "Testing directory write permission"
    printOffStatus touch "$dir/$file" && mv "$dir/$file" "$dir/$rename" && rm "$dir/$rename"
    printOffStatus touch -a "$dir/$known"
    echo  "Testing directory read permission"
    printOffStatus ls "$dir"
    printOffStatus ls --all -l "$dir"
    echo  "Testing directory execute permission"
    printCDStatus

    echo  "Testing file read permission"
    printOffStatus cat "$dir/$known"
    echo  "Testing file write permission"
    printEchoStatus
    echo  "Testing file execute permissions"
    printOffStatus ./"$dir/$executable"
    echo ""
}

main() {
    if [[ ! -d "$dir" ]]; then
        mkdir "$dir"
    fi

    if [[ ! -f "$dir/$known" ]]; then
        echo "Have read the file" > "$dir/$known" && chmod 600 "$dir/$known"
    fi

    if [[ ! -f "$dir/$executable" ]]; then
        echo 'echo "executed the script"' > "$dir/$executable" && chmod 500 "$dir/$executable"
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

    chmod 700 "$dir"
    rm --recursive --force "$dir"
}

#tab error output to align with my tabbed input
main 2> >(sed 's/^/\t/' >&2)
