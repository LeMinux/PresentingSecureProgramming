#include "unsafe_functions.h"

#define MAX_CASES 10

enum show_cases {STRCPY = 0, STRNCPY, STRCAT, SPRINTF, VSPRINTF, GETS, SCANF, MKTEMP, TMPNAM, ACCESS, STAT, EXECVP, EXECLP};

int main(void){
	enum show_cases selection = STRCPY;
	switch(selection){
		STRCPY:   showStrCpy();
		STRNCPY:  showStrNCpy();
		STRCAT:   showStrCat();
		SPRINTF:  showSprintf();
		VSPRINTF: showVSprintf();
		GETS:     showGets();
		SCANF:    showScanf();
		MKTEMP:   showMktemp();
		TMPNAM:   showTmpname();
		ACCESS:   showAccess();
		STAT:     showStat();
		EXECVP:   showExecvp();
		EXECLP:   showExeclp();
		break;
		default: break;
	}
}
