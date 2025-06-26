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
This means there is a singular common interface that programs use to interact with a file.
Common operations like open(), close(), read(), and write() can be done regardless of what the file is.
The actual implementation is abstracted away, and the program just has to worry about handling.
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

#### Inodes

However, the kernel needs a definition of what a file is.
It is good to know how the kernel handles different files, but information about the file has to be stored.
Metadata as it is called.
This is where the file system comes into play by storing metadata about a file and defining what a file is.
On Linux, a file is defined by an inode (index node).
There exists an inode table that is unique per file system, so this would mean /dev/sda1 or /dev/sdb1 would contain different tables since files systems are per partition.
Since this can lead to two identical inode numbers, the inode number is a combination of the device ID and the inode number.
The device id itself is split into a major and minor ID that defines the device type and class.
The inode number itself is an incrementing 32-bit unsigned number which creates about 4 billion inodes.
As the name index node implies, it is effectively an index in a large array.
This large array defines all the metadata associated with a file.
The inode will point to information like the file permissions, link count, and ownership.
All information stored can be found in the stat struct in the stat (2) man page shown below.
```
struct stat {
    dev_t     st_dev;         /* ID of device containing file */
    ino_t     st_ino;         /* Inode number */
    mode_t    st_mode;        /* File type and mode */
    nlink_t   st_nlink;       /* Number of hard links */
    uid_t     st_uid;         /* User ID of owner */
    gid_t     st_gid;         /* Group ID of owner */
    dev_t     st_rdev;        /* Device ID (if special file) */
    off_t     st_size;        /* Total size, in bytes */
    blksize_t st_blksize;     /* Block size for filesystem I/O */
    blkcnt_t  st_blocks;      /* Number of 512B blocks allocated */

    /* Since Linux 2.6, the kernel supports nanosecond
       precision for the following timestamp fields.
       For the details before Linux 2.6, see NOTES. */

    struct timespec st_atim;  /* Time of last access */
    struct timespec st_mtim;  /* Time of last modification */
    struct timespec st_ctim;  /* Time of last status change */

    #define st_atime st_atim.tv_sec      /* Backward compatibility */
    #define st_mtime st_mtim.tv_sec
    #define st_ctime st_ctim.tv_sec
};
```
All of this information is also available in a readable format with `ls -l`.

If you notice though, there is no member for the name of the file.
As far as the kernel is concerned, it does not need the name because the inode uniquely defines the file.
Humans on the other hand, need to have the name of the file, so this would mean there is some translation between the name to the inode.
Directories, are what handle this translation.
Logically, directories are a list of entries (dentries) that map the file name to its inode.
It acts like a dictionary where the key is the file name and the value is the inode.
The directory entry is defined in dirent.h and its struct looks like this.
```
struct dirent {
    ino_t          d_ino;       /* Inode number */
    off_t          d_off;       /* Current position in directory stream. Treat as an opaque value */
    unsigned short d_reclen;    /* Length of this record */
    unsigned char  d_type;      /* Type of file; not supported by all filesystem types */
    char           d_name[256]; /* Null-terminated filename */
};
```

As you may notice, this struct is quite bare compared to the stat struct because the inode links to all the metadata.
This strut also defines a single entry rather than the entire table because readdir() uses a directory stream from opendir().

### Linux File Permissions

Before we get into how to handle files on Linux, we need to understand how permissions work on Linux.
Since Linux uses a multi-user file system, the OS needs to have some way of enforcing its rules.
Permissions are the main way this is done, and it is a core security principle.
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

Here the permissions are given in symbolic mode with the `rwxrw-r--` string with the owning user as Jimbo and the owning group as Office.
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
This form of setting the mode is known as the absolute mode.
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

#### Root

Root is an exception to the permission system.
Since root users need to be able to alter system state, they can do anything on the system.
This includes changing file ownership, file permissions, zeroing out a storage device, mounting a file system, etc.
Even with a file that has 000 permissions not owned by root, the root user can still read, write, and execute the program with sudo.
It makes sense though since a root user should not be prevented from removing a file and such.
Users can obtain superuser permissions if they are set to have them as specified in the /etc/sudoers file.
Although depending on how permissions are set in sudoers, a user or group could only have certain root commands available.
Root is incredibly dangerous to use all willy-nilly, so only use root only when strictly necessary.
The utmost care should be taken to avoid an attacker creating a root shell allowing them to wreak havoc on the system.
Security involving root becomes a lot more important in the later section about (s/g)uid bits.

#### Owning a File

Now that you can read the permissions, what does it mean to own a file?
Of course the permissions determine what can be done, but what happens if an owner is locked out of their file?
If a file were to have 061 permissions the owner cannot read, write, or execute so are they screwed?
Luckily, they are not because the owning user can alter the permissions of files they own.
So the owning user can simply use `chmod 761 <the file>` to get the permissions back.
The owning user actually has a bit more control over their files since it is in the realm of a file system.
An owning user can conduct these actions to files they own.
- Change file permissions (chmod)
- Change group ownership to groups the owner is in (chgrp)
- Rename (mv)
- Delete (rm)
However, this is assuming the user is able to get to their file.
When directories come into play it can determine if these above operations can even be conducted.

#### Owning a Directory

