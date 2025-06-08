#ifndef FILE_SHOW_CASE_H
#define FILE_SHOW_CASE_H

//These methods are used to show how fds are inherited
void execWithGivenFds();
void forkWithGivenFds();

//Close stout fd (1) and try to print
void closeStdoutAndPrint();

//Close stout fd (1) to then open a new file and print to stdout
void closeStdoutOpenNewAndPrint();

//Show info about standard streams with fstat
void showPipeStats();

#endif
