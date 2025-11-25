//Include soemthing about directory caching
//include memfd:
//say what happens in ram when you open a file

## Linux Files

### File Abstraction

Before we can talk about all the aspects of handling files on Linux we must define what a file is.
If you have read the file system section then you already know this, but for those who haven't a file on Linux is an inode.
Inodes hold all the metadata for a file such as permissions, owner, groups, and more.
Essentially this is just an incremental number that is an index to a specific file for a specific file system.
You may have heard the notion that everything is a file on Linux, and it is the inode that helps in that.
Your devices, your memory, your configs, your standard input/output, processes, and mounted file systems are "files".
This is not to say that each one of these components is a logical block on disk.
In fact, some file like objects aren't even on the disk and only exist in memory.
Two notable examples of this is the /proc and /sys directories.
What this phrase really means is that everything on Linux can be treated as a file through a common interface that is the virtual file system (VFS).
File operations like opening, closing, reading, and writing can be done regardless of what the file is because the implementation of file operations is abstracted away.
This way of treating file objects greatly simplifies using the operating system, and it is why piping and redirection just works.
One issue with this abstraction is that saying something is a file is a broad term.
As an example, some files can directly manipulate hardware components like the brightness of your screen similar to this command `echo 50 > /sys/class/backlight/<what ever device>` which would set the brightness to 50% normally.
A user can also zero out their entire drive with dd if they copy and pasted a command not knowing that /dev/sda1 was the representation of their drive.
Applications and users need to understand what they are dealing because this amount of control can lead to costly consequences.
Naturally, this means Linux has different types of files which are
- regular files
- directory files
- block special files      (hardware devices)
- character special files  (hardware devices)
- links
- sockets
- pipes
- door (Solaris)

