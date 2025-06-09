## File Security

### What Are Files

//talk more so about files than the file system
//the file system isn't much of a concern as it's the abstraction that allows access to files
//it really should not be a concern unless the implementation itself leads to security issues

Ahhhh the fundamentals of storing information.
Before computers, a file was a collection of physical records.
Technically it got the name because it referred to a binding of string (filum in Latin) creating the collection rather than the actual collection.
At the time for smaller collections it worked just fine, but to meet the mass needs of businesses and bureaucracy a better form of binding was needed.
This is what lead to file folders to streamline storing files.
These are the little folder icons you see when browsing the file explorer.
Language, at least in English, still referred to container rather than the collection.
It was pretty typical to hear phrases like "Could you hand me the file about x" or "what files do we have about y".
Then people figured out a way to make rocks abide by the whimsical demands of humans which gave rise to computers.
Eventually the computers became good enough to store digital data, and to help ease the transition into a digital age these definitions stuck.
Now I can hear you say "Wow! Nice history lesson that I don't care about!", but just bear with me.
The digital age fundamentally changed how we deal with files.
Files are a singular unit defined by a collection of binary rather than records.
Unlike paper which could simply be grabbed, binary data needs interpretation on what it is.
Therefore, a system had to be placed to define the abstraction of a file, the boundaries of files, and what collections exist.
The identity of what creates a file or folder is so intertwined with the abstraction of the system that they cannot exist without the system.
This would mean that a system designed around a GUI vs a CLI would have different implementations on files.
It is this abstraction that determines how to properly handle files and folders thus affecting security.

### Linux Files

It is pretty well-know that Linux has a principle of treating "everything as a file".
Your devices, your memory, your configs, your standard input and output, processes, and mounted file systems are "files".
But how could this possibly be?
Aren't files a logical location of binary data on disk?
Well the previous saying is not entirely true.
A more accurate saying would be to say "everything can be treated as a file".
There is a singular common interface where a program can use open(), close(), read(), and write() no matter the "file".
The actual implementation is abstracted away, and the program just has to worry about a byte stream.
Naturally, this means Linux has different kinds of files which are specified in the man page for find.
They are shown below.
```
-type c
      File is of type c:

      b      block (buffered) special

      c      character (unbuffered) special

      d      directory

      p      named pipe (FIFO)

      f      regular file

      l      symbolic link; this is never true if the -L option or the
             -follow  option is in effect, unless the symbolic link is
             broken.  If you want to search for symbolic links when -L
             is in effect, use -xtype.

      s      socket

      D      door (Solaris)
```
Beyond file types though this is all the user can see.
The kernel will handle what drivers are used for the file.
A little peek into how the drivers are specified is under linux/fs.h. (probably under /usr/src/\[linux header version\]/include/linux/fs.h)
The kernel will define what operations are available with the file_operations struct.
It looks something like this
```
/* this is not the complete structure */
struct file_operations {
	struct module *owner;
	loff_t (*llseek) (struct file *, loff_t, int);
	ssize_t (*read) (struct file *, char __user *, size_t, loff_t *);
	ssize_t (*write) (struct file *, const char __user *, size_t, loff_t *);
    . . .
	int (*open) (struct inode *, struct file *);
	int (*flush) (struct file *, fl_owner_t id);
	int (*release) (struct inode *, struct file *);
    . . .
} __randomize_layout;
```
The important ones to note here are the open, release (close), read, and write function pointers.
Pretty neat if you ask me!

### Linux File Handling

//talk about file descriptor
//talk about /proc
    //proc has its own fds per process stored in /proc/<PID>/fd/
//talk about stdin, stdout, stderr
//talk about how stdout can be different
//talk about fds returnign the smallest number it is not incremental
//talk about fd table
    //how does fork and exec do with fds

Okay so now we understand what a Linux file is, but how is it actually handled for the programmer?
What mechanisms streamlines the basic file operations?
The core mechanism that this is accomplished is with file descriptors.
The beautiful fact about this abstraction is that it is just an unsigned integer.
This integer is what allows for such seamless behavior of piping, redirection, and sockets.
As an example, stdin, stdout, and stderr are defined as 0, 1, and 2 in that order.
When redirecting with `>>`, `>`, or `<`, it is actually redirecting the fd as a link to that file.
But why is it an integer?
You might know about fopen and how that gives you a FILE\*, so why is that not used?
Well the integer correspondes to a file descriptor table that each process has.
It is basically an array hence why the first three standard descriptors are 0, 1, and 2.

//Talk about this at some point
[Linux Process Injection](https://www.akamai.com/blog/security-research/the-definitive-guide-to-linux-process-injection)

### Linux File Permissions

//mention how exec for dirs is what allows stuff like ls and stat

Linux has permissions for the owner, group, and everyone else.
The way this is represented is essentially a number using the bits as the indications of what permissions are given.
read is 001
write is 010
execution is 100

Since binary is used to convert into a numeric value it is used as a shorthand for a command like chmod.
7 in binary is 111 which would give all permissions.
3 in binary is 011 which could give reading and writing.
777

### Links

Links are the main concern of file security.
Naive checking of a link will check the link itself rather than the file pointed to.
Links can also then change mid-way through execution if a Look Before you Leap approach is taken.

### Windows File Handling

//case insensitive
Windows is. . . ugh.
The problem with windows is that it is a hodgepodge of ideas combined into a single product, and this is because of the OOP design.
Windows has a distinction on files, devices, and //I dunno other stuff I'll have to find
This results in many APIs used for different file types.


### Windows Files Permissions

//my god I'll have to go into Administrator, SYSTEM, Active directory and such
//and all the other permission types

### File Security
<talk about race conditions esspecially when checking for files>
    <it is better to let the OS do the magic>
    <checking for existence then opening can be a race condition>
    <links>

### Deleting Files

It is probably well known now that deleting a file does not actually delete the file.
All deleting does is delete the pointers in the file system to the file.
The actual data of the file remains until the operating system gets to that free block to rewrite it.
This is what allows for file recovery tools to recover deleted files.
<erasing file securely>

### Leaving Files Open
<talk about leaving files open>

### Secretive Buffers

Most operations relating to a file actually use an internal buffer for efficiency.
With the way that a program interacts with the operating system it is better to conduct bulk writes than many smaller ones.
This is because calls for write() and read() are system calls that result in context switches.

### Dealing with File Paths
//realtive paths vs absolute paths
//sanatizing/canonicalization of file paths

### Directory Checking (Maybe have files and directories in one place)
//something about directory permissions
//checking up the tree


//umask funky

S_IRWXU     0700    Owner read, write, execute
S_IRUSR     0400    Owner read
S_IWUSR     0200    Owner write
S_IXUSR     0100    Owner execute
S_IRWXG     0070    Group read, write, execute
S_IRGRP     0040    Group read
S_IWGRP     0020    Group write
S_IXGRP     0010    Group execute
S_IRWXO     0007    Other/world read, write, execute
S_IROTH     0004    Other/world read
S_IWOTH     0002    Other/world write
S_IXOTH     0001    Other/world execute

CODES TO TEST
    Closing a standard stream and opening a file to replace that stream's fd
        since opening gives the lowest number it would replace that stream, so could input in that file be used as the stream?

    using exec on to run a program that inherits all closed fds so new files are opened as the standard streams

    Closing a standard stream and trying to print or take input.

### Sources

Secure Programming Cookbook for C and C++ by John Viega and Matt Messier
