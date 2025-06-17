#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>

int main(void){
    puts("Going to mess with STDIN\n");
    puts("Enter anything");
    (void)fgetc(stdin); // Don't care to parse input
    close(0);
    fopen("./new_input.txt", "r"); //show it works with fopen as well
    int input_there = 1;
    while(input_there){
        int input = fgetc(stdin);
        if(input != EOF){
            printf("%c", input);
        }else{
            input_there = 0;
        }
    }

    puts("-------------------");
    puts("Going to mess with STDOUT\n");
    puts("This is using the program's given stdout descriptor");
    puts("Going to close STDOUT now");
    close(1);
    int fd = open("new_output.txt", O_WRONLY);
    puts("Writing into the file as STDOUT now");

    puts("-------------------");
    puts("Going to mess with STDERR\n");

    return 0;
}
