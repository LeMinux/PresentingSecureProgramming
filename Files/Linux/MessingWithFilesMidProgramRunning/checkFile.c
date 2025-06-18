#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define FILE_NAME "./link"

int main(void){
    if(access(FILE_NAME, F_OK) != 0){
        fprintf(stderr, "%s", "Test File doesn't exist?!");
        exit(EXIT_FAILURE);
    }

    puts("Now to pretend there is some action");
    sleep(2); //pretend there is some action
    puts("Pretending done!");

    //write mode will delete contents of the file
    FILE* test_file = fopen(FILE_NAME, "w");
    if(test_file != NULL){
        fclose(test_file);
    }

    return EXIT_SUCCESS;
}
