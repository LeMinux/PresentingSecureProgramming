//Include soemthing about directory caching
## Linux File System

### File Abstraction

Before we can talk about all the aspects of a Linux file system we must discuss what a file is defined as on Linux.
You may have heard the notion that everything is a file on Linux.
Your devices, your memory, your configs, your standard input/output, processes, and mounted file systems are "files".
This is not to say that each one of these components is a logical block on disk.
Some components are actually in memory accessible through a pseudo-filesystem such as /proc/ and /sys/.
What this phrase really means is that everything on Linux can be treated as a file through a common interface.
Common operations like open(), close(), read(), and write() can be done regardless of what the file is.
Naturally, this means Linux has different types of files which are
- regular files
- directory files
- block special files      (hardware devices)
- character special files  (hardware devices)
- links
- sockets
- pipes
- door (Solaris)

The actual implementation of file operations is abstracted away, and the program just has to worry about handling data it gets.
The kernel will handle what drivers are used for the file.
A little peek behind the abstraction is specified under linux/fs.h. (under /usr/src/\<linux header version\>/include/linux/fs.h)
What is defined in the file_operations struct determines how a file is handled.
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
Here you can see how the file interface is defined with important notes to open, release (close), read, and write function pointers.
However, this file_operations struct only defines how to handle certain operations for a file.
There is no definition for permissions, ownership, data location, path traversal, and other metadata about the file.
This is where we have to prepare to dive in deep.
Even though the concept is quite simple, the way everything interacts with it makes for quite the lengthy chapter.
This concept that is the core of everything in the Linux filesystem is the humble little inode.

### Inodes

#### Inode Contents

An inode is what holds all the metadata for files on Linux.
This is what holds the file type, permissions, location to data blocks, and other information.
Usage of `ls -l` or `stat` will reveal some information stored in the inode with `stat` being more comprehensive.
The stat struct found in stat (2) shows the information it can reveal.
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

The important attributes will be referenced later, but you may notice there is nothing for a name.
This is because directories handle the translation from the name to the inode.
Directories are files that hold directory entries, also known as dentries or dcaches, that map file path names to their inode.
Think of it like looking through a phone book that maps the phone number to a person which is also why it can be called a telephone directory.
This is the reason why Linux tends to call them directories instead of folders since it is a mapping.
Now, it's not like the directory holds an entire path, but more a section of that path.
If we look at the path of `/home/Jimbo/Documents/ACK.png` the traversal looks like this.
```
(    / (2)   )   (  home (20)  )   (     Jimbo (90)   )   (  Documents (114)  )
|------------|   |-------------|   |------------------|   |-------------------|
| home -> 20 |-> | Jimbo -> 90 |-> | Downloads -> 100 |   | report.ods -> 528 |
| usr -> 30  |   | Timbo -> 73 |   | Documents -> 114 |-> | book.pdf -> 739   |
| bin -> 40  |   | Limbo -> 39 |   | Pictures  -> 234 |   | ACK.png -> 300    |-> inode of ACK.png
|------------|   |-------------|   |------------------|   |-------------------|
```
Here each entry has the name and some arbitrary inode number it's associated with.
As you can see, it steps through each dentry to find the inodes along the path.
A singular entry in the dentry would look something like this as defined in dirent.h
```
struct dirent {
    ino_t          d_ino;       /* Inode number of entry*/
    off_t          d_off;       /* Current position in directory stream. Treat as an opaque value */
    unsigned short d_reclen;    /* Length of this record */
    unsigned char  d_type;      /* Type of file; not supported by all filesystem types */
    char           d_name[256]; /* Null-terminated filename */
};
```

### Different File Systems

#### Common EXT Features

The extended file system (ext) takes its influence from the BSD Fast Filesystem where it used cylinder groups for hard disk drives.
Back then, the main mass storage devices were hard disk drives that had physically spinning disks and an actuator arm.
In order to get the best performance you had to minimize movement of the actuator arm to avoid thrashing as well as avoid fragmentation by having data scattered around.
The solution for this problem was to group data into cylinder groups to keep reads closer.
Now with SSDs the issues of figuring out read patterns and thrashing isn't much of an issue, but the system created then persists to today.
The ext file system is a system of many cylinder groups, which are called block groups, with a general layout.
A high level look at how each block group is laid out is shown in the table below.

| Padding | Superblock | Group Descriptors | Reserved GDT Blocks | Block Bitmap   | Inode Bitmap | Inode Table | Data Blocks|
| :-----: | :--------: | :---------------: |:------------------: | :------------: |:-----------: | :---------: | :--------: |

