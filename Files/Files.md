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
Well the previous statement is not entirely true.
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

### Linux File Permissions

//mention how exec for dirs is what allows stuff like ls and stat
//talk about suid and guid

Before we get into how to handle files on Linux we need to understand how permissions work on Linux.
The permissions are split into ownership and the permissions.
For ownership, there is the owner of the file, group ownership, and everyone else.
For permissions, they are read, write, and execute.
Using ls with the list flag `ls -l` will show all the necessary info.
It will give something like this `-rwxrw-r--  1 User Group   148 Jun  7 17:30  bigsleep.c`.
Here the permissions are given by the `-rwxrw-r--` string.
The beginning dash is there to show the file type.
A link would have l and a directory would have a d.
Excluding the file type, the permissions are read in a set of 3.
The first three is for the owner, the second three is for the group, and the last three are for everyone else.
Using the previous example the owner has all permissions, the group has read and write, and everyone has read permissions.
If you are still confused I'll provide some other examples below.
```
-rw-r-----
    read & write for owner
    Only read for groups
T    no permissions for everyone else

-rw-r--r--
    read & write for owner
    Only read for groups
    Only read for everyone else

----------
    No permissions for owner, group, or everyone else

-rwxrwxrwx
    owner, group, and everyone has read, write, and execute

drwxr-xr-x
    All permissions for the owner
    read and excute for the group
    read and excute for everyone
    File is a directory
```

You may also see these permissions represented in their numerical form especially when setting permissions with chmod.
In their numerical representation they are 3 bits with 001 (1) as read, 010 (2) as write, and 100 (4) as execution.
It is basically using the bits of the number as the boolean flags instead of having 3 separate booleans.
```
7 (111) set exec, write, and read
3 (011) set write and read
5 (101) set exec and read
```

#### Suid and Guid bits

//talk about how to safely drop permissions
    //permanent and temporary
//show a program that has setuid

Remember how ownership of a file was determined by the user and group?
Well these setuid bits change that behavior.
What these bits do is give you the permissions of the owning user or the owning group.
This is where permissions on Linux become more complicated because these bits reveal the underlying system on how permissions work.
When a process is started it is actually given 3 IDs for the user and group.
These IDs are the effective, real, and saved ID
The effective user ID is what determines the actual permissions to enforce.
The real ID is who ran the program.
The saved ID is used to switch between privileges.
For normal programs, all the IDs are set to who ever started the process.
Since all the bits are the same it does not allow for the altering of permissions unless the process is run by root.
Setuid bits change the effective and saved ID to the owning user or group with the real ID to who started the process.
This would mean if the user Jimbo ran a program that was owned by root with setuid the effective and saved IDs are root, but the real ID is Jimbo.
It is incredibly dangerous to use setuid and setguid bits, and it should be avoided at all costs.
If they must be used, drop the permissions as fast as possible preferably permanently.

### Linux File Handling

//talk about file descriptor
//talk about /proc
    //proc has its own fds per process stored in /proc/<PID>/fd/
//talk about stdin, stdout, stderr
//talk about how stdout can be different
//talk about fds returnign the smallest number it is not incremental
//mention redirecting any file descriptor

Okay so now we understand what a Linux file is, but how does a programmer handle files?
What mechanisms streamlines the basic file operations?
The core mechanism that this is accomplished is with on Linux is file descriptors.
The beautiful fact about this abstraction is that it is just an unsigned integer.
This integer corresponds to an index in the file descriptor table that is unique to each process.
These descriptors can be listed by this command `ls -al /proc/<pid of process>/fd/`.
Each process will have 0, 1, and 2 descriptors which corresponds to stdin, stdout, and stderr.
Any other files that get opened will get the next lowest number.
Processes can have identical number descriptor since files are localized to them.
It is the kernel that handles what the descriptor links to as well as the permission desired like read-only/write-only.
The operating system has a limit to how many descriptors a process and the system can have.
For processes these limits can be found with `ulimit -Sn`(soft limit) and `ulimit -Hn`(hard limit).
The global system limit is found under `/proc/sys/fs/file-max`.
The soft limit can be controlled by the user and is the limit for that session.
The hard limit is an absolute maximum that can not be surpassed and is only modifiable by root.

At the OS level though, these file descriptors link to the actual file.
When redirecting with `>>`, `>`, or `<`, it is actually redirecting the fd as a link to that file.
If you want to see this go to the ProcFD/ directory and run the show_fd.sh script.
There, you should see the paths that the standard descriptor links to and the fd of the new file.
Now it not always a direct link to a file path.
Remember that are many types of files, and some files do not have named paths.
If you notice with the pipe example it can't resolve the path for stdin since an anonymous pipe has no path.
The same behavior would apply for unnamed sockets as well.
There are named pipes and sockets which do have a path and behave like regular files, but do not store data on disk.

That little experiment goes to show that a file on Linux is just an integer with some kernel magic behind it.
However, let us take a closer look at how a file descriptor is given.
It obtains the next lowest number.
So if the 5th file opened (fd of 4) were to close and there are already 10 open files the next fd to be given would be 4 since that is the lowest compared to 10.
```
/* remember 0, 1, 2 are the standard descriptors */

[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, x]

/* close 5th file */

[0, 1, 2, 3, x, 5, 6, 7, 8, 9, x]

/* open new file */

[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, x]
```

This caveat is important to know because this also applies to the standard file descriptors.
If 0, 1, or 2 were to close due to some bug, any new file would get a standard file descriptor.
This would mean that if a file were to be opened as stdout anything printed would go that file instead and would mess up the file.

//Talk about this at some point
There is also a limit to how many file descriptors can be made which can be found at /proc/sys/fs/file-max.
[Linux Process Injection](https://www.akamai.com/blog/security-research/the-definitive-guide-to-linux-process-injection)

### Links

Links are the main concern of file security.
Naive checking of a link will check the link itself rather than the file pointed to.
Links can also then change mid-way through execution if a Look Before you Leap approach is taken.

### File Descriptors and Process Execution

//talk about fd table
//how does fork and exec do with fds

### Windows File Handling

//case insensitive
Windows is. . . ugh.
The problem with windows is that it is a hodgepodge of ideas combined into a single product, and this is because of the OOP design.
Windows has a distinction on files, devices, and //I dunno other stuff I'll have to find
This results in many APIs used for different file types.

### Windows Files Permissions

//my god I'll have to go into Administrator, SYSTEM, Active directory and such
//and all the other permission types

| Permission      | Description |
| :-------------: | :---------: |
| DELETE          | The ability to delete the object |
| READ_CONTROL    | The ability to read the object’s security descriptor, not including its SACL |
| SYNCHRONIZE     | The ability for a thread to wait for the object to be put into the signaled state |
| WRITE_DAC       | The ability to modify the object’s DACL |
| WRITE_OWNER     | The ability to set the object’s owner |
| GENERIC_READ    | The ability to read from or query the object |
| GENERIC_WRITE   | The ability to write to or modify the object |
| GENERIC_EXECUTE | The ability to execute the object (applies primarily to files) |
| GENERIC_ALL     | Full control |

### General File Security

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

### Directory Checking

//probably will move this into the directory chapter
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
