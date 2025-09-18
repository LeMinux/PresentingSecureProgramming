//welp the plans of moving a file as it was writing has failed because
//it still tracks the movement even though it shows fds as soft links

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

const char IN_FILE [] = "some_file.txt";

int main(void){

    FILE* in_file = fopen(IN_FILE, "w");
    if(in_file == NULL){
        fprintf(stderr, "Couldn't open file");
        exit(EXIT_FAILURE);
    }

    printf("my id: %d\n", getpid());
    sleep(10);
    pid_t pid = fork();
    if(pid < 0){
        fprintf(stderr, "Failed to fork :(\n");
        exit(EXIT_FAILURE);
    }

    if(pid == 0){
        //evil child
        puts("Devious child >:)");
        char* args [] = {"evil.sh", NULL};
        execv("./evil.sh", args);
    }else{
        //parent
        printf("parent PID: %d\n", pid);
        fflush(stdout);
        sleep(8);
        puts("Oh boy time to write to the file");
        if(fputs("Yippie!", in_file) < 0){
            fprintf(stderr, "WHAT!? failed to write!?/n");
        }else{
            puts("Yep wrote just fine");
        }
    }

    exit(EXIT_SUCCESS);
}
