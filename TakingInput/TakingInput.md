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

- Definition: The process of reducing input to a singular, equivalent, and most standard normal form.

The goal of this process is to eliminate ambiguity of multiple representations of input into a single well-defined, equivalent interpretation.
This way the sanitization and validation functions only have to worry about checking a single form rather than considering many other forms.
Not only does this simplify the process, but it makes the code more readable and maintainable.
But what exactly is a canonized form?
Well the answer to that question really depends on the situation and criteria.
Sometimes the canon form is a chosen normal form while other times it is well-defined.
For example, a canon file path has no special directories, no links, and starts at the root.
An American phone numbers though could have multiple canon forms such as `123-456-7890`, `1234567890`, `(123) 456-7890`, or `1+ 123-456-7890`
These phone numbers have equivalent meaning, but a canonized form is one and only one of these forms.
Regardless on what the canon form is, the different variety of inputs should always resolve to its canon form.

One place you will see canonicalization used a lot is with file paths.
File paths only have one canonical form, but have enough system complexity to understand what it means to be canon.
File paths can have a variety of paths resolving to the same file.
This can be from absolute and relative paths or links.
Hard links are an interesting issue, but a canonized path refers to the path itself rather than the data blocks on disk.
Technically hard links ruin having only one path to a file, but it is not really a consideration for canonizing as it just so happens that two files are the same.
Links generally are a concern for race conditions, but that is covered in the Files chapter.
The code block below shows just a few paths to get to a file like `/etc/passwd` which contains users on a Linux system and has 644 root:root permissions.
```
passwd
/etc/passwd
../../../../../etc/passw
//////etc/passwd
/etc/../etc/passwd
./etc/passwd
/./etc/passwd
/home/User/Documents/link_to_passwd
```
The Canon way to represent this file on Linux would be `/etc/passwd`.
Conveniently enough it is also the absolute path to the file.
However, keep in mind that the absolute path to a file is not always the canon path because of soft links.
Additionally, symlinks can redirect with a relative path, so even resolving it could result in a non-canon path.
As a result, the canon version would resolve symlinks and find the absolute path of what the symlink goes to.
If chained links were involved the canon path would go all the way down the chain, but a non-canon path could be any path leading to the end file or links in between.
Although, it is the programmer's decision if they want to accept symlinks.
Window file paths have canon paths as well that look like `C:\Documents\Reports\Summer2025.pdf`.
It has the drive letter, the colon, and the pesky backward slash to start at the root of the drive.
A path like `C:Documents\Reports\Summer2025.pdf` without the `\` after `C:` is not canon because it starts from the current directory on the C: drive.
Windows does have case-insensitive paths, but they do preserve the case.
The comparison itself done by the .NET file system API is case-insensitive.
Technically this means there is no canon path if you want to go by the definition, but it is treated as canon for windows.
Windows is known for being wacky, so this website from Microsoft explains more about their paths [File Path Formats on Windows Systems](https://learn.microsoft.com/en-us/dotnet/standard/io/file-path-formats).

Another place canonicalization can occur is with URL paths.
There are two kinds of canonicalization for a URL.
There is the one similar to how files are handled where the URL specifies a path, and a URL that Google uses to determine a singular resource.
The canonicalization for Google more so defines what it thinks is the most canon representation.
It is for Search Engine Optimization (SEO) to find your website and better optimize recommendations.
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

Then there is the part of dealing with input in a website through the URL or input on the page.
Since this is dealing with the web, other attacks like XSS attacks, encoding attacks, and UTF-8 are a concern.
Encoding is a large issue as double encoding can be used to obfuscate intent, or one level of encoding can be used to mask a character.
As an example, some malicious input may be `<script>alert(0)</script>` as an XSS attack.
On the first level of encoding this input turns into `%3Cscript%3Ealert%280%29%3C%2fscript%3E`.
Without reducing to a canon form, a validation or sanitization function only checking for `<script>` will fail because it is actually `%3Cscript%3E`.
The fix for this would be to decode the input, but attackers know this, so they may encode the input twice or even many times.
In this HTML encoding example it turns all the % into %25, but it is still equivalent to the original text.
Using the previous example this would turn `%3Cscript%3Ealert%280%29%3C%2fscript%3E` into `%253Cscript%253Ealert%25280%2529%253C%252fscript%253E`
This XSS example would of course apply to path traversal attacks by turning `http://victim/cgi/../../winnt/system32/cmd.exe?/c+dir+c:\` into `http://victim/cgi/%252E%252E%252F%252E%252E%252Fwinnt/system32/cmd.exe?/c+dir+c:\`.
This specific example for path traversal was found at this OWASP guideline [OWASP Double Encoding](https://owasp.org/www-community/Double_Encoding).

### Normalization

- Definition: The process of reducing input to a more simple or expected form

Normalization and Canonicalization are similar but not the same.
Canonicalization is a subset of normalization since canonicalization resolves to a single unique normal form while normalization reduces to some normal form.
It is pretty easy to get the two confused because their actions overlap or the interpretation of what is a normal vs canon form changes between topics.
Sometimes they are used interchangeably, but it depends on the intention of the end result of a process.
Sometimes there may not be a difference in the two processes, so correctness wouldn't matter.
Normalization still contains steps to clean or transform data, but it is done to bring a more consistent form rather than a unique form.
This can include
```
removing redundant or duplicate data
adding a suffix string
adding a prefix string
creating consistent order
standardize to a specific form (like DD-MM-YYYY)
setting all letters to the same case
setting expected delimiters
encoding
```
These same actions can also be conducted in canonicalization, but once again we have to look at the entire process to determine what is what.
Since normalization is not intending to reduce to a singular unique form, you have to be careful about how it is done.
Do not combine normalized input with non-normalized input or normalize partial input as it can create segments that are not normalized.

This then raises the question then on why normalization is needed if the canon form is the better form?
Once again I'll point back to that code block of the different actions for normalization.
If we take the input of `A WaSp` and change it into `a_wasp`, or `A hive\n` into `A hive` is their altered form the canon form?

//Include something here about normalization changing things to a state
//Probably should talk about how canonicalization could apply to anything, but in terms of thinking it plays more like normalization in this case.

It could be, but are we concerned about the canon form or just want consistency?
Sometimes you don't care about what the canon form is and just need consistency for raw data.
Yes, the canon form is the most consistent and best for comparison, but that is assuming there is a worthwhile canon form to have.
What is the canon form of a sentence or a JSON?
A canonical form would include having the exact same order of elements in a JSON or correct spelling for a sentence.
This would be a lot of effort to conduct over something simple like removing redundant characters.
Some fields like data science benefits from normalization especially with AI depending on consistent data.
This can involve scaling numerical data in some way to reduce bias or trying to combine data sets in a way that can be meaningfully analyzed.
For more interactive text based AI, this may involve creating consistent spacing of text since the text has to be tokenized.
If we want to be very specific we can look at UTF-8.
In the realm of UTF-8, it is possible to have input that is canon, but is not normalized.
Since the UTF-8 standard specifies two canon forms of Unicode, normalization has to create consistency on what to use.
These two canon forms are the canonical form and a compatibility equivalence form.
The normalization process for UTF-8 would then have to decide between NFD, NFC, NFKD, and NFKC forms which decides what canon form to use as well as ordering of marks.
I won't go into every detail about UTF-8 normalization, so I'll give this link if you want to know more [Unicode Normalization Forms](https://www.unicode.org/reports/tr15/).

### Sanitization

- Definition: The process of ensuring that data conforms to the requirements of the subsystem to which it is passed.

When data has to transfer between systems or trust boundaries the interpretation of data can change.
This is why SQL injections happen because the database interprets the data differently than the app.
Command prompt injections from C code using system() would apply as the app does not interpret the data, but the shell in the OS interprets the data.
XSS injections use the web's own interpretation against.
Sometimes they stored in a database, but it could be a reflected attack.
Basically anytime you have a situation where data can be interpreted differently as a result of crossing a boundary you want to sanitize.
It is up to the calling process to conduct sanitization because it understands the context of the input.
What ever is receiving the input be it through an API or library call will just take the input.
It's kind of like a game of telephone except the consequences of a misinterpretation means you lose your entire database.
This would of course require an understanding on how data can be interpreted between systems, and how to block it.
The main techniques of sanitization include removing, replacing, encoding, or escaping characters based off a list.
Each of these techniques have their uses which depends on how invalid characters should be handled, and how much of the original text should be preserved.
Escaping preserves the input, but provides a greater risk if done incorrectly.
As an example, a naive approach would escape `'` to `\'`, but if the input were `\'` it would turn into `\\'` which escapes the escape.
However, this does provide the best user experience as why shouldn't a username be "\<script\> alert(0) \</script\>".
With proper escaping a user can since it'll treat the name as data.
Encoding falls in the same camp as escaping, but it's a very specific kind of encoding.
This is not encoding like base64, but encoding used as a type of escape.
Specifically for avoiding XSS it would encode `<` and `>` into `&lt` and `&gt`.
The other form of encoding which would be transforming data into another form would be conducted after the validation process because you don't want the encoding to hide malicious characters.
The first two techniques are more destructive to user input, but can be acceptable in some cases.
Replacing spaces with underscores would be one way of replacing assuming that underscores are a valid character to have.
Here it replaces bad characters with known good alternatives.
There may not be a good alternative all the time, so removal would occur in that case.
Removal does as it says and removes malicious characters.
With these techniques though, keep in mind that sanitization manipulates the data much more drastically than normalization and canonicalization.
It can be possible to have your sanitization process inadvertently create malicious data.
A pretty funny way to get around a removal sanitization technique is to simply split words with the very thing that will get removed.
Input like `<scr<script>ipt> alert(0) </scr</script>ipt>` where the sanitization strictly removes script tags would turn this input into `<script> alert(0) </script>`.
Of course any poorly implemented step of the validation process can pass malicious data, but sanitization is the main process that attempts to remove malicious intent.
This is why in some cases validation can replace sanitization to deny invalid data right then and there rather than manipulate it which can be safer.
The validation function would still need some list to know what to do though, so lets talk about the two list approaches.

#### White Lists

A white lists specifies only allowable criteria.
This is generally the most safe approach because there is a failsafe to deny unexpected bad characters.
By specifying characters that are known to be safe, it becomes much easier to know what characters are potentially unsafe and handle them accordingly.
This does create larger lists since alphanumberic characters are acceptable in most cases and everything would need to be specified.
Regex can be used if it's a simple enough expression that would act like a whitelist, but more complicated expressions may reduce how effective the white list regex can be.
Below is some code on how a white list is used to replace bad characters.
```
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define MAX_INPUT_SIZE 21

int main(void) {
    //adding in newline to avoid confusion why there is a _ at the end
    static char ok_chars[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_-.@\n";
    char user_data [MAX_INPUT_SIZE] = "";
    puts("Enter something: ");
    fgets(user_data, MAX_INPUT_SIZE, stdin);
    printf("Original data:\n%s\n", user_data);

    /*
     * sanitization process
     * the way strspn works is by going through the given string and returning
     * the length when it finds an invalid character or null.
     * here we pass the string itself in with p and add length until the end
    */
    const char* end = user_data + strlen(user_data);
    char* p = user_data + strspn(user_data, ok_chars);
    for(; p != end; p += strspn(p, ok_chars)){
        *p = '_';
    }

    printf("Sanitized data:\n%s\n", user_data);
    return EXIT_SUCCESS;
}
```
#### Black Lists

A black lists specifies known restricted criteria.
The issue black lists are you have to know what to block, so it is incredibly easy to miss what to block.
If we look at SQL injections some known bad characters are `- ; ' "`, but there are many ways to create a SQL injection as this Github page shows [sql-injection-payload-list](https://github.com/payloadbox/sql-injection-payload-list).
Looking through that list, a potential injection could include the `#` or `=` character which we have not added to our black list.
Since there is no fail-safe to default deny like with the whitelist these characters will simply remain untouched.
The implementation of a blacklist is almost identical to a whitelist apart from the list and logic to favor detecting invalid state.
In this C example, the two changes from the whitelist example is the use of strcspn() rather than strspn() and the bad\_chars array.
With strcspn() it returns how many characters are before the first occurance of a given character in a list while strspn() returns the length of a substring it found with only acceptable characters.
```
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define MAX_INPUT_SIZE 21

int main(void) {
    static char bad_chars[] = "/@ ;[]<>&\t";
    char user_data [MAX_INPUT_SIZE] = "";
    puts("Enter something: ");
    fgets(user_data, MAX_INPUT_SIZE, stdin);
    printf("Original data:\n%s\n", user_data);

    /*
     * sanitization process
     * Notice is is strCspn and not strspn
     * strCspn works like strspn, but it returns the number of characters before
     * the first occurance of a letter in the second argument.
     * here we pass the string itself in with p and add length until the end
    */
    const char* end = user_data + strlen(user_data);
    char* p = user_data + strcspn(user_data, bad_chars);
    for(; p != end; p += strcspn(p, bad_chars)){
        *p = '_';
    }

    printf("Sanitized data with blacklist:\n%s\n", user_data);
    return EXIT_SUCCESS;
}
```

You may ask then why black lists are even considered an option if white lists are so much more superior.
In environments where input is known to have a valid restricted data set white lists are much better.
However, you don't always know the exact degree of all valid input.
The whitelist needs to say what is valid, and just with the alphanumeric list you can see the whitelist is much longer.
It may not be known what every valid input is, or it is not feasible to create a list of every valid input.
In this case a blacklist is used because it is a more simple and maintainable approach.
As an example, a firewall might allow any connection to a web server.
From just an IP address it cannot be determined if it is malicious unless it has already conducted suspicious behavior in the past.
Once it does something suspicious, it'll be added to a blacklist to be denied in the future.
Along the same line, if you know about pi-hole devices you know that they typically use a blacklist style blocking because there are almost limitless domains that are safe but some that are known to be mistrustful.
A whitelist style is the most secure method, but it would behave as a blacklist for usability since it would default deny anything not in the whitelist.
If you were conducting cooking research the whitelist would more than likely block a lot of cooking blogs due to its default behavior.
Really any kind of research would be troublesome since you would not know about domains until you find them.
As a result, who ever manages the pi-hole device will find themself adding more and more domains to a giant whitelist basically allowing almost everything anyway.
The whitelist approach would only work if the environment is restricted enough that it makes sense to only allow certain domains and nothing else.
In a home network with a family though, a blacklist is much more user-friendly not just for the users on the network but the resident IT person as well.
Since a blacklist only blocks what it knows about, domains that are known to be bad can be blocked allowing mostly benign domains through.
Of course the blacklist still has the same problem with allowing unknown malicious items through, but it's a cost for usability.
Another application where blacklists are used is for video game anti-cheats and antivirus.
Some work via searching for a known hash of a bad pattern or suspicious process which in effect is a blacklist.
There are simply too many processes that can be installed let alone created for a whitelist to work.
However, because of the major flaw with blacklists it is always an arms race between the opposing parties to break the anti-cheat/antivirus software and the people trying to find cheats and malware.
Hence, why this software went to the kernel level to try to limit the search to context switches.
Even though blacklists are the worst approach; they are actually used a lot more than you would think due to how dynamic things can be.

#### Output Sanitization

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

### Side Note

When you are conducting these steps **DO NOT ROLL YOUR OWN FUNCTIONS UNLESS NECESSARY**.
Most cases there will be a library to aid in the validation process.
For file paths, the language should supply a way to canonize a path because the process is complicated on your own.
C has realpath(), however be careful about PATH\_MAX definitions, and python has a few ways like os.path.realpath() and pathlib.Path().resolve().
Some languages or libraries may provide methods for sanitization as well.
Validation and normalization is little more up to you as that is getting down your understanding of data, but there may be some helper methods.
Of course make sure that these libraries are trustworthy and maintained, as you would not want to have a vulnerability from your escaping method becoming out of date.


## Source

Secure Coding in C and C++ by Robert C. Seacord

Secure Programming Cookbook for C and C++ by John Viega and Matt Messier

This similar code for the white/black list [SEI STR02](https://wiki.sei.cmu.edu/confluence/display/c/STR02-C.+Sanitize+data+passed+to+complex+subsystems)

