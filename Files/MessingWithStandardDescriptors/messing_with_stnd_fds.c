#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>

int main(void){
    puts("This is using the program's given stdout descriptor");
    puts("Going to close STDOUT now");
    close(1);
    int fd = open("new_output.txt", O_WRONLY);
    puts("Writing into the file as STDOUT now");
    return 0;
}
