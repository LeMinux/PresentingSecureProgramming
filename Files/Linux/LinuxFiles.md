//See if you can avoid root usage by cheeky purposeful thread unsafe stuff to act like root
## Linux File System

### File Abstraction

Before we can talk about all the aspects of a Linux file system we must discuss what a file is defined as on Linux.
You may have heard the notion that everything is a file on Linux.
Your devices, your memory, your configs, your standard input and output, processes, and mounted file systems are "files".
This is not to say that each one of these components is a logical block on disk.
In fact, Linux actually has a few pseudo-filesystem that exist solely in memory such as /proc and /sys which abstracts processes and the system into files.
This phrase is to say that everything has a common file like interface
Common operations like open(), close(), read(), and write() can be done regardless of what the file is.
Naturally, this means Linux has different kinds of files which are specified in the man page for find shown below.
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

The actual implementation of file operations is abstracted away, and the program just has to worry about handling.
The kernel will handle what drivers are used for the file.
A little peek into how the drivers are specified is under linux/fs.h. (under /usr/src/\[linux header version\]/include/linux/fs.h)
The kernel will define what operations are available with the file_operations struct.
It looks something like this.
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
Here you can see how the common file interface is defined with important notes to open, release (close), read, and write function pointers.

Getting back on track, how does the Linux file system itself handle all the metadata associated with its files?
Well each file on Linux references an index node also known as an inode.
The inode will include necessary metadata like file permissions, link count, data blocks, and ownership.
Usage of `ls -l` or `stat` will reveal information stored in the inode with `stat` being more comprehensive.
All information stored can be found in the stat struct in the stat (2) man page shown below.
```
/* note that the members are not always stored in this order */
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
You may notice though, that there is no name or data blocks inside the inode.
For the name portion, that is handled by directories.
Directories are a list of entries (dentries) that map the file name to its inode.
A singular directory entry is defined in dirent.h and its struct looks like this.
```
struct dirent {
    ino_t          d_ino;       /* Inode number of entry*/
    off_t          d_off;       /* Current position in directory stream. Treat as an opaque value */
    unsigned short d_reclen;    /* Length of this record */
    unsigned char  d_type;      /* Type of file; not supported by all filesystem types */
    char           d_name[256]; /* Null-terminated filename */
};
```
The directory itself has its own inode which is what allows for traversal through the file system.
Relative paths take particular use of this as `.` and `..` make use of the inode in their entry.
As far as the kernel is concerned, it does not need the exact name because the inode uniquely defines a file.
For the data blocks, is not necessary or safe for the programmer to handle them directly.
The information is still stored in the inode it is just not accessible to the user.
The kernel will handle it and the programmer will have to use the read and write syscalls.

#### Inode Creation

Inodes are stored in an array which is created when the file system is made.
This is where they get their name of index node since they are just an index in an array.
Each file system has their own inode table, so this would mean two file systems on /dev/sda1 and /dev/sdb1 would contain different tables.
Since this can lead to two identical inode numbers, the inode number is a combination of the device ID and the inode number.
The inode number is an incrementing 32-bit unsigned number while the device ID is split into a major and minor ID that defines the device type and class.
As a result, inodes can only ever reference files in their file system.
This is important to know for hard links which directly use the inode number.
Once the inode table has been created, its size can not be changed.
Even if there is enough space on disk, if the maximum number of inodes is reach no more files can be created.
The number of inodes in the array is determined by the total size on disk divided by the inode ratio.
The inode ratio means to create an inode every n bytes, so a ratio of 10,000 would create 1 inode every 10,000 bytes.
the ratio should not be lower than the block size as it would create more inodes that could ever be used.
The block size is what defines the smallest unit of work for the file system.
This means a file with a single character takes up a block size of space, but also when more space is allocated it will be in a block size.
This becomes more important in the ext sections.
Once the number of inodes has been determined the size of the inode array is affected by the size of a single inode.
A larger inode would create the potential for larger files, but it would come at the cost of less overall data that can be stored.
All these variables for the file system can be found under `/etc/mke2fs.conf`
These settings can be altered when using the `mkfs.xxx` command, but generally the default settings should not be changed.

### Different File Systems

#### Ext2 & Ext3

In the Ext 2 and 3 file systems a variety of pointers that point to data blocks on disk are stored in the inode.
Depending on how large a file gets, different levels of indirection is used to keep the inode itself smaller.
The levels go from direct -> one level -> two levels -> three levels of indirection with each indirection level pointing to a table of pointers.
This does not compress how much space is used in the file system because it's just moving around where the chunks of pointers would be.
Instead of having 100 contiguous direct blocks pointers creating a very large inode it leaves some direct pointers, but then uses the space of one pointer to contain many other pointers.
This way the inode is a well-defined size, but still contains room for dynamic sizing.
How many pointers and indirection exists depends on the file system.
Typically, there are 12 direct blocks with 1 pointer each for the different levels of indirection.
Although, how many pointers there are per indirection table also depends on the block size.
For a 64-bit system (8 byte pointers) and a block size of 512 bytes it would mean a single table could hold 64 pointers.
This helps keep the inodes a fixed reliable size while having the benefits of maintaining larger files.
Once file sizes go past direct blocks the data is instead stored in tables containing pointers.
You can think of each level of indirection as how many tables the system has to go through first.
So for three levels of indirection the system would have to go through three tables before getting to the pointer to the file block.
The graphic I made below shows how the different levels would behave.

```
|----|            |----|             |----|            |----|
| &f | -> block   |    |             |    |            |    |
| &p | ---one---> | &f | -> block    |    |            |    |
| &p | ---two---> | &p | ---two--->  | &f | -> block   |    |
| &p | --three--> | &p | --three-->  | &p | --three--> | &f | -> block
|----|            |----|             |----|            |----|

