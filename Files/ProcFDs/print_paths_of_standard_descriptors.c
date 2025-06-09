#include <unistd.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// /proc/4194304/fd/0\0 (19)
// maximum pid is 4194304 so length of +7
// /proc/ is +6
// /fd/ is +4
// ending file descriptor is +1
// nul byte at end +1
#define MAX_PATH_LENGTH 19

enum STND_FDS {STDIN = 0, STDOUT, STDERR};

struct Fd_Info {
    char link_path [PATH_MAX];
};

int main(void){
    FILE* output_file = fopen("fd_output.txt", "w");
    if(output_file == NULL){
        exit(EXIT_FAILURE);
    }

    pid_t pid = getpid();
    char fd_path [MAX_PATH_LENGTH] = "";

    int snprint_ret = snprintf(fd_path, MAX_PATH_LENGTH, "/proc/%d/fd/0", pid);
    if( snprint_ret < 0 || snprint_ret >= MAX_PATH_LENGTH){
        fprintf(stderr, "path to fds could not be created");
        exit(EXIT_FAILURE);
    }
    int fd_index = strlen(fd_path) - 1;

    for(int fd = STDIN; fd <= STDERR; ++fd){
        fd_path[fd_index] = fd + '0'; //convert to ASCII number
        char resolved_path [PATH_MAX];
        char* result = realpath(fd_path, resolved_path);
        if(result != NULL){
            fprintf(output_file, "%d -> %s\n", fd, resolved_path);
        }else{
            fprintf(output_file, "Failed to resolve %d\n", fd);
        }
    }

    return 0;
}
