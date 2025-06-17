## General File Security

### Handling Files Best Practices

//talk about race conditions esspecially when checking for files
    //it is better to let the OS do the magic
    //checking for existence then opening can be a race condition
    //Checking stat before opening
    //opening file then closing then opening again
    //links
    //file locks

### Deleting Files

It is probably well known now that deleting a file does not actually delete the file.
All deleting does is delete the pointers in the file system to the file.
The actual data of the file remains until the operating system gets to that free block to rewrite it.
This is what allows for file recovery tools to recover deleted files.

### Leaving Files Open

//talk about leaving files open

### Secretive Buffers

Most operations relating to a file actually use an internal buffer for efficiency.
With the way that a program interacts with the operating system it is better to conduct bulk writes than many smaller ones.
This is because calls for write() and read() are system calls that result in context switches.

### Dealing with File Paths

//realtive paths vs absolute paths
//sanatizing/canonicalization of file paths

