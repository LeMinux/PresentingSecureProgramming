#include <stdio.h>
#include <sys/stat.h>

static void printType(int mode){
    /*copied from the stat(2) man page*/
    switch (mode & S_IFMT) {
       case S_IFBLK:  printf("block device\n");            break;
       case S_IFCHR:  printf("character device\n");        break;
       case S_IFDIR:  printf("directory\n");               break;
       case S_IFIFO:  printf("FIFO/pipe\n");               break;
       case S_IFLNK:  printf("symlink\n");                 break;
       case S_IFREG:  printf("regular file\n");            break;
       case S_IFSOCK: printf("socket\n");                  break;
       default:       printf("unknown?\n");                break;
   }
}

static void printStatInfo(const char* file_string){
    struct stat file_info = {0};
    if(stat(file_string, &file_info) < 0){
        printf("Couldn't use STAT to resolve %s\n", file_string);
        perror("error");
    }else{
        printf("File type using STAT %s: ", file_string);
        printType(file_info.st_mode);
    }
}

static void printLstatInfo(const char* file_string){
    struct stat file_info = {0};
    if(lstat(file_string, &file_info) < 0){
        printf("Couldn't use LSTAT to resolve %s\n", file_string);
        perror("error");
    }else{
        printf("File type using LSTAT %s: ", file_string);
        printType(file_info.st_mode);
    }
}

int main(void){
    const char with_slash [] = "./link_to_dir/";
    const char without_slash [] = "./link_to_dir";
    puts("Using symlink with no slash at end");

    printStatInfo(with_slash);
    printStatInfo(without_slash);
    printLstatInfo(with_slash);
    printLstatInfo(without_slash);

    const char with_slash2 [] = "./link_to_dir2/";
    const char without_slash2 [] = "./link_to_dir2";
    puts("\nUsing symlink with slash at end");

    printStatInfo(with_slash2);
    printStatInfo(without_slash2);
    printLstatInfo(with_slash2);
    printLstatInfo(without_slash2);

    const char file_with_slash [] = "./link_to_file/";
    const char file_without_slash [] = "./link_to_file";
    puts("\nUsing symlink to a file");

    printStatInfo(file_with_slash);
    printStatInfo(file_without_slash);
    printLstatInfo(file_with_slash);
    printLstatInfo(file_without_slash);

    return 0;
}
