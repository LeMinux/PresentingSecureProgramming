## Linux File Security

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
As well as a system designed for multiple users vs a singular user.
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
//talk about precedence

Before we get into how to handle files on Linux, we need to understand how permissions work on Linux.
Permissions are the main way the operating system enforces its rules on a process.
It is important not just for finding out if a file is operable, but also how to correctly set permissions securely.
The permissions are split into ownership and the permission types.
For ownership, there is the owner of the file, group ownership, and everyone else/other/world.
For permissions, they are read, write, and execute.
The permissions also have a precedence from owner to group to other.
This means that even if the permissions of other were to allow everything, if the group permissions only allows for reading people part of that group can only read.
To find the permissions of a file, ls with the list flag `ls -l` will show all the necessary info.
It will give something like `-rwxrw-r--  1 Jimbo Office   148 Jun  7 17:30  bigsleep.c`.
The table below shows what each segment means.
| File Type | Permission String | Number of Hard Links | Owning User | Owning Group | File Size | Last Modification Date | Filename |
| :--------:| :---------------: | :------------------: |:---------: | :----------: | :-------: | :--------------------: | :------: |
| - | rwxrw-r-- | 1 | Jimbo | Office | 148 | Jun 7 17:30 | bigsleep.c |
Here the permissions are given by the `rwxrw-r--` string with the owning user as Jimbo and the owning group as Office.
The permission string is read in sets of 3 in the order of owner, group, and everyone else.
In this example the owner has all permissions, the group has read and write, and other has read permissions.
If you are still confused there are more examples below.
```
-rw-r-----
    read & write for owner
    Only read for groups
    no permissions for everyone else
    Normal file

-rw-r--r--
    read & write for owner
    Only read for groups
    Only read for world
    Normal file

----------
    No permissions for owner, group, or other
    Normal file

-rwxrwxrwx
    owner, group, and everyone else has read, write, and execute
    Normal file

drwxr-xr-x
    All permissions for the owner
    read and excute for the group
    read and excute for everyone else
    File is a directory
```

You may also see these permissions represented in their numerical form especially when setting permissions with chmod.
In their numerical representation they are an octal value (3 bits) with 001 (1) as read, 010 (2) as write, and 100 (4) as execution.
Any number between 0 and 7 can be used to represent the permissions since it is using the location of the bits.
If we use the previous permissions string example here it would look like this.
```
7 (111) set exec, write, and read
5 (101) set exec and read
3 (011) set write and read
1 (001) set read


310
    read & write for owner
    Only read for groups
    no permissions for everyone else
    Normal file

311
    read & write for owner
    Only read for groups
    Only read for world
    Normal file

000
    No permissions for owner, group, or other
    Normal file

777
    owner, group, and everyone else has read, write, and execute
    Normal file

755
    All permissions for the owner
    read and excute for the group
    read and excute for everyone else
```

#### Owning a File

Now that you can read the permissions, what does it mean to own a file beyond the permissions?
As an example, what happens if the owner is locked out of their own file because it has the permissions of 061?
Here the owner cannot read, write, or execute this file, so are they just screwed?
Luckily, they are not because the owning user can alter the permissions of files they own.
So the owning user can simply use `chmod 761 <the file>` to get the permissions back.
They can not change the owning user or owning group of the file with chown though since that is a root action.

#### Owning a Directory

#### Permissions Along Directory Path

### Directory Checking

//probably will move this into the directory chapter
//something about directory permissions
//checking up the tree

#### Access Control Lists (ACL)

#### Root

Root is an exception to the permission system.
Since root users need to be able to alter system state, they can do anything on the system.
This includes changing file ownership, file permissions, zeroing out a storage device, mounting a file system, etc.
Even with a file that has 000 permissions (even owned by root), the root user can still read, write, and execute the program.
It makes sense though since a root user should not be prevented from removing a file and such.
Users can obtain superuser permissions if they are set to have them as specified in the /etc/sudoers file.
Although depending on how permissions are set in sudoers a user or group could only have certain root commands available.
Root is incredibly dangerous to use all willy-nilly, so only use root only when strictly necessary.
The utmost care should be taken to avoid an attacker creating a root shell allowing them to create wreak havoc on the system.
Security involving root becomes a lot more important in the next section.

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
Since all the bits are the same it does not allow for the altering of permissions unless the process was run by root.
Setuid bits change the effective and saved ID to the owning user or group with the real ID set to who started the process.
This would mean if the user Jimbo ran a program that was owned by root with setuid the effective and saved IDs are root, but the real ID is Jimbo.

It is incredibly dangerous to use setuid and setguid bits, and it should be avoided at all costs.
If they must be used, drop the permissions as fast as possible preferably permanently.

To figure out if a program has a setuid or setguid bit active the `ls -l` will show this.
If the setuid bit is set it will display an 's' or an 'S' if setuid is set without a way to execute it. in the permissions string like so `-rwSrwSr--`.
In this example, the setuid and setguid bit is set.
The `file` command can also be used to see if setuid/setguid is set.
If the bits are set, it will print `setuid` and/or `setguid`.
Just like normal permissions setuid/setguid also has a numerical octal value.
Their number is specified ahead of the standard 3 numbers with 100 (4) as setuid, 010 (2) as setguid, and 001 (1) as sticky.
They would be represented like so `6755`
This numerical representation is good to know for the find command with system administration.
Using a command like `find / -perm /4000` will scan the entire system finding any file that has setuid.

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

#### Links

Links are the main concern of file security.
They take special care to handle as naive checking will create a security vulnerability.
Links can also then change mid-way through execution if a Look Before you Leap approach is taken.

#### Device Files

### File Descriptors and Process Execution

//talk about fd table
//how does fork and exec do with fds

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
