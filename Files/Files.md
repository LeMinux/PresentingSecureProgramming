## Files

### What Are Files

Ahhhh the fundamentals of storing information.
Before computers, a file was a collection of physical records.
Technically it got the name because it referred to a binding of string (filum in Latin) creating the collection rather than the actual collection.
At the time for smaller collections it worked just fine, but to meet the mass needs of businesses and bureaucracy a better form of binding was needed.
This is what lead to file folders to streamline storing files.
These are the little folder icons you see when browsing the file explorer.
Language, at least in English, still referred to the container rather than the collection.
It was pretty typical to hear phrases like "Could you hand me the file about x" or "what files do we have about y".
Then people figured out how to make rocks abide by the whimsical demands of humans which gave rise to computers.
The change was not instant as storage devices could not hold that much data, but eventually technology improved to allow for reliable mass digital storage.
In order to aid the transition into the digital age the paper jargon stuck around.
Now I can hear you say "Wow! Nice history lesson that I don't care about!", but just bear with me.
The digital age fundamentally changed how we deal with files.
Files are a singular unit defined by a collection of binary rather than records.
Trying to treat a digital file as a paper file will not work as digital data if fundamentally different.
Unlike paper which could simply be grabbed, binary data needs interpretation on what it is.
Therefore, a system had to be placed to define the abstraction of a file, the boundaries of files, and what collections exist.
The identity of what creates a digital file and digital folder is so intertwined with the abstraction of the system that they cannot exist without the system.
File systems not only define where data for a file is located, but also data about that file that the OS uses.
Different implementations of file systems have risen to meet multi-user, interface, and efficiency needs.
It is this abstraction that determines how to properly handle files and folders thus affecting security.
This would include data such as permissions, ownership, or size, so it is important to understand conceptually what a file is per system.
Essentially, a file system is a system of metadata that can be used to implement security.

### Different Systems

The two main Operating systems of Linux and Windows have different implementations of a file system.
Thus, there are two chapters in here for Linux and Windows as well as a general security chapter that applies to both.
The chapters about the OS's will go into detail about how their file system's abstraction works and other details.
The chapter for general security will go over techniques and other aspects of concerns about file systems.
It may not be necessary for you to exactly how file systems work, but for fields such as forensic sciences it is beneficial to know.
For this field, Knowing how the file system works allows for techniques to understand what time files were created and when data was overwritten.
