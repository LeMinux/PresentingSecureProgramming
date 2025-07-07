## General File Security

### Handling Files Best Practices

### Race conditions (Time of Check vs Time of Use TOCTOU)
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

#### Absolute vs Relative Paths

//find better introduction
Paths will determine how to even get the file you want to handle, but a program must properly handle different paths provided to it.
For now, we will ignore links as these file objects makes validation more complicated, but they will be mentioned later.
A program should expect to handle two different kinds of paths.
These are an absolute path or a relative path.
On Linux, an absolute path is anything beginning with `/` such as `/etc/resolv.conf`, `/home/Jimbo/Documents/`, or `/usr/../etc`.
Absolute paths allow for permissions to be verified every step of the way, and only evaluates to one file object.
Relative paths traverse based off the current working directory.
It begins with `.` to denote the current directory or `..` to denote going to the parent directory or just a name.
These paths are some examples of relative paths `../Linux/ProcFDs/`, `../`, `cheese`.
Generally it will be used for file system traversal or finding files within the current working directory.
If you notice though, an absolute path can still contain `..` since it would still refer to a single file starting from the root.
This can mean you can start off from root and end up back at root with a path like `/etc/udev/rules.d/../../../`.
It is this nuance that makes files paths tough to validate.
Naive validation or sanitization can lead to storing files in unintended places or opening unintended files.
A user could supply a path like `/home/../etc/shadow` which would resolve into `/etc/shadow`.
A program using elevated privileges could then accidentally write over the contents of password hashes as a result.
Furthermore, a path like `/home/Jimbo/.config/../../../etc/sudoers` could bypass a length check if the program is known the check only the first 19 characters.
Additionally, equivalence vulnerabilities can be fabricated where a path is effectively equivalent to the desired file.
Such a case would be the path `/var/log/./syslog` which is equivalent to `/var/log/syslog`.
A program strictly checking for a string path of `/var/log/syslog` would then allow `/var/log/./syslog`, and an attacker would get what they want.

The relative path does not evaluate to the absolute path.
You may think the '.' would expand into the absolute path, but it does not.
The argument will literally be `./path/to/thing` instead of `/home/Jimbo/Documents/path/to/thing` which means the program has no context of permissions before it.
As an example, if a script was run inside `/home/Jimbo/Documents/SecretStuff` with /Jimbo and /Documents having 700 permission, but SecretStuff has 776 from default mkdir permissions
if for what ever reason the script allowed switching users either by poor design decisions or some vulnerability a user Timmy outside the owner and group permissions could list the SecretStuff with a relative path.
This behavior is shown with the script under `./RelativePathAfterSu/relative_path.sh`.
This one does not use sudo because I thought it would be dangerous to use `sudo su` in a script, so it emulates having no permissions along the path instead.
Regardless of implementation the point still stands that the relative path can be used to bypass permissions by ignoring all directories before it.
This is a pretty specific vulnerability to have.
It would require switching users into the current directory or subprocess cds and having permissions set just the right way, but for a suid or guid program it could happen.

#### Links

So lets say you have a program where you deal with file paths.
You know vulnerabilities associated with paths, so you conduct what ever magic to handle that path.
Just when you thought you handled your files perfectly fine you now have to deal with files pretending to be what they say.
Links are a similar to shortcuts on Windows, but of course not exactly the same.
There are two kinds of links to consider on Linux.
These are soft and hard links.
Soft links/symbolic links/symlinks just contain a file's name.
The path can be a relative or absolute path, but they do not point to the actual inode.
As a result, deleting the file the symbolic link points to can result in a broken link.
To resolve this issue a hard link can be used to directly point to the inode of a file.
In effect, it is "creating" two files with different names but identical contents.
If you recall, inodes are limited to their current file system, so hardlinks can not link to other files across file systems.
If you wonder why `ls -l` lists how many hard links there are for a file it is because all hard links must be deleted before the file gets deleted.
In a sense, when you create a directory the `.` and `..` are hard links.
They point to the inodes of current directory and the parent directory respectively.
This is why when you use a relative path it does not give the entire absolute path because there is no need to.
The inode given allows for a direct skip into where it starts from.

A user does not even need permissions for the file to link to it.
This is because the permissions will be checked once the linked file is opened, so it is typical to see symbolic links with permissions of 777.
Really the permissions would determine who can use the link.
Just like other aspects of files, links take special care to handle as naive checking will create a security vulnerability.
As mentioned, links typically will have 777 permissions, so a program checking for permissions that doesn't resolve a link would instead check the link's permissions rather than the actual file.
This is a huge consideration to keep in mind because links can be made to any file regardless of the user's permissions to that file.
The user Jimbo is able to create a link to `/etc/shadow` despite `/etc/shadow` having 640 root:root permissions.
Additionally, links can mask themselves as a file because they have a name just like a regular file.
If we continue with `/etc/shadow`, a user could create a link under the name and path of `/etc/shadow` to mess up a program.
For this reason, some programs may decide to not dereference links.
Links can also then change mid-way through execution if a Look Before you Leap approach is taken.

#### Sanitization of Paths

//list some vulnerabilities related to file paths
// equivalence vulnerability
// path traversal vulnerability
// relative path thingy

With all the ways an acceptable path can be made it is pretty difficult to sanitize and validate file paths correctly.
Failure to properly sanitize paths can lead to a CVE like this one [CVE-2024-2362](https://www.tenable.com/cve/CVE-2024-2362)
File traversal vulnerabilities can take many forms, so a programmer must convert the input into a standardized form first.
This is called canonicalization.
Canonicalization makes it much easier to verify paths as it resolves the path into a simple absolute path.
This way it avoids equivalence and path vulnerabilities.
Using solely naive sanitization methods such as removing any occurance of `../` or `./` is not sufficient.
Checking the beginning portion of a path as well is not sufficient because of absolute paths using traversal like `/var/www/downloads/../../log`.
All it would really take is the malicious user to create their own script to conduct the reverse of the sanitization and replace `../` with `....//` to get what they want.
Hidden files must also be considered as those are valid file types, and sanitization that removes any `.` would make those files not usable.
