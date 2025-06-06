## File Security

### What Are Files

Ahhhh the fundamentals of storing data.
Before computers, a file was a collection of physical records.
Technically it got the name because it referred to a binding of string creating the collection rather than the actual collection.
Eventually to replace measly string, file folders were created to streamline storing files.
Then computers became good enough to store digital data, and to help ease the transition into a digital age these definitions stuck.
Nowadays, a file refers to the storing of digital data on a medium with folders acting as a collection of files on a GUI.
Technically, directories are the more proper term for folders by referring to how files and folders are indexed, but it doesn't matter.
//change the however to something else
However, due to the digital revolution files and file systems are so intertwined that you cannot have a file without the system.
In order to have a file, a file system has to define the name, location of contents on disk, and other data about the file.
//I dunno just put some crappy conclusion here for now
By understanding file systems and files, hopefully you will have a better understanding as to why certain practices exist.

### Linux File System

<talk about files on Linux>
<talk about file descriptor>
<talk about /proc>
    <proc has its own fds per process stored in /proc/<PID>/fd/>
<talk about stdin, stdout, stderr>
<talk about how stdout can be different since fd's are based off smallest number>


On Linux systems, files are the core of everything.
Linux takes files to the extreme by abstracting everything as a file.
Your devices are files, your configs are files, your standard input and output is a file, even processes are a file.
Technically everything isn't strictly a file, but more so wrapped in a file like object.
If you have used a dynamic window manager you are probably familiar with extracting or manipulating the system state with files.
Something like echoing 50 into the corresponding backlight file to change the brightness of the screen.
[Linux Process Injection](https://www.akamai.com/blog/security-research/the-definitive-guide-to-linux-process-injection)


### Windows File System

### FAT System

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

