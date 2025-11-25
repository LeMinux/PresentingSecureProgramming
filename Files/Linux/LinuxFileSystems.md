### Linux File Systems

Welcome to the Linux file system section!
This section is a deep dive into how files get a home in the first place, and how they eventually get used.
This section isn't necessary to know if you just want to deal with files, but it is useful for forensics or file recovery.
Linux has many file systems defined, it is not just the system on disk.
For the most part most of the magic doesn't occur on the disk and is instead in RAM, but the magic needs its source.
I'll first talk about how the Extended File System (ext) is created, which is what most Linux systems use, then abon specific versions, then the Virtual File System (VFS).
There will be quite large C structs in here to show how each component is defined, but you don't need to memorize them.
They are there to show what goes into a file system, and a peek into how exactly your files work.


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
The first 60 lines contains information like the OS type, block size, error behavior, inode count, block count, reserved block count, blocks per group, etc.
It even contains the number of times the system has been mounted before it has been checked.
After the first 60 lines it shows every block group which will explode your terminal with text hence the suggestion for the head command.
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
For normal users you will probably run out of space before that happens, but knowing this fact can lead to a unique DOS attacks if too many temp files get created.
The number of inodes created is defined by the `filesystem size / inode ratio`.
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
Then the formula to get to the inode itself is `(inode_number - 1) % # of inodes_per_group`.
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

#### Inode Contents

What exactly does the inode contain though?
Well it contains the file type, permissions, location to data blocks, and other information.
Usage of `ls -l` or `stat` will reveal some information stored in the inode with `stat` being more comprehensive.
The stat struct found in stat (2) shows most of the information an inode holds.
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

#### Data Blocks

The data blocks are what's left for the file system to use after it has created itself.
This is where the data for your files will be stored and where your inodes will point to.
Other features like journaling will also be used in the data blocks as it is just a normal file.
Sometimes though, a file can store its data inside the inode itself if it is small enough, so an inode may not always have data blocks.

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

### The Virtual Filesystem (VFS)

So far we have covered what happens on disk when it comes to EXT, but there is one big problem with disks.
Disk I/O is an expensive task to conduct in terms of time, so those processes want to be minimized as much as possible.
Additionally, a process may want non-persistent file, yet have a way to traverse to it.
Disks are not suited for this, but RAM suites this job perfectly.
In fact, many secrets are hidden in RAM, yet the philosophy of treating things like files hides this fact.
As an example, the directories of /proc, /dev, /sys, and /tmp are such RAM secrets.
These directories do not exist on disk as they reside solely in RAM.
Knowing this you can use tools like volatility3 to not only examine processes but to also find files or devices.
All of this is possible because of the VFS.
The main purpose of the VFS is to act as the file system interface for user space programs.
Really, this entails a whole lot of work because this interface is massive.

#### Defining Filesystems

One of the main behaviors is creating an abstraction to allow different filesystems to coexist.
It does this by handling system calls such as open, stat, and chmod.
This way, if your program needs to access a file from a USB using FAT32 while your host OS uses ext4 your program can't tell the difference.
The thing is the VFS doesn't really define how files are handles.
The filesystem itself defines to the VFS what it calls inodes, dentries, and other operations.
First, the filesystem has to register itself with the file_system_type struct.

```
struct file_system_type {
        const char *name;
        int fs_flags;
        int (*init_fs_context)(struct fs_context *);
        const struct fs_parameter_spec *parameters;
        struct dentry *(*mount) (struct file_system_type *, int, const char *, void *);
        void (*kill_sb) (struct super_block *);

        /* stuff for the VFS */
};
```