So even though the humble inode is a simple fella, it is important to understand the information it holds and how it is used.
This information can be revealed to you via the `stat` command or the `ls` command with the `-l` flag.
The relevant information given to you is listed below.
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
    /* file system block info */

    /* time members */
};
```

You may notice there is no member for the name of the file, and this is because the name is completely separate from the inode.
Resolving the name to the inode is handled by directories which is talked about later.

#### Linux File Permissions

Before we get into how to handle files on Linux, we need to understand how permissions work on Linux.
Any multi-user system needs to have a way to enforce rules via permissions since we can't just give everyone root.
It would be a pretty crummy system to give everyone root permissions and pray someone doesn't use rm incorrectly.
Simple program probably won't care so much about permissions and want to simply open a file, but root programs should care.
It is important not just for finding out if a file is operable, but also how to correctly set and determine permissions securely.
If we look back at the stat structure the permissions and file type are stored in st_mode.
If you ever wondered why the chmod command is called change mode instead of change permissions this is why.
The way the mode is read is with bit masking following this table

| Hex Value | Tag       | Description         |
| :-------: | :-------: | :-----------------: |
| 0x1       | S_IXOTH   | World/Other Execute |
| 0x2       | S_IWOTH   | World/Other Write   |
| 0x4       | S_IROTH   | World/Other Read    |
| 0x8       | S_IXGRP   | Group Execute       |
| 0x10      | S_IWGRP   | Group Write         |
| 0x20      | S_IRGRP   | Group Read          |
| 0x40      | S_IXUSR   | Owner Execute       |
| 0x80      | S_IWUSR   | Owner Write         |
| 0x100     | S_IRUSR   | Owner Read          |
| 0x200     | S_ISVTX   | Sticky Bit          |
| 0x400     | S_ISGID   | Set GID             |
| 0x800     | S_ISUID   | Set UID             |
| 0x1000    | S_IFIFO   | FIFO                |
| 0x2000    | S_IFCHR   | Character Device    |
| 0x4000    | S_IFDIR   | Directory           |
| 0x6000    | S_IFBLK   | Block Device        |
| 0x8000    | S_IFREG   | Regular File        |
| 0xA000    | S_IFLNK   | Symbolic Link       |
| 0xC000    | S_IFSOCK  | Socket              |

Using this table, a mode of 0x8664 would mean a regular file with read and write for the owner and group and only read for others.
Permissions do have a precedence from owner -> group -> other.
A mode of 0x8646 or would mean the group can only read despite others having read and write.
Using this form of the mode isn't the most user-friendly way of displaying, but you probably recognize the mode from the ls command with -l.
Something like `-rwxrw-r--  1 Jimbo Office   148 Jun  7 17:30  bigsleep.c`.
The table below shows what each segment means.
| File Type | Permission String | Number of Hard Links | Owning User | Owning Group | File Size | Last Modification Date | Filename |
| :--------:| :---------------: | :------------------: |:---------: | :----------: | :-------: | :--------------------: | :------: |
| - | rwxrw-r-- | 1 | Jimbo | Office | 148 | Jun 7 17:30 | bigsleep.c |

Here the permissions are given in their symbolic mode of `rwxrw-r--` with the leading `-` signifying a regular file.
Below are some more example of what different symbolic forms mean.
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
The syntax that the /etc/sudoers file follows is ``
Root is incredibly dangerous to use all willy-nilly, so only use root only when strictly necessary.
The utmost care should be taken to avoid an attacker creating a root shell allowing them to wreak havoc on the system.
Security involving root becomes a lot more important in the later section about (s/g)uid bits.

#### Owning a File

You may have notice though that the mode does not contain the owner or group.
These are separate inode members stored in the st_uid and st_gid members of the stat struct.
Of course, the permissions determine what can be done and are pretty self explanitory.
Reading allows usage of commands like cat on the file.
Writing allows modifying the contents of the file.
Executing allows attempting to execute a file if it can be interpreted as something executable.
However, what happens if an owner is locked out of their file?
If a file were to have 061 permissions the owner cannot read, write, or execute so are they screwed?
Luckily, they are not because the owning user can alter the permissions of files they own.
So the owning user can simply use `chmod 761 <the file>` to get their permissions back.
The owning user actually has a bit more control over their files.
An owning user can conduct these actions to files they own.
- Change file permissions (chmod)
- Change group ownership to groups the owner is in (chgrp)
- Rename (mv)
- Delete (rm)

Groups ownership also has some extent of control, but they cannot change permissions or ownership.
What can not be changed normally is the file type even if it is part of the mode.
To change a file to a directory or a directory to a file it would require changing the file system directly.
It is possible as this Ask Ubuntu post shows [Convering a file to directory](https://askubuntu.com/questions/626634/converting-a-file-to-directory), but it's not practical.
Continuing on with what can be changed in the mode we have only considered a file all by itself.
A Linux file system has directories with their own permissions which have their own behavior
When directories come into play it can determine if these above operations can even be conducted in the first place.

### Linux Directories

Directories are files that hold directory entries, also known as dentries, that map file names to their inode.
Think of it like looking through a phone book that maps the phone number to a person which is also why it can be called a telephone directory.
This implementation is why Linux people prefer to say directories instead of folders since it is a mapping rather than a collection.
Or they just called them directories because that's what everyone else says, and they don't want to get clowned.
Now, it's not like directories hold an entire path like `/var/log/auth.log`.
If this was the case you can probably image how gargantuan the root directory would be if it was holding every single full path name.
Instead, each directory along the way holds the individual file name with the inode to follow.
If we look at a path like `/home/Jimbo/Documents/ACK.png` the traversal looks like this.

```
(    / (2)   )   (  home (20)  )   (     Jimbo (90)   )   (  Documents (114)  )
|------------|   |-------------|   |------------------|   |-------------------|
| home -> 20 |-> | Jimbo -> 90 |-> | Downloads -> 100 |   | report.ods -> 528 |
| usr -> 30  |   | Timbo -> 73 |   | Documents -> 114 |-> | book.pdf -> 739   |
| bin -> 40  |   | Limbo -> 39 |   | Pictures  -> 234 |   | ACK.png -> 300    |-> inode of ACK.png
|------------|   |-------------|   |------------------|   |-------------------|
```

Here you can see how traversal is recursively looking inside each entry.
If we were to traverse a path like `/home/Jimbo/AHHHHHH` the traversal would fail in `Jimbo` since that doesn't have an `AHHHHHH` entry.
This traversal is simple, but it is very annoying for the programmer to get the full path if it wasn't provided.
In order to construct the full path one would have to go through each directory and glue together the entry file names as they go.
The structures for dentries reflect this.

Table for struct ext4_dir_entry
| Member   | Size      | Description |
| :------: | :-------: | :--------------------------------------------: |
| inode    | 4 bytes   | Inode number pointed to by dentry              |
| rec_len  | 2 bytes   | Length of the dentry record in a multiple of 4 |
| name_len | 2 bytes   | Length of the file's name                      |
| name     | 255 bytes | File name as a character array                 |

Table for struct ext4_dir_entry_2
| Member   | Size      | Description |
| :------: | :-------: | :--------------------------------------------: |
| inode    | 4 bytes   | Inode number pointed to by dentry              |
| rec_len  | 2 bytes   | Length of the dentry record in a multiple of 4 |
| name_len | 1 byte    | Length of the file's name                      |
| file_type| 1 byte    | File type code                                 |
| name     | 255 bytes | File name as a character array                 |

The C dirent structure.
```
struct dirent {
    ino_t          d_ino;       /* inode number */
    off_t          d_off;       /* offset to the next dirent */
    unsigned short d_reclen;    /* length of this record */
    unsigned char  d_type;      /* type of file; not supported by all file system types */
    char           d_name[256]; /* filename; name is 255 bytes, but C needs the nul byte so 256 */
};
```

These structures only hold enough space for the filename of that entry which is set to a max of 255 characters.
You may wonder what the maximum size for an entire path may be, but that size isn't exactly well-defined.
Technically there isn't a limit, but an imposed limit of 4096 bytes is typically used.
That's what's normally seen under PATH_MAX in limits.h, but PATH_MAX isn't guaranteed to be defined.
Continuing on, these structures reflect how directories are stored on disk at least by default.
The default way to store directories on Linux is through linear/classic directories.
They are called linear directories since they store entries as an array inside data blocks.
The series of data blocks themselves are not linear because the file system can't guarantee that.
The default structure used inside classic directories is the ext4_dir_entry_2.
If there isn't a file type feature flag set then the entries will be ext4_dir_entry.
Remember that filesystems works in block sizes, so a directory that only has one entry takes up one entire block in the data blocks.
This is why your directory files say they take up 4096 bytes (the default block size) when you use ls -l.
When more space is required more blocks are added.
As an example my /etc directory says it takes up 12288 bytes which is 3 blocks of 4096.
However, there is a quirk with directories.
They don't downsize to avoid fragmentation, so if you were to remove all the entries in a data block the data block will not be reclaimed.
The only way to reclaim the space would be to delete and recreate the directory.
The ext4_dir_entry structs from above can take up 263 bytes, but they normally don't take up that space.
The entries will only take up as much space as needed, so they can only be at most 263 bytes if the file name is 255 bytes.
As an example, a file name of "cheese" will simply take up 6 bytes for the name instead of 6 bytes and 249 empty bytes.

Most directories won't take up an entire block size, so unused entries are marked with an inode of 0 since 0 can't exist.
For cases where the directory is encrypted another struct is appended after the name member that includes hash information.
This extra entry is called ext4_extended_dir_entry_2 and is included in the rec_len which can make the record length up to 271 bytes.

//Something about tails

The values in the directory are not stored alphabetically.
```
00480014 02090014 65756c62 746f6f74 00000068
```
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
This is because `ls -l` requires execution privileges to look at the inodes inside the dentry list.
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
Using this fact allows you to determine how many direct subdirectories there are since all the lower directory `..` will point to the inode of the parent.
This means if a directory has 36 hardlinks to it it has at least 36 subdirectories.
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

#### File Descriptors

Since the VFS is an interface for the userspace it has to return something for users to use.
It is through the VFS system that gives file descriptors which is quite literally an index into a table.
This table is known as the open file table which exists per process for files that it opens.
This behavior is why some people say "everything is a file descriptor" although not completely wrong it misses the abstraction of the VFS that created it in the first place.

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

[Anatomy of the Linux File System](https://developer.ibm.com/tutorials/l-linux-filesystem/)

[Inode Linux Man Page](https://www.man7.org/linux/man-pages/man7/inode.7.html)

[Stat (2) Linux Man Page](https://www.man7.org/linux/man-pages/man2/stat.2.html)

[Readdir Linux Man Page](https://www.man7.org/linux/man-pages/man3/readdir.3.html)

[Oracle mkfs.ext4 Blog](https://blogs.oracle.com/linux/post/mkfsext4-what-it-actually-creates)

[Linux Docs Kernel Index Nodes](https://www.kernel.org/doc/html/latest/filesystems/ext4/inodes.html)

[Linux Docs Block Groups](https://docs.kernel.org/filesystems/ext4/blockgroup.html)

[Linux Docs Virtual Filesystem](https://docs.kernel.org/filesystems/vfs.html)

[Hard vs Soft Links](https://linuxgazette.net/105/pitcher.html)

[Understand Linux Links](https://www.linux.com/topic/desktop/understanding-linux-links/)

[Understanding Ext4 Layout](https://blogs.oracle.com/linux/post/understanding-ext4-disk-layout-part-1)

[Understanding Ext4 Layout Part 2](https://blogs.oracle.com/linux/post/understanding-ext4-disk-layout-part-2)

[Ext4 Extents](https://blogs.oracle.com/linux/post/extents-and-extent-allocation-in-ext4)

