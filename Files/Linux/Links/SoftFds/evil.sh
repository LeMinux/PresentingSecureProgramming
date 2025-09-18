#!/bin/bash

file="some_file.txt"
new_name="my_file_now.txt"
new_name2="goober.txt"
mv "$file" "$new_name"
mv "$new_name" "$new_name2"
sleep 12
mv "$new_name" "$file"
