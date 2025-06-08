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
Therefore, a system had to be placed to define the abstraction of a file, the boundaries of files and what collections exist.
The identity of what creates a file or folder is so intertwined with the abstraction of the system that they cannot exist without the system.
This would mean that a system designed around a GUI vs a CLI would have different implementations on files.
It is this abstraction that determines how to properly handle files and folders thus affecting security.

### Linux File Handling

It is pretty well-know that Linux has a principle of treating "everything as a file".
Your devices are files, your configs are files, your standard input and output is a file, processes are many files, and mounting a drive turns into a file.
But how could this possibly be?
Aren't files binary data on disk that the system interprets?
That would be true if Linux did not have different types of files.
Everything is not strictly a file, but everything is handled like a file.
The mechanisms for reading, writing, opening, and closing are all streamlined but how is this done?
The core mechanism that this is accomplished is with file descriptors.
The beautiful fact about this abstraction is that it is just an integer.
This integer is what allows for such seamless behavior of piping, redirection, and sockets.
As an example, stdin, stdout, and stderr are defined as 0, 1, and 2 in that order.
When redirecting with `>>`, `>`, or `<`, it actually sets the fd as a link to that file in /proc/[PID]/fd.
Really anything that can take or send a byte string is a file on Linux.

But why is it an integer?
Well this is because there is file descriptor table that is essentially just an array.
Hence why the first three standard descriptors are 0, 1, and 2.

Really in Linux everything is treated as a byte stream.
Processes just take in the stream and parse the data.


Really everything is just a pointer.
A more accurate way of saying "everything is a file" is "everything has a file descriptor".
This kind of implementation is what allows the neat command line tricks like redirection and pipes
Technically everything isn't strictly a file, but more so wrapped in a file like object.
If you have used a dynamic window manager you are probably familiar with extracting or manipulating the system state with files.
Something like echoing 50 into the corresponding backlight file to change the brightness of the screen.
[Linux Process Injection](https://www.akamai.com/blog/security-research/the-definitive-guide-to-linux-process-injection)

//talk about files on Linux
//talk about file descriptor
//talk about /proc
    //proc has its own fds per process stored in /proc/<PID>/fd/
//talk about stdin, stdout, stderr
//talk about how stdout can be different since fd's are based off smallest number
//talk about fd table
    //how does fork and exec does with fds

### Linux File Permissions

//mention how exec for dirs is what allows stuff like ls and stat

Linux has permissions for the owner, group, and everyone else.
The way this is represented is essentially a number using the bits as the indications of what permissions are given.

777
read is 001
write is 010
execution is 100

Since binary is used to convert into a numeric value it is used as a shorthand for a command like chmod.
7 in binary is 111 which would give all permissions.
3 in binary is 011 which could give reading and writing.

### Links

Links are the main concern of file security.
Naive checking of a link will check the link itself rather than the file pointed to.
Links can also then change mid way through execution if a Look Before you Leap approach is taken.

### Windows File Handling

Windows is. . . ugh.
The problem with windows is that it is a hodgepodge of ideas combined into a single product, and this is because of the OOP design.
This might just be my digression, but OOP designs such inheriently lead to such bloat.
Objects are just so well defined that when you need to implement a completely new thing it just creates more objects.
Except now this object is having to remember how to use other objects.
Recently they have started to implement aspects of UNIX, but it is all under Windows.
Windows has a distinction on files, devices, and 
<case insensitive>


### Windows Files Permissions

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
<realtive paths vs absolute paths>
<sanatizing file paths>

### Directory Checking (Maybe have files and directories in one place)
<something about directory permissions>
<checking up the tree>


<umask funky>

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

    using exec on a to run a program that inherits all closed fds so new files are opened as the standard streams

    Closing a standard stream and trying to print or take input.
