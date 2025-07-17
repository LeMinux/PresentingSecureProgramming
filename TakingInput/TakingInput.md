## Taking Input

User input is root of countless vulnerabilities in software.
Sometimes the vulnerability directly affects the program due to negligence, but it may be a result of crossing boundaries.
Examples include database requests, command line executables, file systems, libraries, and more.
This is why you must conduct a series of checks to ensure that input is what is expected before doing anything with it.
It is not just limited to user input, but really any kind of input expected.
Function parameters would fall under here as it is the input given to a function.
If you have looked at NASA's Power of 10 you would recognize this as rule 7 and rule 5.
The safest approach to taking input is to assume that every input you take will explode your system.
Of course, this is not always true as invalid input is often accidental, but it puts a mind set in place to catch malicious input.
Input can mean anything.
You can not assume that input is valid just because it is not from direct manipulation of a user.
It can mean the terminal, a user form, JSON data, a binary stream, command line arguments, the network, or environment variables.
It really depends on the application and how the program takes in data.
This input must then be validated by a trusted authoritative source.
For client-server models, it means the conducting server side validation.
Even if the frontend checks for bad input an attacker could avoid the interface and send directly to an endpoint.
This isn't to say that client side validation is useless, but more so that server side validation should be the main defense as the server interacts with the system.
Even things that are to be trusted like persistent storage must be validated in the case that it was tampered with.
This could be from an internal attack, or simply corrupted data.
The need for validation is quite evident, but the process is not always easy.
Depending on the input, extra steps may need to be taken to make validation easier.
These steps include canonicalization/normalization, sanitization, validation, and output sanitization in that order.
Not every step is strictly necessary, but the order of which it is conducted is necessary.
Regardless, validation must always be conducted even if the other steps are not used as it is the gatekeeper of input.

### Canonicalization

- Definition: The process of reducing input to a singular, equivalent, and most standard form.