This struct describes the filesystem, but most importantly includes a mount function.
This function is what allows you to mount a filesystem into any arbitrary point since it is required to return a tree starting at the root dentry of what you wanted.
The unmount function is not held in here since the struct super_operations holds that information.
Here the filesystem kills the superblock with kill_sb which shuts down the current instance of the filesystem.
Other members like next, fs_supers, and owner are not in here since that's for the VFS to handle not the filesystem.
For example, the 'next' member points to the next registered file system since the VFS stores a linked list of these structs.
A list of supported filesystems can be found in `/proc/filesystems`.
When you cat this file you may see a lot of systems saying nodev which just means it doesn't need a block device to be mounted.
These filesystems can be other virtual filesystems or even network filesystems.
This file is also used by the mount command if it couldn't determine the type of filesystem to be mounted basically brute forcing what doesn't have nodev next to it.
Here is what I have for my `/proc/filesystems`
```
nodev	sysfs
nodev	tmpfs
nodev	bdev
nodev	proc
nodev	cgroup
nodev	cgroup2
nodev	cpuset
nodev	devtmpfs
nodev	configfs
nodev	debugfs
nodev	tracefs
nodev	securityfs
nodev	sockfs
nodev	bpf
nodev	pipefs
nodev	ramfs
nodev	hugetlbfs
nodev	devpts
	ext3
	ext2
	ext4
	squashfs
	vfat
nodev	ecryptfs
	fuseblk
nodev	fuse
nodev	fusectl
nodev	efivarfs
nodev	mqueue
nodev	resctrl
nodev	pstore
	btrfs
nodev	autofs
nodev	zfs
nodev	binfmt_misc
```
Any of these filesystems can be mounted, and when they do get mounted it's the job of the mount function to give a struct super_operations.
The super_operations struct defines how the VFS can change the superblock of the mounted filesystem.
```
struct super_operations {
        struct inode *(*alloc_inode)(struct super_block *sb);
        void (*destroy_inode)(struct inode *);
        void (*free_inode)(struct inode *);
        void (*dirty_inode) (struct inode *, int flags);
        int (*write_inode) (struct inode *, struct writeback_control *wbc);
        int (*drop_inode) (struct inode *);
        void (*evict_inode) (struct inode *);
        void (*put_super) (struct super_block *);
        int (*sync_fs)(struct super_block *sb, int wait);
        int (*freeze_super) (struct super_block *sb, enum freeze_holder who);
        int (*freeze_fs) (struct super_block *);
        int (*thaw_super) (struct super_block *sb, enum freeze_wholder who);
        int (*unfreeze_fs) (struct super_block *);
        int (*statfs) (struct dentry *, struct kstatfs *);
        int (*remount_fs) (struct super_block *, int *, char *);
        void (*umount_begin) (struct super_block *);

        int (*show_options)(struct seq_file *, struct dentry *);
        int (*show_devname)(struct seq_file *, struct dentry *);
        int (*show_path)(struct seq_file *, struct dentry *);
        int (*show_stats)(struct seq_file *, struct dentry *);

        ssize_t (*quota_read)(struct super_block *, int, char *, size_t, loff_t);
        ssize_t (*quota_write)(struct super_block *, int, const char *, size_t, loff_t);
        struct dquot **(*get_dquots)(struct inode *);

        long (*nr_cached_objects)(struct super_block *,
                                struct shrink_control *);
        long (*free_cached_objects)(struct super_block *,
                                struct shrink_control *);
};
```
Here there are actually two unmounting functions used at different stages.
The put_super function is a wish by the VFS to unmount while the unmount_begin is called when the VFS is unmounting.
This structure only defines what the system would call an inode.
To handle individual inodes that is under inode_operations.
```
struct inode_operations {
        int (*create) (struct mnt_idmap *, struct inode *,struct dentry *, umode_t, bool);
        struct dentry * (*lookup) (struct inode *,struct dentry *, unsigned int);
        int (*link) (struct dentry *,struct inode *,struct dentry *);
        int (*unlink) (struct inode *,struct dentry *);
        int (*symlink) (struct mnt_idmap *, struct inode *,struct dentry *,const char *);
        struct dentry *(*mkdir) (struct mnt_idmap *, struct inode *,struct dentry *,umode_t);
        int (*rmdir) (struct inode *,struct dentry *);
        int (*mknod) (struct mnt_idmap *, struct inode *,struct dentry *,umode_t,dev_t);
        int (*rename) (struct mnt_idmap *, struct inode *, struct dentry *, struct inode *, struct dentry *, unsigned int);
        int (*readlink) (struct dentry *, char __user *,int);
        const char *(*get_link) (struct dentry *, struct inode *, struct delayed_call *);
        int (*permission) (struct mnt_idmap *, struct inode *, int);
        struct posix_acl * (*get_inode_acl)(struct inode *, int, bool);
        int (*setattr) (struct mnt_idmap *, struct dentry *, struct iattr *);
        int (*getattr) (struct mnt_idmap *, const struct path *, struct kstat *, u32, unsigned int);
        ssize_t (*listxattr) (struct dentry *, char *, size_t);
        void (*update_time)(struct inode *, struct timespec *, int);
        int (*atomic_open)(struct inode *, struct dentry *, struct file *, unsigned open_flag, umode_t create_mode);
        int (*tmpfile) (struct mnt_idmap *, struct inode *, struct file *, umode_t);
        struct posix_acl * (*get_acl)(struct mnt_idmap *, struct dentry *, int);
        int (*set_acl)(struct mnt_idmap *, struct dentry *, struct posix_acl *, int);
        int (*fileattr_set)(struct mnt_idmap *idmap, struct dentry *dentry, struct file_kattr *fa);
        int (*fileattr_get)(struct dentry *dentry, struct file_kattr *fa);
        struct offset_ctx *(*get_offset_ctx)(struct inode *inode);
};
```
Keep in mind this is in relation to the inode itself and not the file data.
It is the metadata to the file that is messed with here.
Dentries are an exception since they deal with inode mappings, and their file data contains that.
You might recognize commands like rmdir, ln (link/symlink), touch (create), rm (unlink), and mv (rename).
This is where those system calls mentioned earlier relating to opening, creating, linking, and changing attributes are handled.
Not all of these operations need to be defined.
Thus, it defines if links, directories, or files even exist for the filesystem.
An another important function to mention is lookup for finding inodes.
Then finally to define how individual file data is handled it is defined in the file_operations struct.

