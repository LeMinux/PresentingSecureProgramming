#!/bin/bash

#This is a script that just shows how the special directories of . and ..
#are hard links

dir1="dir1"
dir2="dir2"

mkdir -p "$dir1"
mkdir -p "$dir1/$dir2"

echo "Contents of dir1"
#ls -ali "$dir1"

#ls -ali "$dir1" | awk '{print "\033[1;32m" $1 "\033[0m", $0}'
#ls -ali "$dir1" | awk '{print "\033[1;32m" $1 "\033[0m", substr($0, length($1)+2)}'

ls -ali "$dir1" | awk --assign=dir2="$dir2" '
    $NF == "." {print "\033[1;33m" $1 "\033[0m", substr($0, length($1)+2)}       # Color current directory inode yellow
    $NF == dir2 {print "\033[1;36m" $1 "\033[0m", substr($0, length($1)+2)}      # Color dir2 inode cyan
    $NF != "." && $NF != dir2 {print $0}                                         # Leave other lines unchanged
'

echo -e "\nContents of dir2"
#ls -ali "$dir1/$dir2"
ls -ali "$dir1/$dir2" | awk '
    $NF == "." {print "\033[1;36m" $1 "\033[0m", substr($0, length($1)+2)}       # Color current directory inode cyan
    $NF == ".." {print "\033[1;33m" $1 "\033[0m", substr($0, length($1)+2)}      # Color parent directory inode yellow
    $NF != "." && $NF != ".." {print $0}                                         # Leave other lines unchanged
'

echo -e "\nNotice the matching colors!"