The goal of this process is to eliminate ambiguity of multiple representations of input into a single well-defined, equivalent interpretation while keeping the original intention.
If two different inputs resolve to the same output, then their canon result should be equal.
At first, it may seem like hashing would be a form of canonicalization as it turns input into a unique form, but the original data is lost and is not equivalent.
Often times canonicalization is done with file paths.
Since file inputs can have a variety of paths resolving to the same file, it is necessary to reduce them to a single accepted and equivalent form to make future steps easier.
The code block below shows just a few paths to get to a file like `/etc/passwd` which contains users on a Linux system and has 644 root:root permissions.
```
passwd
/etc/passwd
../../../../../etc/passw
//////etc/passwd
/etc/../etc/passwd
./etc/passwd
/./etc/passwd
```
The canon way to represent this file on Linux would be `/etc/passwd`, so a canon function should resolve all these inputs into `/etc/passwd`.
However, once symlinks join the party `/etc/passwd` may not be the actual canon path, so the symlink would need to be resolved to find the canon path.
Although, it is the programmer's decision if they want to accept symlink resolution, or simply return an error for invalid input.
Window file paths have absolute paths as well that look like `C:\Documents\Reports\Summer2025.pdf`.
It has the drive letter, the colon, and the pesky backward slash to start at the root of the drive.
Of course Windows is Windows, so this website from Microsoft explains more about their unique paths [File Path Formats on Windows Systems](https://learn.microsoft.com/en-us/dotnet/standard/io/file-path-formats).

For URLs thing are even more tricky.
There are two kinds of canonicalization for a URL.
There is the one similar to how files are handled where the URL specifies a path, and a URL that Google uses to determine a singular resource.
The canonicalization for Google more so defines what it thinks is the most canon representation.
It is more so for Search Engine Optimization (SEO) to find your website and better optimize recommendations.
It is not so much a consistent standardization, but rather a technique to reduce duplication of a resource for efficiency.
Website can suggest what they want for their canon URL with `<link rel="canonical" href="https://www.example.com/page">`, but Google ultimately decides what it is.
In some instances trying to use http when the canon URL uses https will promote to https.
This code block below shows different URLs that could be a canon URL.
```
https://example.com/page
http://example.com/page
http://example.com/page/
https://www.example.com/page
http://www.example.com/page
```

Then there is the part of the path inside the URL itself.
Then there is the part of dealing with input in a website through the URL or input on the page.
Since this is dealing with the web, other attacks like XSS attacks, double encoding attacks, and UTF-8 are a concern.
Encoding is a large issue as double encoding can be used to obfuscate intent, or one level of encoding can be used to mask a character.
As an example, some malicious input may be `<script>alert(0)</script>` as an XSS attack.
On the first level of encoding this input turns into `%3Cscript%3Ealert%280%29%3C%2fscript%3E`.
Without reducing to a canon form, a validation or sanitization function only checking for `<script>` will fail because it is actually `%3Cscript%3E`.
The fix for this would be to decode the input, but attackers know this, so they may encode the input twice or even many times.
In this HTML encoding example it turns all the % into %25, but it is still equivalent to the original text.
Using the previous example this would turn `%3Cscript%3Ealert%280%29%3C%2fscript%3E` into `%253Cscript%253Ealert%25280%2529%253C%252fscript%253E`
This XSS example would of course apply to path traversal attacks by turning `http://victim/cgi/../../winnt/system32/cmd.exe?/c+dir+c:\` into `http://victim/cgi/%252E%252E%252F%252E%252E%252Fwinnt/system32/cmd.exe?/c+dir+c:\`.
This specific example for path traversal was found at this OWASP guideline [OWASP Double Encoding](https://owasp.org/www-community/Double_Encoding).
Hopefully you can see why canonicalization is done first before sanitization and validation.

### Normalization

- Definition: The process of reducing input to a more simple or expected form

Normalization and Canonicalization, at least with user input, is similar but not the same.
It is pretty easy to get the two confused because they can overlap, are used together, or the context they are used effects the interpretation of what is a normal vs canon form.
Canonicalization is a subset of normalization since canonicalization resolves to a single unique normal form while normalization reduces to some normal form.
Normalization still contains steps to clean or transform data, but it is done to bring a more consistent form.
This can include encoding, removing characters, setting everything to the same case, adding a string suffix, or creating consistent order.
As an example a normalized path could remove the `.` and `..` special directories, yet keep the path relative.
In certain contexts, The two terms are interchanged since normalization can create a canon form, but canonicalization is a stricter form of normalization.
Normalization often times is done in an effort to help canonize.
As a result, never normalize partial input or combine normalized input with non-normalized input.
//eeehhh probably not a "as a result" type thing
//more like a general rule to do, so find a way to word it like that

To help distinguish the difference between canonicalization and normalization, at least with file paths, I'll explain a file path to a symbolic link.
If we were to look at a file path to a symbolic link, a normalized path could be the absolute path to that symbolic link itself.
Another normal path could even be a relative path without the special `.` and `..` directories to the same symlink.
If the symlink were to be a normal file or directory the absolute path would be canon, but because symlinks direct to other locations it is not canon to use just the path to the symlink.
Additionally, the symlink can redirect with a relative path, so even resolving it could result in a normalized path.
As a result, the canon version would resolve this link and find the absolute path of what the symlink goes to.
If chained links were involved the canon path would go all the way to the end, but a normalized path could be any reduced path to the links in between.
However, this is just in the context of file paths.

In the realm of UTF-8, it is possible to have input that is canon, but is not normalized.
Since the UTF-8 standard specifies two canon forms of Unicode, normalization has to decide what to use.
There is the canonical form and the compatibility equivalence form.
The normalization process for UTF-8 would then have to decide between NFD, NFC, NFKD, and NFKC forms which decides what canon form to use as well as order of marks.
Much more information can be found on the Unicode normalization form page [Unicode Normalization Forms](https://www.unicode.org/reports/tr15/).
In some cases there may not exist a widely accepted canon form like with converting letters to lowercase since that's just a word.
Such a situation could arise from taking input from a menu where a user can input a mixture of cases for a word like `PiCKle`.

### Sanitization

- Definition: The process of ensuring that data conforms to the requirements of the subsystem to which it is passed.

When input has to transfer between systems the interpretation of data can change.
As a result input itself has to be altered so that inadvertent actions are not taken.
This is why SQL injections happen because the database system interprets the data differently than the system of the app.
Command prompt injections from C code using system() would apply as the app does not interpret the data, but the shell in the OS interprets the data.
XSS injections may not go through multiple systems, but it uses the web's own interpretation against it.
An understanding of how data can turn into malicious actions 


Basically anytime you have a situation where data can be interpreted differently as a result of crossing a boundary you want to sanitize.


#### White Lists

A white lists specifies only allowable criteria.

#### Black Lists

A black lists specifies known restricted criteria.
The issue black lists have is that you must know what to block, so it is easy to miss what to block.



#### Escaping

- Definition: 

### Validation

//talk about validation before calling methods sometimes

- Definition: The process of ensuring that input data falls within the expected domain of valid program input

Validation of input means to check if input given falls within the realm of acceptability.
If input does not match the criteria of what your program deems as acceptable it is immediately dropped and is not processes further.
Once again, validation is the main decision factor in if input goes any further.
In certain cases sanitization may not be needed because if the input would require active sanitization then it can be denied.
Function arguments must always be validated or asserted.
When assertions vs validation should be conducted can be a fine line, but remember that assertions are for programmer mistakes.
Typically, it would mean asserting not NULL.

#### Integers

#### UTF-8

99% of the web currently uses the UTF-8 standard to support international languages.
UTF-8, just like with file paths, has many ways to represent the same character.
UTF-8 was designed to encompass as many languages as possible while keeping backwards compatibility with the prevalent ASCII standard.
This is why the ASCII and first 128 code points of UTF-8 are exactly the same value.
However, just one byte is not enough to encompass every language, so UTF-8 uses multiple bytes.
Remember though, that UTF-8 has to be backwards compatible with ASCII, so UTF-8 uses variable length encoding so that ASCII is read as normal.
UTF-8 uses a max of 6 bytes for a character, so depending on the language a single UTF-8 character can be 1 - 6 bytes long.
So how does UTF-8 distinguish between the many characters?
This is done by analyzing how many 1s before encountering a zero is found in the first byte read.
As mentioned before, ASCII characters will be the same, so their 8th bit is always zero.
A character that is two bytes long would begin with 110 for the first byte.
The following bytes would then contain 10 for the first two most significant bits.
As an example the UTF-8 binary for U+00A7, which is that fancy s thing to indicate a section, is **110**00010 **10**100111 or 0xC2 0xA7 in hex.
For all the bytes the table below shows potential representations.

| Byte Range              | UTF-8 Binary                                          |
| :---------------------: | :---------------------------------------------------: |
| 0x00000000 - 0x0000007F | 0xxxxxxx                                              |
| 0x00000080 - 0x000007FF | 110xxxxx 10xxxxxx                                     |
| 0x00000800 - 0x0000FFFF | 1110xxxx 10xxxxxx 10xxxxxx                            |
| 0x00010000 - 0x001FFFFF | 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx                   |
| 0x00200000 - 0x03FFFFFF | 111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx          |
| 0x04000000 - 0x7FFFFFFF | 1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx |

When letters use more bytes it has to split the bits used across the sequence.
This is seen with the x's.
For a 2 byte sequence it uses 11 bits which is split with 5 bits in the 1st byte and 6 bits in the second byte.
The 6 byte sequence only uses a single bit in the first byte and 6 in the rest using 31 bits.
The intention behind this method was to save space for ASCII text and indicate the length of the sequence, but it accidentally created a why to define the lower level characters multiple ways.
The only legal way to create a UTF-8 character is with its shortest valid sequence.
Sequences that are longer than they should be are called overlong sequences.
If we take a 1 byte ASCII value 'w' which is 01110111 (0x77) and transform it into a 2 byte UTF-8 we get a sequence of (110)00001 (10)110111 (0xC1 0xB7)
Using longer sequences would just add more zeros, so 4 bytes is (11110)000 (10)000000 (10)000001 (10)110111.
Just like in the XSS script example in the canonicalization section, this can be used to obfuscate the intended character and lead to XSS or file path attacks.

You may ask why this is not in the canonicalization or sanitization section, and that is because in this case validating is easier to do.
Validation would require just checking a correct sequence rather than trying to fix a broken one which can introduce more bugs than necessary.
//show examples
//show a better example
For example if we were to try to sanitize an invalid sequence depending on your implementation an attacker could provide an invalid length and remove perfectly good bytes like so `1111110x 00xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx`.

#### Output Sanitization

## Source

Secure Coding in C and C++ by Robert C. Seacord

Secure Programming Cookbook for C and C++ by John Viega and Matt Messier