```
With all this information, an inode for an ext2 or ext3 file system would look more like the table below.

| Inode Structure              |
| :--------------------------: |
| Attributes (stat struct)     |
| Direct blocks (12)           |
| One indirection blocks (1)   |
| Two Indirection blocks (1)   |
| Three Indirection blocks (1) |

#### Ext4

Ext4 is currently the default file system used when you create a new Linux machine.
Ext4 did originally start out as an extension for ext3 meant to be backwards compatible, but fears of stability resulted in a fork of the ext3 code.
This way existing ext3 users did not have to worry about changes to the existing system.
Ext4 is backwards compatible with ext3 and ext2, but ext3 is only partially forwards compatible.
This is because ext4 uses extents which is a range of contiguous blocks.
With the ext4 system, fragmentation is heavily avoided and tries to keep everything in a block.

| Inode Structure              |
| :--------------------------: |
| Attributes (stat struct)     |
| Direct blocks (12)           |
| One indirection blocks (1)   |
| Two Indirection blocks (1)   |
| Three Indirection blocks (1) |


### Linux Files

#### Linux File Permissions

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
Groups ownership also has some extent of control, but they cannot change permissions or ownership.
However, this is assuming the user or group is able to get to their file.
When directories come into play it can determine if these above operations can even be conducted.

#### Owning a Directory

The permissions of directories really show the importance of understanding that files live within a file system.
Permissions on directories allows for users to organize files into shared or separate segments of the file system.
Now because directories are a special kind of file the permissions behave slightly differently.
Ownership will still abide by the permissions the same way as files, but what the permissions do is different.
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
It will show more nuanced permissions like 100, 200, and 400.
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

#### Permissions Along Directory Path

Now that you understand directory permissions, this section will expand more about it.
With all these permissions covered it is pretty annoying having to conduct constant permission checks for the sake of security.
Luckily directories are here to help with their own permissions, so they can be used as a way to check for security once.
It may be necessary in certain situations, such as storing sensitive data, to check the entire directory tree with the path given to ensure it is secure.
This would involve validating each step determining that only the owner (and root users) can modify the directory path.
It is not as simple as checking solely the parent directory for permissions because write permissions (with exec) grants access to moving and deleting files anywhere along the path.
The concern here though is not so much deleting the file because `rm -r` would require directories below to agree on permissions.
Be aware of partial deletion however as `rm -r` will delete everything it can.
The larger concern is with moving files which can be seen with the script in `./DirectoryPermissions/show_dir_move.sh`.
This script will require root permissions to run since it is using chown to root:root a directory.
This script will show even if a subdirectory is owned by root it is the current directory's permissions that determines its own inode table so the root subdir can be renamed.
This may not be the most damaging vulnerability, but it would be enough to brick a program that depends on a certain file.
Then again the extent of a vulnerability depends on if it could be exploited, so there could be a situation where a malicious user redirects sensitive files into a directory they control.

#### Sticky Bit

Since the `-wx` permissions on a directory allows for deleting or renaming files for the owner or group the sticky bit was created.
The sticky bit is there to only allow the owner of the file or directory to change or delete their files.

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

#### Links

//some intro here

##### Soft links

Soft links are a file with an inode that holds arbitrary text information that can be created by `ln -s <target> <name of link>`.
The reason I say arbitrary text data is because the target for the symlink does not need to exist.
A command like `ln -s aehtihaeithaeiht my_soft_link` is perfectly valid and will just create a broken link.
Typically, the text information holds a path to another file which can be relative or absolute, but it can hold any text data.
Additionally, a user does not even need the permissions of the target file to create a symbolic link.
This is because the symlink is its own file with an inode, so a symlink can be created as long as the directory it's created in allows it.
Permissions are checked once the OS tries to open the file that the link points to, but the link can have its own permissions.
The permissions on the link itself just determine who can resolve the link, but they typically have 777.
It is these properties that make soft links very versatile.
Symlinks can link to directory, files, devices, or basically anything that can be found via a file path.
A few examples are /etc/resolv.conf linking to a systemd file and /bin and /sbin linking to /usr/bin and /usr/sbin/.
This may sound kind of like a Windows shortcut, but soft links do not behave in this manner.
They are not as simple as setting your working directory to its contents.
When a soft link is resolved it bases the resolution off its parent directory.
This is what allows for relative paths inside a soft link.
Additionally, paths are relative to the link, a link in /home/Jimbo/Documents/my_link points to /etc/systemd/system/
when the user cds into my_link they can cd .. back into Jimbo's documents rather than /etc/systemd.
The user is in /home/Jimbo/Documents/my_link/ that is secretly /etc/systemd/system/.
It is basically like creating a new path to traverse.
However, since symlinks are just a file that has a path they are highly susceptible to breaking.
Deleting or moving the linked file or the link itself can result in a broken link.
It is suggested to use an absolute path for links so that they can be moved around.
They do provide advantages over hard links like
-   Ability to link across file systems
-   Can point to directories and other file objects


##### Hard links

On the other hand there are hard links.
The command to create a hard link is `ln <target> <name of link>` which is the default behavior of ln.
Hard links link to the actual inode structure of a file, but you also have to remember how Linux uses directories to get the inode from a name.
What a hard link does is insert itself into the directory entry table.
You are not creating a separate file because an additional inode is not created.
You are creating two file paths that link to the same inode structure and thus the same data.
In fact the special `.` and `..` entries in each dentry are hard links.
The `.` is a hard link to the current directory's inode, and `..` is a hard link to the parent directory's inode.
Running the `./Links/special_dir.sh` script will show this which I have added some color coding to.
This is what allows for relative traversal in the file system avoiding the need to constantly pwd to get your absolute path.
In effect, a hard link is basically indistinguishable from the original file unless you were to look at logs.
The only way to know if hard links are present would be the hard link counter in the inode structure.
This counter is important because a file's data block is only deleted if the hard link counter reaches zero.
This means all hard links must be deleted to delete a file on Linux.
There isn't much of an elegant solution other than scanning the entire file system for a specific inode.
The find command with `find / -samefile <file>` or `find / -inum <inode num>` can be used, but the find man page suggests to use `-samefile`.
However, hidden files can occur if a process has a file open, but the name portion is removed from the directory entry with unlink.
At this point the file would only close if the last file descriptor closes the file.

However, hardlinks have restrictions.
-   A hardlink can only link to inodes on the same file system since the inode itself is partly made of the device id.
-   The target file must also exist otherwise there is no inode to link.
-   Directories can't be hard linked normally to maintain an acyclic tree.

You can hard link to a soft link since a soft link is its own separate file.

##### Link Security

Symbolic links are an interesting case when it comes to security.
Any time you have to deal with files you have to ask yourself if symbolic links are a reasonable concern.
This is because a symbolic link can allow for arbitrary writing, reading, deleting, or permission changes.
Links are part of a class of vulnerabilities that have been used to take control of a system or harm the system in other ways.
Mainly, the problem is with symbolic links, but hard links have been used as well.
Programs that solely check for just the filename will fall victim to TOUCOU (Time of Check vs Time Of Use) vulnerabilities since the link can change where it goes by the time it is used.
This is why it is preferable to simply try to open the file right then and there since you know you'll need it later anyway.
If a user normally couldn't open some file then a link to that file doesn't change the fact it can't be opened.
A privileged process would want to lower permissions to the real user before attempting to open a file.
The user Jimbo is able to create a link to `/etc/shadow` despite `/etc/shadow` having 640 root:root permissions, but if a setuid program doesn't check Jimbo's permissions he may write to /etc/shadow.
Mainly the concerns for symlinks occur when a process has elevated privileges, or an insecure directory allows for other files to be manipulated.
For this reason, some programs may decide to not dereference links, and will fail if they find it.
//add more 

### File Descriptors

//talk about file descriptor
//talk about /proc
    //proc has its own fds per process stored in /proc/<PID>/fd/
//talk about stdin, stdout, stderr
//talk about how stdout can be different
//talk about fds returnign the smallest number it is not incremental
//mention redirecting any file descriptor
//talk about handling links
//talk about reading a directory as finding the max name length is not consistent
//talk about difference in fopen and open (buffering vs non-buffering)
//talk about avoiding race conditions with fds

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

Secure Coding in C and C++ by Robert C. Seacord

[Inode Linux Man Page](https://www.man7.org/linux/man-pages/man7/inode.7.html)

[Stat (2) Linux Man Page](https://www.man7.org/linux/man-pages/man2/stat.2.html)

[Readdir Linux Man Page](https://www.man7.org/linux/man-pages/man3/readdir.3.html)

[Oracle mkfs.ext4 Blog](https://blogs.oracle.com/linux/post/mkfsext4-what-it-actually-creates)

[Linux Kernel Index Nodes](https://www.kernel.org/doc/html/latest/filesystems/ext4/inodes.html)

[Hard vs Soft Links](https://linuxgazette.net/105/pitcher.html)

[Understand Linux Links](https://www.linux.com/topic/desktop/understanding-linux-links/)
