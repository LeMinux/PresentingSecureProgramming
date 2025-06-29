#!/bin/bash

#script to show that permissions of the parent directory need to be considered
#because it can result in moving a path

cyan="\033[0;36m"
nocolor="\033[0m"

dir="DirMoveWithin"
root_dir="RootDir"
root_dir2="GetMovedRoot"
rename_dir=""
current_root=""
file_in_root="root_file.txt"

mkdir --parents "$dir"

if [[ -d "$dir/$root_dir" ]]; then
    rename_dir="$root_dir2"
    current_root="$root_dir"
elif [[ -d "$dir/$root_dir2" ]];then
    rename_dir="$root_dir"
    current_root="$root_dir2"
else
    mkdir --parents "$dir/$root_dir"
    touch "$dir/$root_dir/$file_in_root"
    echo "Sudo permissions required to change $dir/$root_dir to root:root."
    sudo chown root:root "$dir/$root_dir"
    rename_dir="GetMovedRoot"
fi

echo -e "${cyan}Contents before${nocolor}"
ls --all -l "$dir"

echo -e "\nCommencing move"
mv --force "$dir/$current_root" "$dir/$rename_dir"
echo "Move done"

echo -e "\n${cyan}Contents after${nocolor}"
echo "After moving"
ls --all -l "$dir"