The ordering shown is not guaranteed, but the superblock and group descriptors are the first 2 groups if they are present.
Each version of ext will have some variation on the individual structure of these segments such as Ext 4's own definition for inode and superblock structures.
The more specific differences will be mentioned in their own sections later.
Each of these block groups are sized to contain at least `8 * block size` blocks.
If you do not know what a block size is it defines the smallest unit of work for the file system.
Typically, the default blocksize is 4096 bytes (4 KiB), so this means units of work are done in 4 KiB.
This means a file with a single character takes up 4 KiB of disk space, but also when more space is allocated it will be in a block size.
Continuing on with the equation, this would mean a block group would contain 32,768 blocks.
The size of each block group would then be the `number of blocks per group * block size`.
With the default settings for the block count the size of a block group would be 128 mebibytes.
Then you can get how many block groups will be in the system by taking the `file system size / size of each block group`.
The table below summarizes these formulas.

| Formula                                     | What For                 |
| :-----------------------------------------: | :----------------------: |
| 8 * block size                              | Blocks per group         |
| # blocks per group * block size             | size of each block group |
| file system size / size of each block group | # of block groups        |

This kernel docs link will also show other values based on block size [Kernel Docs Blocks](https://docs.kernel.org/filesystems/ext4/blocks.html).

Each block group will have a group descriptor, block bitmap, inode bitmap, and an inode table.
This means if there are 12 block groups then there are also 12 of each of these segments as well.
The way these block groups are stored is not directly next to each other.
These separate groups are more so linked together while remaining in their own segments.
The inode bitmap will be stored with other inode bitmaps, and the inode table is stored with other inode tables, so a layout looks more like the graphic below.
The graphic doesn't accurately show how block size plays a part just how stuff is laid out.

```
-----------------------
|       padding       |
|     super block     |
|     free space      |
|     free space      |
|                     |
|   0th Group desc.   |
|   1th Group desc.   |
|   ...............   |
|   nth Group desc.   |
|                     |
|   Reserved blocks   |
|   Reserved blocks   |
|   Reserved blocks   |
|                     |
|  0th group bit map  |
|  1th group bit map  |
|  .................  |
|  nth group bit map  |
|                     |
|  0th inode bit map  |
|  1th inode bit map  |
|  .................  |
|  nth inode bit map  |
|                     |
| inode table for 0th |
| inode table for 1th |
| .................   |
| inode table for nth |
|                     |
|     Data blocks     |
-----------------------
```

#### Padding

The padding only exists before the first superblock to allow for the x86 boot sectors and other things.
The padding is 1024 bytes which means the superblock, and thus group 0, is offset by 1024 bytes.
If the block size is 1024 bytes then what would be group 0 is not used and the superblock moves to group 1.
None of the other group blocks have padding before them.

#### Superblock

The superblock is essentially the metadata for the file system itself.
While an inode is the metadata for a singular file, the superblock is what the file system uses to keep track on how to conduct its actions.
Typically, the filesystem will only use the superblock in the first group, but many backups are stored in case of corruption.
This superblock is incredibly important because if it gets corrupted then the OS won't be able to handle files properly, or it may act in a misconfigured manner.
The default behavior is to set the sparse_super flag which will store a backup of the superblock on specific group numbers.
These numbers are 0 and 1 and then numbers in the power of 3, 5, or 7.
If this flag is not set it will store a backup of the superblock in every group which can be costly for disk space.
Information about the super block can be revealed using `dumpe2fs <device>`; however, be warned that it will reveal **A TON** of information.
You probably only want the first 60 lines so using head like so `dumpe2fs <device> | head -n 60` is more preferable.
The dumpe2fs command will require sudo to run as well.
The first 30 lines contains information like the OS type, block size, error behavior, inode count, block count, reserved block count, blocks per group, etc.
It even contains the number of times the system has been mounted before it has been checked.
After the first 30 lines it shows every block group which will explode your terminal with text hence the suggestion for the head command.
If you want to know where your superblock backups are located `dumpe2fs <device> | grep "superblock"` will reveal that.
The backups may not be the most up to date because they are only ever updated if the filesystem itself is changed.
Resizing or tuning the filesystem would cause these backups to change.

#### Group Descriptors

The block group descriptors store information for their block group.
The group descriptors store information on where to find that block group's free inodes, free blocks, and block bitmaps.
The Group descriptors are stored in the Group Descriptor Table (GDT) which holds all the group descriptors.
The GDT will be immediately follow superblocks, and it will also have backups stored.
The backup behavior is just like that of the superblock depending on if sparse_super is set or not.

#### Reserved GDT Blocks

The reserved GDT blocks is the space between the GDT table and the block bitmaps.
This space is kept for future expansion of the file system.
The default settings allow for the file system to use this space to grow up to 1024 times the original file system size.
This is the original file system size by the way, so don't expect your drive to grow 1024 times.

#### Block Bitmap

The block bitmap tracks what blocks are used for that block group.
The location is not fixed, so the group descriptor has a pointer to its location.
Each bit represents a block indicating if it's used or not.
The size of the bitmap is one block, so if we use 4096 bytes as the block size the bitmap is able to indicate 32,768 blocks of 4096 bytes.
This would mean if every block for that group is set 134,217,728 bytes or 128 mebibytes have been used.
These are the same numbers we have calculated at the beginning.

#### Inode Bitmap

The inode bitmap functions similarly to the block bitmap.
It just represents what inodes are for the inode table rather than group blocks.
This also is contained within one block size, so 4096 bytes could represent 32,768 inodes.

#### Inode Table

The inode table is what holds all the inodes (the metadata for your files).
This is where the name for the inode comes from since it is just an index to a node in an array.
Since space is limited there can only be so many inodes defined.
This means the maximum number of files you can create is your inode count.
For normal users you will probably run out of space before that happens, but knowing this fact can lead to a unique DOS attacks if a server doesn't close their files.
The number of inodes created is defined by the `filesystem size divided by the inode ratio`.
The inode ratio says to create an inode for every number of bytes, so if the ratio was 33,333 it would create an inode for every 33,333 bytes.
The ratio should not be lower than the block size as it would create more inodes that could ever be used.


The default inode_ratio is 16,385 bytes which creates 65,536 inodes for every Gibibyte which is just above the max value of an unsigned short.
Each group then has its own inode table which is sized to have the `total inode count / how many block groups` there are.
If we have a max inode count of 65,656 with 8 block groups and a file system of 1 gibibyte then there will be 8,192 inodes per group.
The inode table then must contain all those inodes, so the size of the inode table is the `inode size * number of inodes per group`.

So now we know how to size the table and how many inodes we have.
The next step is to figure out how to get to that index.
The inode table isn't stored at the very beginning like the superblock, and each group has their own table.
So the inode table is not stored as a massive continuous block as you may think, but it is rather continuous segments per group block.
Luckily the formulas for getting the inode are pretty easy since it involves getting the group and then the offset to the inode.
The formula for finding out what block group an inode belongs to is `(inode_number - 1) / # inodes per group`.
Keep in mind this will conduct integer division, so the answer will be floored.
Once the group number is obtained it will look into its group descriptor to find the inode table.
Then formula to get to the inode itself is `(inode_number - 1) % # of inodes_per_group`.
You may notice in these formulas it is subtracting one.
As a result there can't exist an inode of zero otherwise it would turn into -1.

| Formula                                     | What For                  |
| :-----------------------------------------: | :-----------------------: |
| file system size / inode ratio              | Total # of inodes         |
| Total # of inodes / # of block groups       | # of inodes in each group |
| # of inodes in each group * inode size      | Inode table size          |
| (inode_number - 1) / # inodes per group     | Block group of an inode   |
| (inode_number - 1) % # of inodes_per_group  | Offset into inode table   |

A problem does present itself though.
How would the file system handle a case where there are two mounted Linux file systems that want to access an inode?
An inode is just an index, so what happens if they want to access the same inode number?
Luckily this has been thought about.
The inode number is a combination of the device ID and the inode number.
This way the inode remains an incrementing 32-bit unsigned number while the device ID is split into a major and minor ID that defines the device's type and class.
As a result, inodes can only ever reference files in their file system, and why st_dev is in the stat struct.

#### Data Blocks

The data blocks are what's left for the file system to use after it has created itself.
This is where the data for your files will be stored and where your inodes will point to.
Other features like journaling will also be used in the data blocks as it is just a normal file.

#### Ext2 & Ext3

For the most part, ext2 and ext3 are the same system, but ext3 is ext2 with journaling.
In fact, an ext 2 system can be upgraded to ext3 by tuning it to enable journaling.
These two systems are succeeded by ext4, but these systems are still used to teach how files are stored.
The group blocks remains the same, but the inode structure is different.
In the Ext 2 and 3 file system the inode holds a variety of pointers that point to data blocks on disk.
Depending on how large a file gets, different levels of indirection get used.
The levels go from direct -> one level -> two levels -> three levels of indirection with each indirection level pointing to a table of pointers.
You can think of each level of indirection as how many tables the system has to go through first before getting to a direct pointer to data.
So for three levels of indirection the system would have to go through three tables before getting to the pointer to the file block.
The graphic below shows how the different levels would behave.

```

Direct pointers

|---|
| 1 | ---> data block
| 2 | ---> data block
| 3 | ---> data block
| 4 | ---> data block
|---|

One level of indirection

              Pointers
               |---|
            -> | 1 | ---> data block
           /   | 2 | ---> data block
          |    | 3 | ---> data block
          |    | 4 | ---> data block
          |    |---|
          |
|---|     |    |---|
| 1 |----/  -> | 1 | ---> data block
| 2 |------/   | 2 | ---> data block
| 3 |-----\    | 3 | ---> data block
|---|     |    | 4 | ---> data block
          |    |---|
          |
           \   |---|
            -> | 1 | ---> data block
               | 2 | ---> data block
               | 3 | ---> data block
               | 4 | ---> data block
               |---|

Two levels of indirection

              Pointers    Pointers
               |---|       |---|
            -> | 1 |-----> | 1 | ---> data block
           /   | 2 |---\   | 2 | ---> data block
          |    | 3 |-\ |   | 3 | ---> data block
          |    |---| | |   | 4 | ---> data block
          |          | |   |---|
          |          | |
|---|     |          | |   |---|
| 1 |----/           | --> | 1 | ---> data block
| 2 |-----\          |     | 2 | ---> data block
| 3 |--\   |         |     | 3 | ---> data block
|---|   |  |         |     | 4 | ---> data block
        |  |         |     |---|
        |  |         |
        v  v         |     |---|
 (to another table)  L---> | 1 | ---> data block
                           | 2 | ---> data block
                           | 3 | ---> data block
                           | 4 | ---> data block
                           |---|

Three levels of indirection

                                                         Pointers
                                                          |---|
              Pointers                                 -> | 1 | ---> data block
               |---|                                  /   | 2 | ---> data block
            -> | 1 |-------> (to another table)      /    | 3 | ---> data block
           /   | 2 |---\                            /     | 4 | ---> data block
          |    | 3 |-\  |                          /      |---|
          |    |---| |  |                         /
          |          |  |                        /        |---|
          |          |  |           Pointers    /     --> | 1 | ---> data block
|----|    |          |  |            |---|     /     /    | 2 | ---> data block
| 1  |---/           |  -----------> | 1 | ---/     /     | 3 | ---> data block
|----|               v               | 2 | ---------      | 4 | ---> data block
                (to another table)   | 3 | ----\          |---|
                                     |---|      \
                                                 \        |---|
                                                  ------> | 1 | ---> data block
                                                          | 2 | ---> data block
                                                          | 3 | ---> data block
                                                          | 4 | ---> data block
                                                          |---|
```

This does not compress how much space is used in the file system because it's just moving around where the chunks of pointers would be.
This behavior helps keep the inode itself a consistent smaller size.
Instead of having 100 contiguous direct blocks or dynamically resizing an inode it leaves some direct pointers, but then uses the space of one pointer to contain many other pointers.
This way there is still dynamic sizing of files, but an easy way to create an array of inodes.
Due to this behavior, the ext3 and ext2 inode is a fixed size of 128 bytes.
How many direction pointers there are depends on the file system version, but the Unix file system has 12 direct blocks with 1 pointer each for the different levels of indirection.
How many pointers there are per indirection table depends on the block size.
For a 64-bit system (8 byte pointers) and a block size of 512 bytes it would mean a single table could hold 64 pointers.
There is one issue with this approach though.
If the inode structure is a consistent size, and only leaves room for the pointers to the tables then where do the tables go?
The indirection tables have no other choice but to be placed into the data blocks which can cause fragmentation.
This would create slower performance, and is a main fault of ext3 as performance significantly drops with higher inode counts.
Additionally, this creates a maximum limit of 2 TiB (with a block size of 4 KiB) since storage is based on the pointers.
With all this information the ext3 inode structure would look like below.

| Inode Structure              |
| :--------------------------: |
| Attributes (stat struct)     |
| Direct blocks                |
| One indirection blocks       |
| Two Indirection blocks       |
| Three Indirection blocks     |

#### Ext4

Ext4 is currently the default file system used when you create a new Linux machine.
Ext4 did originally start out as an extension for ext3 meant to be backwards compatible, but fears of stability resulted in a fork from ext3.
This way existing ext3 users did not have to worry about changes to the existing system.
It's a good thing they did because the ext4 system adds a lot more features that ext3 couldn't support.
Ext4 is backwards compatible with ext3 and ext2 which allows mounting of those systems, but ext3 is only partially forwards compatible with ext4.
This is because ext4 has a different inode structure, superblock structure, and block group behavior.
The inode has a significant change in that instead of storing indirection pointers it uses extents.
With ext2/3 the direction pointers stored every point the file resided in.
For larger files it could quickly take up the space of the 12 direct pointers leading to less efficient indirection pointers.
Extents on the other hand don't store every direct block of the file.
It instead stores the continuous memory of the first and last block.
This way less metadata is needed to represent a file as representing a range has a constant size, and data is represented contiguously.
The ext4 extent structure looks like so
```
struct ext4_extent {
    __le32  ee_block;       /* First logical block that the extent covers */
    __le16  ee_len;         /* Number of blocks covered by this extent */
    __le16  ee_start_hi;    /* High 16 bits of the starting physical block */
    __le32  ee_start_lo;    /* Low 32 bits of the starting physical block */
};
```
If we were to use an example of a file spanning 1,000 block sizes, the ext4 structure would simply have ee_len set to 1,000 while ext3 would contain 1,000 pointers.
This would be assuming an unfragmented file, so extents are arranged in a tree to accommodate multiple extents.
The extent tree is under the i_block member in the struct ext4_inode, and it is 60 bytes in size.
The extent tree can hold three different kinds of structures those being the ext4_extent_header, ext4_extent_idx, and ext4_extent.
Each of these structures are 12 bytes in size which means 5 can be stored in the i_block member.
In reality, the number is 4 because the first 12 bytes are taken up by the extent_header.

```
struct ext4_extent_header {
        __le16  eh_magic;       /* Magic number, 0xF30A */
        __le16  eh_entries;     /* number of valid entries following header*/
        __le16  eh_max;         /* Maximum number of entries that could follow the header. */
        __le16  eh_depth;       /* Depth of this extent node in the extent tree */
        __le32  eh_generation;  /* generation of the tree (Used by Lustre, but not standard ext4) */
};
```

```
struct ext4_extent_idx {
        __le32  ei_block;       /* index covers logical blocks from 'block' */ 
        __le32  ei_leaf_lo;     /* pointer to the physical block of the next *
                                 * level. leaf or next index could be there */
        __le16  ei_leaf_hi;     /* high 16 bits of physical block */
        __u16   ei_unused;
};
```

The reason the first 12 bytes are taken up by the header is because it reveals how far the tree goes.
It tells how deep the tree goes as well as how many valid entries there are.
The maximumm depth can only by 5.
The max depth is 5 not because the i_block member is only 60 bytes (remember the first 12 are taken anyway), but because 5 is the smallest practical number.
The equation used is `4*(((blocksize - 12)/12)^n) >= 2^32` given by the kernel docs.
If the depth in the header is zero then the i_block structure can hold 4 leaf nodes.
Once 5 nodes are needed the depth is increased and an index node is used.
The ext4_extent_idx act as indirection like with ext3 indirection tables.
They point to other blocks that can contain index nodes or leaf nodes with their own extent header.
These extent blocks have their own extent_tail which is used as a checksum for that block.
This checksum uses the inode number, uuid, inode generation number, and the entire extent block excluding the checksum.
With this behavior the maximum file size that can be 16 - 256 TiB depending on block size.
The leaf node then shows the extent itself.
// insert more stuff

The inode record takes up 256 bytes while the inode structure is 160 bytes.
Ext4 can allocate larger sized inode even ones to the size of block.
It is not practical to allocate to the size of a block, but each inode can have a different size unlike the consistent size of what ext3 had.
The extra size is determined by the field i_extra_size in the struct ext4_inode.
// insert more stuff

A summary of the inode structure for ext4 looks like the table below.
| Inode Structure              |
| :--------------------------: |
| Attributes (stat struct)     |
| Extent tree / block map      |
| Extended attribute block     |
| Size for extended fields     |
| sub second precision         |

Additionally, ext4 has delayed allocation to try to allocate blocks in groups.
This also has the benefit of not allocating temporary files by the time they get deleted.
// insert more stuff

#### Hash Trees



### The Virtual Filesystem (VFS)

### Linux Files

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

[Linux Block Groups](https://docs.kernel.org/filesystems/ext4/blockgroup.html)

[Hard vs Soft Links](https://linuxgazette.net/105/pitcher.html)

[Understand Linux Links](https://www.linux.com/topic/desktop/understanding-linux-links/)

[Understanding Ext4 Layout](https://blogs.oracle.com/linux/post/understanding-ext4-disk-layout-part-1)

[Understanding Ext4 Layout Part 2](https://blogs.oracle.com/linux/post/understanding-ext4-disk-layout-part-2)

[Ext4 Extents](https://blogs.oracle.com/linux/post/extents-and-extent-allocation-in-ext4)