The permissions of directories really show the importance of understanding that files live within a file system.
Permissions on directories allows for users to organize files into shared or separate segments of the file system.
Now because directories are a special kind of file the permissions behave slightly differently.
Ownership will still abide by the permissions the same way as files it is just applied differently.
As mentioned previously, a directory is a list of entries, so the permissions apply to what can be done to that list.
Read and write is intuitive, but what does the execute bit do?
You may think it acts like the other permissions and determines if executing files in the directory is possible, but that is not the case.
According to the man page for chmod, the +x bit for directories permits searching inside.
For example, to be able to remove or rename files -wx is needed instead of just -w-.
ls as well will need r-x instead of r-- to work properly.
A directory can still have just read and just write, but commands will not work as intended.
You can still use `ls` on a directory with r--, but since -x is what gives the ability to search inside `ls -l` half completes the job.
This is because `ls -l` requires execution privileges to go to inodes inside the dentry list.
As a result, without +x permissions `ls -l` lists files by name, but doesn't show the file info.
What does work with solely r-- is tab completion since that just needs to look at the entry list.
Writing permission will always need execution permissions as the entry table can not be modified without executable permissions.
Notice what the write permission does though.
It changes the directory table, so that means who ever owns the directory with proper permissions can remove files in that directory regardless of the file owner.
If you want to see this behavior the script `./DirectoryPermissions/show_dir_write.sh` will show it.
Note that this script will use `chown` which requires root permissions so expect to type in a password.
Some other behaviors are explained in the table below.
```
/* permissions for owner */
/* remember that these can apply to other ownership too */

700 (rwx------)
Can create, delete, rename, and list files

500 (r-x------)
Can only list directory contents.
can be seen on /etc for everyone permissions

300 (-wx------)
Can only create, delete, and rename files
Can write to known files

100 (--x------)
Can cd into the directory.
```
If you want to have a more comprehensive look at how these permissions affect directories, or if you want to experiment, the script in `./DirectoryPermissions/perms.sh` will be useful for you.
It will show more nuanced permissions like 100, 300, and 400.
I will only go over the 100 permission as that truly shows what executable permissions gives a user for a directory.
A directory with only `--x` only allows a user to `cd` into that directory and that's about it.
However, once the user is in the directory a file's permissions determines what can be done to itself.
Once again, the directory permissions only determine what can be done to the directory's list and not the files inside.
The executable bit on a directory just allows access into dentry list.
This would mean you can cd into the directory and still read, write, or execute a file if the file allows it because the file has its own permissions.
With a special case like `100`, I suppose you could create secret files that aren't discoverable because of this fact.
Not that it would be useful because the permissions would either make it impractical for yourself or a security risk for other ownerships.
Nonetheless, this is how permissions work for directories.
Hopefully now you won't make the mistake of assuming a file can't be deleted if it's owned by a different person because it is the directory owner that determines it.
The exception to this rule is the sticky bit which is talked about later.
To sum up the permission system for directories, the execute bit allows accessibility of the inodes in the dentry list, read allows reading of the dentry list, and write allows changing the dentry list (with +x).

##### Permissions Along Directory Path

//Look into that weird behavior discovered where
//if switching users in current directory the relative path can list a directory with everyone permissions
//but the absolute path to that file denies permission to the file in first place yet relative allows listing

//include a script for how recursive delete will get handled

Now that you understand directory permissions this section will expand on why it was important to know about how it works.
The most notable permission to consider is the write and execute permission since that is what allows changes to the directory path.


```
/home/Jimbo/SomeDir/file.txt

/           (755 root, root)
home        (755 root, root)
Jimbo       (750 Jimbo, Jimbo)
Documents   (755 Jimbo, Jimbo)
file.txt    (664 Jimbo, Jimbo)
```
//Make programs to show this
The entire directory path and their permissions have to allow for a user to access the file they want, and it is used as a way to enforce security.
The easiest way to think about how permissions work for a directory is the think of them as a step.
The file path shows all the steps you will need to take with each step needing to grant you access to move forward.
This example path and permissions in absolute form will be used as an example.

//checking up the tree

##### Sticky Bit

Since the `-wx` permissions on a directory allows for deleting or renaming files for the owner or group the sticky bit was created.
The sticky bit is there to only allow the owner of the file or directory to change or delete their files.

#### Links

Links
They take special care to handle as naive checking will create a security vulnerability.
Links can also then change mid-way through execution if a Look Before you Leap approach is taken.

#### Access Control Lists (ACL)

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

To figure out if a program has a setuid or setguid bit active the `ls -l` can be used.
If the setuid bit is set it will display an 's' or an 'S' in the executable bit position in the permissions string like so `-rwsrwSr--`.
There is a difference in lower case and upper case s.
Since setuid is taking the place of the executable bit, to show that execution privileges are given a lower case s is used while an upper case S shows no execution privileges.
In the example given, the setuid and setguid bit is set, but the group does not have execution privileges set.
The intention of setuid bits is to act as the owning user/group, so an upper case S does not make sense to have.
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
//talk about handling links
//talk about reading a directory as finding the max name length is not consistent

Okay so now we understand what a Linux file is and permissions, so what does this mean for the programmer?
All of this talk to mention 
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

#### Device Files

### File Descriptors and Process Execution

//talk about fd table
//how does fork and exec do with fds
You ever wonder why you still print to the same terminal when you fork two processes?
Well as you now know, standard out is defined as file descriptor 1 in the fd table.
When a process forks or execs this table is inherited, so that same fd is still used.

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
[Inode Linux Man Page](https://www.man7.org/linux/man-pages/man7/inode.7.html)
[Stat (2) Linux Man Page](https://www.man7.org/linux/man-pages/man2/stat.2.html)
[Readdir Linux Man Page](https://www.man7.org/linux/man-pages/man3/readdir.3.html)
