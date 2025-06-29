#!/bin/bash

#colors
cyan="\033[0;36m"
nocolor="\033[0m"

dir="ShowWrite"
file="some_file.txt"
root_file="some_root_file.txt"

main() {
    mkdir -p "$dir"
    touch "$dir/$file"
    touch "$dir/$root_file"
    echo "Sudo permissions required to change $dir/$root_file to root:root."
    sudo chown root:root "$dir/$root_file"

    echo -e "${cyan}Contents before${nocolor}"
    ls -al "$dir"

    echo -e "\nremoving file owned by $(whoami)"
    rm "$dir/$file"

    echo -e "removing file owned by root"
    rm --force "$dir/$root_file"

    echo -e "\n${cyan}Contents after${nocolor}"
    ls -al "$dir"

    rmdir "$dir"
}

main
