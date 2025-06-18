original="original_file.txt"
new="new_point.txt"
exec="race_condition.out"
link="link"

echo "I am the original file the link is point to!" > "$original"
echo "I am the file that the link will point to mid-way!" > "$new"

echo "Contents of files before test"
echo "Original: $(cat $original)"
echo "New: $(cat $new)"
echo ""

ln -sf ./original_file.txt "$link"
echo "Link before execution $(ls -al $link)"
./"$exec" &
pid=$! #get pid of child process
ln -sf ./new_point.txt "$link"
echo "Link changed during execution $(ls -al $link)"

wait "$pid"

echo ""
echo "Contents of files after test:"
echo "Original: $(cat $original)"
echo "New: $(cat $new)"
