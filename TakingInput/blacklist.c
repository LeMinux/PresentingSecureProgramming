#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define MAX_INPUT_SIZE 21

int main(void) {
    static char bad_chars[] = "/@ ;[]<>&\t";
    char user_data [MAX_INPUT_SIZE] = "";
    puts("Enter something: ");
    fgets(user_data, MAX_INPUT_SIZE, stdin);
    printf("Original data:\n%s\n", user_data);

    /*
     * sanitization process
     * Notice is is strCspn and not strspn
     * strCspn works like strspn, but it returns the number of characters before
     * the first occurance of a letter in the second argument.
     * here we pass the string itself in with p and add length until the end
    */
    const char* end = user_data + strlen(user_data);
    char* p = user_data + strcspn(user_data, bad_chars);
    for(; p != end; p += strcspn(p, bad_chars)){
        *p = '_';
    }

    printf("Sanitized data with blacklist:\n%s\n", user_data);
    return EXIT_SUCCESS;
}
