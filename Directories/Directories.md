You're probably wondering why directories are on here.

Well the answer to that is Linux and how permissions work on directories.
If you don't know about Linux permissions look at the Files security show case.

For files the permissions are quite simple in that the permissions set of the file are what you'll get.
Directories are a bit more tricky as the permissions allow modification of the directory even if they are not the owner of the subdirectory.
It depends on the permissions of the parent what they can do inside of the subdirectory, but because the subdirectory is inside the parent it can change the name.

$HOME/Documents/GoofyStuff owned by user in group user with 775
$HOME/Documents/GoofyStuff/RootDir owned by root in group root with 750

Despite not owning the file or part of the root group, GoofyStuff can mv the RootDir to a different name.

<parent directory permissions>
<only the owner and superuser should have writeables>
