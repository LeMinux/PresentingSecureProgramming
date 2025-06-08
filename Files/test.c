#include <stdio.h>
#include <sys/stat.h>
#include "test.h"

static void prinOpenFileInfo(int fd){
    struct stat file_info = {0};
    if(fstat(fd, &file_info) != 0){
        
    }
}

void showPipeStats(){

}

int main(void){
    
}
