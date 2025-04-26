#include <stdio.h>

#define BUF_SIZE 20

int main(void){
	char input [BUF_SIZE] = "";
	int some_int = 0;
	puts("enter something");
	//in this case I don't care about the return value as this is
	//just an example
	(void)fgets(input, BUF_SIZE, stdin);
	puts("\nLets show the difference between parameters!");
	puts("This is the safe approach to formatting");
	printf("%s\n", input);
	puts("Now the insecure way");
	//this is insecure as an attacker can input their own formats into the string
	//there is a warning given about this
	printf(input);

	printf("\nresult of int after %d\n", some_int);
}
