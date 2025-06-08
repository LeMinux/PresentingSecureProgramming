#include <stdio.h>

#define SQUARE(x) ((x) * (x))       /* syntatically correct and maintains order */
#define BAD_SQUARE(x) (x * x)       /* syntatically correct, but does not maintain order */
#define EVEN_WORSE_SQUARE(x) x * x  /* not syntatically correct, nor maintains order */

int main(void){
    return 0;
}
