source="print_paths_of_standard_descriptors.c"
exec="print_fds.out"
redir_file="empty_file.txt"
output_file="fd_output.txt"

if  [[ ! -f "$exec"  ]]; then
    gcc -Wall -Werror -Wpedantic "$source" -o "$exec"
fi

if  [[ ! -f "$redir_file"  ]]; then
    touch "$redir_file"
fi

echo "$exec"
./"$exec"
cat "$output_file"

echo ""

echo "$exec > $redir_file"
./"$exec" > "$redir_file"
cat "$output_file"

echo ""

echo "$exec < $redir_file"
./"$exec" < "$redir_file"
cat "$output_file"

echo ""

echo "$exec 2> $redir_file"
./"$exec" 2> "$redir_file"
cat "$output_file"

echo ""

echo "cat $redir_file | $exec"
cat "$redir_file" | ./"$exec"
cat "$output_file"
