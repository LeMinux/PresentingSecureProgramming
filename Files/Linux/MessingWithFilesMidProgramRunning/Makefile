EXEC=checkFile.c
OUT=race_condition.out
SCRIPT=run_link_test.sh

compile:
	gcc -Wall -Werror -Wpedantic $(EXEC) -o $(OUT)

run:
	./$(SCRIPT)

clean:
	rm -f ./link
	rm -f ./original_file.txt
	rm -f ./new_point.txt