```
struct file_operations {
        struct module *owner;
        fop_flags_t fop_flags;
        loff_t (*llseek) (struct file *, loff_t, int);
        ssize_t (*read) (struct file *, char __user *, size_t, loff_t *);
        ssize_t (*write) (struct file *, const char __user *, size_t, loff_t *);
        ssize_t (*read_iter) (struct kiocb *, struct iov_iter *);
        ssize_t (*write_iter) (struct kiocb *, struct iov_iter *);
        int (*iopoll)(struct kiocb *kiocb, struct io_comp_batch *, unsigned int flags);
        int (*iterate_shared) (struct file *, struct dir_context *);
        __poll_t (*poll) (struct file *, struct poll_table_struct *);
        long (*unlocked_ioctl) (struct file *, unsigned int, unsigned long);
        long (*compat_ioctl) (struct file *, unsigned int, unsigned long);
        int (*mmap) (struct file *, struct vm_area_struct *);
        int (*open) (struct inode *, struct file *);
        int (*flush) (struct file *, fl_owner_t id);
        int (*release) (struct inode *, struct file *);
        int (*fsync) (struct file *, loff_t, loff_t, int datasync);
        int (*fasync) (int, struct file *, int);
        int (*lock) (struct file *, int, struct file_lock *);
        unsigned long (*get_unmapped_area)(struct file *, unsigned long, unsigned long, unsigned long, unsigned long);
        int (*check_flags)(int);
        int (*flock) (struct file *, int, struct file_lock *);
        ssize_t (*splice_write)(struct pipe_inode_info *, struct file *, loff_t *, size_t, unsigned int);
        ssize_t (*splice_read)(struct file *, loff_t *, struct pipe_inode_info *, size_t, unsigned int);
        void (*splice_eof)(struct file *file);
        int (*setlease)(struct file *, int, struct file_lease **, void **);
        long (*fallocate)(struct file *file, int mode, loff_t offset, loff_t len);
        void (*show_fdinfo)(struct seq_file *m, struct file *f);
#ifndef CONFIG_MMU
        unsigned (*mmap_capabilities)(struct file *);
#endif
        ssize_t (*copy_file_range)(struct file *, loff_t, struct file *, loff_t, size_t, unsigned int);
        loff_t (*remap_file_range)(struct file *file_in, loff_t pos_in, struct file *file_out, loff_t pos_out, loff_t len, unsigned int remap_flags);
        int (*fadvise)(struct file *, loff_t, loff_t, int);
        int (*uring_cmd)(struct io_uring_cmd *ioucmd, unsigned int issue_flags);
        int (*uring_cmd_iopoll)(struct io_uring_cmd *, struct io_comp_batch *, unsigned int poll_flags);
        int (*mmap_prepare)(struct vm_area_desc *);
};
```

This is where the system calls for writing, reading, seeking, and such are defined.
When a file is to be opened the VFS creates a file structure and puts information into there.
If you have used C these would be what those FILE* variables point to.

These are all the structures that define your filesystems behavior for the Linux VFS.
If you want to get into more granular detail on how individual file systems are coded they can be found in `linux/fs` (`/usr/src/<linux version>/fs`).


#### Caching

So far we have covered how filesystems define themselves to the VFS, but we haven't really talked about files yet.
The next large task the VFS handles is path name lookups, and the operations related to files.
This is sped up by caching inodes to avoid searching through the disk, but it will look on disk if it needs to.
The VFS has two separate caches for this task.
One is an inode cache for any kind of file while the other one is a dentry cache which holds dcaches.
Dcaches are never written to disk and only exists in RAM.
As a result, since the VFS is responsible for look ups which use dentries this technically means dentries are a facade.
At first this may sound confusing because you're still able to alter entries in a dentry, but remember inodes point to any kind of file.
We still have the inode cache, so it is here where changes are reflected on to disk if the inode did reside on disk.
The inode cache can also point to inodes that exist in memory like that from a pseudo filesystem.





These are the VFS's version of inodes and dentries since it wants to cache the filesystem's definition of said constructs.

