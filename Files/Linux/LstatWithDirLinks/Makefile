LINK_TO_DIR:=link_to_dir
LINK_TO_DIR_WITH_SLASH:=link_to_dir2
LINK_TO_FILE:=link_to_file
DIR:=some_dir
FILE:=some_file

compile:
	gcc ./link_test.c

$(DIR):
	@mkdir $(DIR)
	touch $(FILE)
	@ln -sf ./$(DIR) $(LINK_TO_DIR)
	@ln -sf ./$(DIR)/ $(LINK_TO_DIR_WITH_SLASH)
	@ln -sf ./$(FILE) $(LINK_TO_FILE)

run: $(DIR)
	@ls -l $(LINK_TO_DIR) | awk '{print $$9" "$$10" "$$11}'
	@ls -l $(LINK_TO_DIR_WITH_SLASH) | awk '{print $$9" "$$10" "$$11}'
	@ls -l $(LINK_TO_FILE) | awk '{print $$9" "$$10" "$$11}'
	./a.out

clean:
	rm -f ./a.out
	rm -f $(LINK_TO_DIR)
	rm -f $(LINK_TO_DIR_WITH_SLASH)
	rm -f $(LINK_TO_FILE)
	rm -f $(FILE)
	rmdir $(DIR)

