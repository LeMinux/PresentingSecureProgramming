## Windows File Security

### Windows Files

Windows is. . . ugh.
The problem with windows is that it is a hodgepodge of ideas combined into a single product, and this is because of the OOP design.
Windows has a distinction on files, devices, and //I dunno other stuff I'll have to find
This results in many APIs used for different file types.

### Windows File Handling

//case insensitive

### Windows Files Permissions

//my god I'll have to go into Administrator, SYSTEM, Active directory and such
//and all the other permission types

| Permission      | Description |
| :-------------: | :---------: |
| DELETE          | The ability to delete the object |
| READ_CONTROL    | The ability to read the object’s security descriptor, not including its SACL |
| SYNCHRONIZE     | The ability for a thread to wait for the object to be put into the signaled state |
| WRITE_DAC       | The ability to modify the object’s DACL |
| WRITE_OWNER     | The ability to set the object’s owner |
| GENERIC_READ    | The ability to read from or query the object |
| GENERIC_WRITE   | The ability to write to or modify the object |
| GENERIC_EXECUTE | The ability to execute the object (applies primarily to files) |
| GENERIC_ALL     | Full control |
