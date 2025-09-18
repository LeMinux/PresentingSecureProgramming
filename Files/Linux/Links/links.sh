#!/bin/bash

#This script shows the difference between a hard link and soft link

dir_container="HardSoft"
original_file="data_file.txt"
rename_file="rename_file.txt"
hard_link="hard_link"
soft_link="soft_link"
random_soft_link="random_softy"

mkdir -p "$dir_container"
rm -f "$dir_container/$rename_file"
echo "La La La I have data" > "$dir_container/$original_file"

if [[ ! -f "$dir_container/$hard_link" ]]; then
    ln "$dir_container/$original_file" "$dir_container/$hard_link"
fi

if [[ ! -f "$dir_container/$soft_link" ]]; then
    ln -s "$original_file" "$dir_container/$soft_link"
fi

if [[ ! -f "$dir_container/$random_soft_link" ]]; then
    ln -s "ieahtiehatihaietih" "$dir_container/$random_soft_link"
fi

exit 0

echo -e "dir content\n"
ls -al "$dir_container"

echo -e "\n"
echo -e "Contents of original:\n$(cat "$dir_container/$original_file")\n"
echo -e "Contents of hard link:\n$(cat "$dir_container/$hard_link")\n"
echo -e "Contents of soft link:\n$(cat "$dir_container/$soft_link")\n"
echo -e "Contents of soft link:\n$(cat "$dir_container/$random_soft_link")\n"

echo "Changing $original_file contents\n"
echo "No! I'm the original!" > "$dir_container/$original_file"
echo -e "Contents of original:\n$(cat "$dir_container/$original_file")\n"
echo -e "Contents of hard link:\n$(cat "$dir_container/$hard_link")\n"
echo -e "Contents of soft link:\n$(cat "$dir_container/$soft_link")\n"
echo -e "Contents of soft link:\n$(cat "$dir_container/$random_soft_link")\n"

echo -e "\n"
echo "Changing permissions of the original file"
chmod 700 "$dir_container/$original_file"
ls -al "$dir_container"

echo -e "\n"
echo "Going to rename $original_file to $rename_file"
mv "$dir_container/$original_file" "$dir_container/$rename_file"
ls -al "$dir_container"
echo -e "\n"
echo -e "Contents of original:\n$(cat "$dir_container/$original_file")\n"
echo -e "Contents of hard link:\n$(cat "$dir_container/$hard_link")\n"
echo -e "Contents of soft link:\n$(cat "$dir_container/$soft_link")\n"
echo -e "Contents of soft link:\n$(cat "$dir_container/$random_soft_link")\n"
