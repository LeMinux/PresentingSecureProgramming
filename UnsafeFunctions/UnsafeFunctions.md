# Unsafe C Functions

Yeah there are a lot

## BAD FUNCTIONS

- atoi(), atof(), atol()
    ASCII to integer
    ASCII to float
    ASCII to long
    If you're wondering what the 'a' meant :P
    <undefined behavior>
    <oveflow prone>

- strcpy()
    <buffer overflows>

- strcat()
    <buffer overflows>

- sprintf()
    <buffer overflows>

- vsprintf()
    <buffer overflow>

- gets()
    <huge buffer overflow problem>
    deprecated

- mktemp()

- tmpnam()

- access()

    Access has a race condition since it checks permissions before opening a file. This can be especially dangerous with symbolic links.
    You should let the OS check the permissions for you by opening the file.

- stat()
    <race condition>

- execvp()
    <PATH manipulation>

- execlp()
    <PATH manipulation>

<todo more research on exec>

- system()
    <Environment variable manipulation and opens to shell manipulation>

- alloca()

## QUESTIONABLES

These are listed here as they do have a use, but the way they are most often is unsafe. These can be made safer, but you may
be better of using something else.

- scanf family

    Scanf is meant for formatted strings. This would be like a csv file. Using %s really could mean anything there is no known end.
    If you are going to use it at least use the precision modifiers to limit how many characters are taken, and ensure the string is NUL terminated.
    Using %.14s will simply take 14 character, so if you want to NUL terminate take 13 and set the last as the NUL byte.

    The scanf family can also be unrealiable as white space can really mess it up. <todo what about empty strings>

- strncpy()

    The strncpy( ) function is certainly an improvement over strcpy( ), but it's just werid. 
    If the source contains more data than the limit given by the len argument, the destination buffer will not be NUL-terminated.
    This means the programmer must ensure the destination buffer is NUL-terminated. This is especially true if the substring you take
    does not end in a NUL byte.

    strncpy() is also more inefficient by padding out the end of the destination with NUL bytes if the string from source is
    less than the length given.

    \0 = NUL byte

    Source: "I am a string\0" (length of 14)
    <todo explanation>

## ALTERNATIVES

- strtol()

- strncat(char* destination, const char* source, size_t n)
    
    Keep in mind that n should be the remaining size in source not the total length of source.
    You could also use this as a hacky strncpy.

- snprintf(char* destination, size_t size, const char* format, ...)

    snprintf can have different implementation on different linux systems depending on their version.

- fgets(char* source, int size, FILE* stream)
    
    fgets is much better for taking user input. It will read at most len - 1 and guarentees a NUL byte after the last character.
    fgets reads until it reaches EOF or newline.
    If a newline character is read it will store it in the buffer which can be used to determine if you have read an entire line.

    Error handling for fgets can be a little more tricky as it returns NULL in the event of reaching EOF while reading nothing, or a file error.
    To check for a file error you would use ferror() to check for an error on the file stream.
    
- execv()

- execve()

- mkstemp

- strdup

- fstat

    fstat is better than stat as it avoid race conditions
