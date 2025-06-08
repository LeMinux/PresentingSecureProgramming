//File stuff will probably cover most of this stuff
//There is some more specific stuff like sticky bits though and sub dirs with different permissions

$HOME/Documents/GoofyStuff owned by user in group user with 775
$HOME/Documents/GoofyStuff/RootDir owned by root in group root with 750

Despite not owning the file or part of the root group, GoofyStuff can move the RootDir to a different name.
//create a little bash program to show it
//include something about walking up the path checking for permissions because of this
