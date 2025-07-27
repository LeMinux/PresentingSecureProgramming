#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define MAX_INPUT_SIZE 21

int main(void) {
    //adding in newline to avoid confusion why there is a _ at the end
    static char ok_chars[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_-.@\n";
    char user_data [MAX_INPUT_SIZE] = "";
    puts("Enter something: ");
    fgets(user_data, MAX_INPUT_SIZE, stdin);
    printf("Original data:\n%s\n", user_data);

    /*
     * sanitization process
     * the way strspn works is by going through the given string and returning
     * the length when it finds an invalid character or null.
     * here we pass the string itself in with p and add length until the end
    */
    const char* end = user_data + strlen(user_data);
    char* p = user_data + strspn(user_data, ok_chars);
    for(; p != end; p += strspn(p, ok_chars)){
        *p = '_';
    }

    printf("Sanitized data with whitelist:\n%s\n", user_data);
    return EXIT_SUCCESS;
}
