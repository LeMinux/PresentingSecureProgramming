## Taking Input

As a programmer, taking input is one of the first crucial skills you learn.
Each language does it differently, but if you started off with Java you quickly found out that using nextInt() and passing a string crashed your program entirely.
When the program did crash you had no recourse either, so you resorted to nextLine() to even have a chance to look at the input.
Very quickly you understood that you can't assume a user will abide by your rules, and it is something you have to enforce unless you want your program blowing up.
As programs become more involved, you then have to ask what exactly is input and the consequences of incorrect handling?
Input is not always in the form of human typed text.
The input may very well be some kind of electromagnetic wave like radio or light, or it could even be a file.
Failure to ensure input isn't malicious can exploit the program directly, or use the program to affect other systems.
These other systems can be databases, the OS, file systems, libraries, AI, and more.
While the best security approach would be to take absolutely no input at all, it's a bit foolish to have a locked up program like that.
We write applications because they are interactive, and it allows for that "just works" feeling.
However, in order to understand how to take input we must distinguish between what is safe and unsafe.
This is where trust boundaries come in.
A trust boundary is what surrounds a component where data used internally is trusted because it went through checks, but data that comes from outside the boundary is assumed to be untrustworthy.
Essentially, data going in or out at the boundary must go through a checkpoint to ensure it is valid.
Outside data is untrusted because once data is sent across other trust boundaries it loses its context.
This would even include checking data that comes from trusted components because trusted parts could be compromised.
All the process knows is to interpret data how it was told to.
For example, what handles database requests does not know the intention is to add a user.
It only knows to add a user once it interprets it as such assuming the data is not malformed.
This is why sometimes the output at the boundary is cleaned or checked because the current component understands how the next component will interpret the data it sends.
With the concept of a trust boundary, an approach of default skepticism can be taken.
Not all invalid input is the result of devious deviants trying to hack you of course.
Invalid input is often accidental, but it puts a mind set in place to expect invalid data.
As mentioned before, input can be in the form of anything.
It can mean the terminal, a form, JSON data, a binary stream, command line arguments, the network, or environment variables.
It really depends on the application and how the program takes in data.
The need for validation is quite evident, but the process is not always easy.
Each component knows what to do and how to validate in its own way, but this can mean each component has a different input handling process.
Depending on the input, extra steps may need to be taken to make validation easier.
There really isn't an agreed upon name or acronym that I could find for this process it's simply just understood in secure programming as input handling.
I suppose a more explicit name could be the secure input handling process, but that doesn't sound as nice.
To keep things less ambiguous by saying "the process" over and over I will refer to the secure input handling process as the S.A.V.E process.
Here the letters mean Simplify, Alter, Validate, and Edit, and are a one-word summary of a step in the secure input handling process.
Hopefully the SAVE process will also save your program from bad input :P.
The SAVE process includes the steps of canonicalization/normalization (Simplify), sanitization (Alter), validation (Validate), and output sanitization (Edit).
Not every step is strictly necessary, but the order these steps are conducted in is necessary.
You don't want to invalidate validation by normalizing afterward, or output sanitize then normalize.
The proper order is how it is listed in the SAVE acronym.
The reasoning for this order is because each step fulfills a specific role in how it handles input.
Conducting the steps out of order would invalidate any effort done, and more than likely lead to vulnerabilities.
Now let us get into the actual steps because a one-word summary alone won't tell you the little details.

### Canonicalization (Simplify)

- Definition: The process of reducing input to a singular, equivalent, and most standard form.

The canonical representation of something is the standard, most direct, and least ambiguous way to represent it.
The goal is to eliminate ambiguity of multiple representations of input into a single well-defined, equivalent interpretation.
This way the sanitization and validation functions only have to worry about checking the canon form rather than considering many other forms.
This simplifies security since input is enforced to a standard form that doesn't have a hidden trick up its sleeve.
But what exactly is a canonized form?
Well the answer to that question is highly specific to the situation and criteria.
Mathematically speaking, it is a unique representation of every object that can be used to check for equality.
However, when dealing with input unique is hard to define and depends on context.
A case-sensitive search would make `WHERE IS MY COLBY JACK` and `WhErE Is mY cOlBy JaCk` unique, but for a case-insensitive search they are the equal.
If we look at American phone numbers they can be in forms like `123-456-7890`, `1234567890`, `(123) 456-7890`, or `1+ 123-456-7890`.
These phone numbers have equivalent meaning, but what is the canonized form?
If we stick to a standard like E.123 it would be `+1 123 456 7890`, but if international representation isn't a concern it could be `234567890` which would be formatted later at output.
The E.123 would be the most standard way to represent it, but the international code can be inferred data from the customer's country which may not be needed in the format.
In a case like this there are technically many canon forms and the canonized form is simply what normal form is chosen.
This is why canonicalization and normalization may be interchangeably used in IT and computer science even if it annoys people.
You may also just annoy people by simply using the word canonicalization since the proper term would be canonize, but that's getting into too many details.
Trying to define the difference between canonicalization and normalization for nuanced details like this just unnecessary like folders vs directories.
To help in being more direct about meaning though, I find it a more appropriate to use canonicalization for when a standard says what is canon like with POSIX rules defining a canon file path and XML defining canon XML.
These standards at least say what that unique and most true form is.

#### File Paths
The de facto example for canonicalization is with file paths.
File paths only have one canonical form, so that makes things much more simple.
File paths can have a variety of paths resolving to the same file.
A file path can be an absolute path, a relative path, or a link.
Hard links are an interesting issue, but a canonized path refers to the path itself rather than the data blocks on disk.
Technically hard links ruin having only one path to a file, but it is not really a consideration for canonizing as it just so happens that two files paths are the same file.
The code block below shows just a few paths to get to a file like `/etc/passwd` which contains users on a Linux system.
```
passwd
./passwd
/etc/passwd
../../../../../etc/passwd
/../../../etc/passwd
//////etc/passwd
/etc/../etc/passwd
./etc/passwd
/./etc/passwd
/home/User/Documents/link_to_passwd
```
The canon way to represent this file on Linux would be `/etc/passwd`.
Conveniently enough it is also the absolute path to the file.
However, keep in mind that the absolute path to a file is not always the canon path because of soft links and relative traversal.
Additionally, symlinks can redirect with a relative path, so even resolving it could result in a non-canon path.
As a result, canonicalization would have to resolve symlinks and find the absolute path of what the symlink goes to.
If chained links were involved the canon path would go all the way down the chain, but a non-canon path could be any path leading to the end file or links in between.
Window file paths have canon paths as well that look like `C:\Documents\Reports\Summer2025.pdf`.
It has the drive letter, the colon, and the pesky backward slash to start at the root of the drive.
A path like `C:Documents\Reports\Summer2025.pdf` without the `\` after `C:` is not canon because it starts from the current directory on the C: drive.
Windows does have case-insensitive paths, but they do preserve the case.
The comparison itself done by the .NET file system API is case-insensitive though.
Then there are long and short (8.3 style) file names which means files have two names.
The 8.3 style can be disabled though.
Technically this means there is no canon path if you want to go by the definition, but it is treated as canon for windows.
Windows is known for being wacky, so I'll provide two Learn Microsoft docs that explains more about their paths
[File Path Formats on Windows Systems](https://learn.microsoft.com/en-us/dotnet/standard/io/file-path-formats)
[Naming Files, Paths, and Namespaces](https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file).

#### Canon URLs

URL canonicalization is as simple as suggesting to Google what is the best URL to use when URLs link to identical pages.
Website can suggest a canon URL with `<link rel="canonical" href="https://www.example.com/page">`, but Google ultimately decides what it is.
It is for Search Engine Optimization (SEO) to find your website and better optimize recommendations.
It's not a security tactic since the domains of "windows.example" and "vvindows.example" are different domains, and page itself would suggest a canon URL.

#### Websites

Then comes the absolute mess that the web is.
Since this is dealing with the web, other attacks using XSS, encoding, and UTF-8 are a concern.
All the attacks follow the same principle of trying to make data pass the checkpoint in the trust boundary.
Once it does, the data internally is assumed to be safe when it is not.
Encoding is a large issue it can be used to obfuscate characters when inspected at the checkpoint.
As an example, some malicious input may want to send `<script>alert(0)</script>` as an XSS attack.
On the first level of encoding this input turns into `%3Cscript%3Ealert%280%29%3C%2fscript%3E`.
Without reducing to a canon form, a validation or sanitization function checking for `<` or `>` will fail because it is actually `%3C` and `%3E`.
Similarly, this can apply to path traversal attacks by turning `http://victim/cgi/../../winnt/system32/cmd.exe?/c+dir+c:\` into `http://victim/cgi/%252E%252E%252F%252E%252E%252Fwinnt/system32/cmd.exe?/c+dir+c:\`.
The fix for this would be to decode the input, but attackers know this, so they may encode the input twice or even many times.
For double URL encoding, it turns all the `%` into `%25`.
Double encoding would thus turn `%3Cscript%3Ealert%280%29%3C%2fscript%3E` into `%253Cscript%253Ealert%25280%2529%253C%252fscript%253E`
It just has to be decoded twice further up to then become the payload `<script>alert(0)</script>`.
Normally you want to decode a single time, but if additional decoding were to happen automatically or unknowingly in a module after the initial decoding it allows this attack.
There are many ways to encode data which is the biggest challenge, and nothing prevents you from using multiple encoding styles in the same input.
If you know that a sanitization script checks for `alert(` and you want to use it in HTML encoding then the l turns to `&#6C;`.
URL encoding turns that same l to `%6C`.
There is even stupidity in HTML encoding allowing stuff like `&#00000000000065` which is just 'e', but any amount of leading zeros can exist.
If you want to get fancy you may even do `&bsol;u0061` which decodes `&bsol` to `\` then creating a unicode escape of `\u0061` which is 'a'.
What ever encoding is used depends on what is going to interpret the data whether it's the URL, HTML, JavaScript, etc.
This is really tough problem, so how is this handled in this step?
Each situation is different, but remember this step just concerns itself with creating a standard form.
The simple solution is to decode just once, and use the next steps to find out if input is valid.
You can decide to decode until the original text is given, but depending on the encoding scheme this can be a DOS attack.
Don't be concerned with trying to obtain the original input.
The later steps are there to find out if input is invalid.

### Normalization (Simplify)

- Definition: The process of reducing input to a more simple or expected form typically for consistency

Normalization and Canonicalization are similar but not the same.
Canonicalization is a subset of normalization since canonicalization resolves to a single unique normal form while normalization reduces to some normal form.
Normalization still contains steps to clean or transform data, but it is done to bring a more consistent or simple form rather than a unique form.
Since normalization is not intending to reduce to a singular unique form, you have to be careful about how it is done.
Do not combine normalized input with non-normalized input or normalize partial input as it can create segments that are not normalized.
When you do normalize, this can include
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
These same actions can also be conducted in canonicalization, but whether it could be called normalization depends on context.
If we take the input of `A WaSp` and change it into `a_wasp`, or `A hive\n` into `A hive` which process was used?
I'd say the intention is normalization, but you could call it canonicalization if the normal form results of `A WaSp` and `A hive\n` are the most standard and completely nonambiguous.
This is getting too much into terminology though, and sometimes you don't care about what the canon form is and just need consistency data.
Yes, the canon form is the most consistent and best for comparison, but that is assuming there is a canon form to have.
A canonical form of a JSON would include having the exact same order of elements and no duplicates, which would be necessary for hashing, but isn't always needed.
Perhaps you just want to remove redundant characters instead of sorting everything and then simplifying.
Some fields like data science benefits from normalization especially with AI depending on consistent data.
This can involve scaling numerical data in some way to reduce bias or trying to combine data sets in a way that can be meaningfully analyzed.
For more interactive text based AI, this may involve creating consistent spacing of text since the text has to be tokenized.
UTF-8 has an interesting case where data can be canon, but is not normalized since there are two canonical forms.
Since the form is already canon, normalization would then have to decide between the two as well as ordering of marks.
What ever wacky situation you get into would call for what ever is needed, so don't get so worried about technicalities.
What is important is that you realize that either part of the S in SAVE is needed in your process.

### Sanitization (Alter)

- Definition: The process of ensuring that data conforms to the requirements of the subsystem that uses it.

When data has to transfer between systems or trust boundaries the interpretation of data can change.
This is why SQL injections happen because the database interprets the data differently than the app.
Command prompt injections from C code using system() would also apply as the shell interprets the data differently.
XSS injections use the web's own interpretation against itself.
Basically anytime you have a situation where data can be interpreted differently as a result of crossing a boundary you want to sanitize.
It's kind of like a game of telephone except the consequences of a misinterpretation means a brand new CVE.
This would of course require an understanding on how data can be interpreted between systems, and how to prevent misinterpretation.
In order to prevent this misinterpretation you may be required to alter the input to avoid it.
The main techniques of sanitization include removing, replacing, encoding, or escaping characters based off a list.
Each of these techniques have their uses which depends on how invalid characters should be handled, and how much of the original content should be preserved.
Keep in mind though you don't always need to sanitize.
Sometimes you can deny input that would require sanitization as a step in validation.

#### Encoding & Escaping

Escaping preserves the input, but provides a greater risk if done incorrectly.
As an example, a naive approach would escape `'` to `\'`, but if the input were `\'` it would turn into `\\'` which escapes the escape.
This does provide the best user experience as why shouldn't a username be `\<script\> alert(0) \</script\>`.
With proper escaping a user can since it'll treat the name as data.
If you are dealing with a database, prepared statements cover this work since the variable is never part of the statement and is strictly treated as data.

Encoding falls in the same camp as escaping, but it's a very specific kind of encoding.
This is not encoding like base64, but encoding used as a type of escape.
Specifically for avoiding XSS it would encode `<` and `>` into `&lt` and `&gt`.
Remember there are many kinds of encoding as covered in the canonicalization section, so use what is appropriate.

#### Removal & Replacement

If you do not care about preserving the original content removal or replacement can be done.
Replacement would simply swap a bad thing with a known good thing like replacing a space with an underscore.
It tries to preserve the intention and is not as aggressive as removal.
Removal deletes the bad character entirely.
Removal can be used for strict enforcement like enforcing only numerical data.
With these techniques though, keep in mind that the data is manipulated much more drastically.
It can be possible to have your sanitization process inadvertently create malicious data due to it being so aggressive.
A pretty funny way I've gotten around input sanitization for a project was to simply split the word with the very thing that will get removed.
If the sanitization removed script tags like `<script>` and `</script>` Input like `<scr<script>ipt> alert(0) </scr</script>ipt>` would turn into `<script> alert(0) </script>`.
In this case the sanitization for the project was too aggressive on a specific thing, and it missed the real problem of the less than and greater than symbols.

#### Output Sanitization (Edit)

Input sanitization works when it is known what can be changed about input, so later on it isn't an issue.
However, the input may be sanitized for its context, but is still malicious for its highly specific output context.
As an example, `<script> alert(1)</script>` is perfectly fine for a SQL database, but dangerous if sent to be rendered by HTML.
You may try to use input sanitization to remove the arrow brackets; however, this may not be desirable as it can destroy the original data resulting in a negative user experience or unreliable data.
The destruction may be acceptable if it is known for sure it'll never be used, but situations that call for dynamic behavior on the same data can't make this guarantee.
It may not be known what to do with data until it gets near the point of usage because it is only then context given on how it will be interpreted.
In these situations output sanitization is conducted as a way to slightly edit the data to be more acceptable.
Both input and output sanitization have the same principle of creating data that is safe to pass through a boundary; it is just where that data is handled that is different.
Output sanitization changes the data in a way to make it safer to be displayed or sent out to what ever.
You'll probably see that output sanitization is the preferred method, especially if it's in the context of web development, but keep in mind that the SAVE steps are context specific.
You may very well may have to conduct input and output sanitization if the situation requires it.
As an example, a website that allows users to post text would want to include any typeable character for user convenience.
In this case the programmer would prefer to keep the user's input unaltered because why shouldn't a user be able to type script tags.
Now the programmer could still conduct input sanitization by removing unprintable non-control characters and use a parameterized query.
Once the data is obtained from the database, while it is still in memory and not set to be interpreted it will be output sanitized.
Characters like `< > ; = ' "` are valid typeable characters, so the sanitization would need to encode/escape these characters to avoid attacks like XSS.
This is just one possible example.
Output can go to literally anything, and there are even attacks that can be made off the attributes tags of HTML if that's the output.
Once the data has left the component and past the trust boundary that is it.
Output sanitization is that last check double check you said would be the last one to ensure the data is safe while it is still in your control.

#### White Lists

A white lists specifies only allowable criteria.
This is generally the most safe approach because there is a failsafe to default deny unexpected characters.
Since you are only concerned about what you know is valid, there isn't a risk of forgetting to add something that is invalid like with a blacklist.
If a character was thought to be malicious, but is actually benign then it simply gets added to a whitelist.
This does create larger lists since alphanumeric characters are acceptable in most cases and everything would need to be specified.
Regex can be used if it's a simple enough expression that would act like a whitelist, but more complicated expressions need more special care and testing.
Below is some code on how a white list is used to replace bad characters.
```
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define MAX_INPUT_SIZE 21

int main(void) {
    //adding in newline to avoid confusion why there is a '_' at the end
    static char ok_chars[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_-.@\n";
    char user_data [MAX_INPUT_SIZE] = "";
    puts("Enter something: ");
    fgets(user_data, MAX_INPUT_SIZE, stdin);
    printf("Original data:\n%s\n", user_data);

    /*
     * sanitization process
     * the way strspn works is by going through the given string and returning
     * the length when it finds an invalid character or null.
     * Basically how long is a substring containing only valid characters.
     * here we pass the string itself in with p and add length until the end
    */
    const char* end = user_data + strlen(user_data);
    char* p = user_data + strspn(user_data, ok_chars);
    for(; p != end; p += strspn(p, ok_chars)){
        //example of replacement
        *p = '_';
    }

    printf("Sanitized data:\n%s\n", user_data);
    return EXIT_SUCCESS;
}
```
#### Black Lists

A black lists specifies known restricted criteria.
The issue black lists are you have to know what to block, so it is incredibly easy to miss what to block.
If we look at SQL injections a blacklist could look like `- ; ' "`, but there are many ways to create a SQL injection as this GitHub page shows [sql-injection-payload-list](https://github.com/payloadbox/sql-injection-payload-list).
Looking through that repo, a potential injection could include the `#` or `=` character which we have not added to our black list.
Since there is no fail-safe to default deny like with the whitelist these characters will remain untouched.
The implementation of a blacklist is almost identical to a whitelist apart from the list and logic to favor detecting invalid state.
In this C example, the two changes from the whitelist example is the use of strcspn() rather than strspn() and the bad\_chars array.
With strcspn() it returns how many characters are before the first occurrence of a given character in a list while strspn() returns the length of a substring it found with only acceptable characters.
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
     * the first occurrence of a letter in the second argument.
     * here we pass the string itself in with p and add length until the end
    */
    const char* end = user_data + strlen(user_data);
    char* p = user_data + strcspn(user_data, bad_chars);
    for(; p != end; p += strcspn(p, bad_chars)){
        //example of replacement
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
However, in the realm of sanitization where it wants to remove malicious intent you more than likely won't see blacklists.
The usage of a blacklist would fall closer to validation to test if something is known to be bad.
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
However, because of the major flaw with blacklists it is always an arms race between the opposing parties to break the anti-cheat/antivirus software and the people trying to create cheats and malware.
Hence, why this software went to the kernel level to try to limit the search to context switches.
Even though blacklists are the worst approach, they are actually used a lot more than you would think due to how dynamic things are.

### Validation (Validate)

- Definition: The process of ensuring that input data falls within the expected domain of valid program input

Validation of input means to check if input or behavior falls within the realm of acceptability.
This can mean validating a certain size, variable type, only numbers, only letters, a specific format, no integer overflow potential, or checking for empty/NULL.
If data checked does not match the criteria of what the component deems as acceptable it is immediately dropped and is not processed further.
As mentioned before, this kind of behavior can forgo input sanitization by understanding that if input needs to be sanitized it can be denied instead to not risk bugs in sanitization.
A default deny rule can still be in place with a whitelist, so it really depends on if sanitization is actually necessary.
Sanitization is still a crucial step, but rejecting data rather than trying to filter is much more simple.
Validation is the main decision factor on if a process goes any further into the core of component or even to another component.
Hence, why it is such an important step because it's the last step before data is actually used.
Since it is such a crucial step, where validation is conducted matters.
It should be conducted in a trusted place.
Standard programs will simply conduct the validation internally adhering to the SAVE order.
For client-server models, it means conducting server side validation.
Even if the frontend checks for bad input, an attacker could avoid that interface entirely and send data directly to the server.
This isn't to say that client side validation is useless, but more so that the server should be the main defense as the server is what interacts with the core systems.
Essentially, this will mean copying the validation that is on the frontend to the backend.
However, even input from a trusted source must be validated.
An attacker could compromise what is trusted to send malformed data which blind trust would risk exploitation.
Chances are though there was a bug on the server side which sent unexpected data.

#### Functions

Now remember that validation does not have to strictly limit itself to just user input.
Although it is the most common perception of validation, validation can be conducted on if a process indicates success or on function arguments.
Essentially validating that the program is running as expected much like rule 7 in NASA's power of 10 if you read that.
Often times when people are learning to program they aren't told to validate function parameters.
It makes sense though as everything is assumed to be created and tested by a trusted source (you the programmer), and if faulty input was given it's not the function's fault.
However, as mentioned before blind trust is bad.
You can think of each function having their own trust boundary where input for the parameters comes from the outside.
This can be especially true if it's a helper method called from multiple places.
Just like with any other trust boundary, outside input should go through the SAVE process.
Although, sometimes naive functions won't have a trust boundary and will simply accept anything given to it.
For these functions SAVE is conducted before calling it.
Remember, not every step in SAVE is needed, so validation may be the only step needed.
An argument can be made for making naive functions because parameter validation can incur unnecessary performance cost, and the caller should know what is invalid.
This principle is what many C functions follow, but this results in many checks all over and free rein for vulnerabilities to slip by.
Validation inside the callee places validation in a single spot and conducts checks much more consistently.
For this reason, it is recommended that the called function validate its parameters so that function can at least survive/catch some improper usage.
Likewise, the caller should check the return value if it indicates an error so that incorrect behavior that is caught isn't ignored.
C also has a habit of doing this.

#### Assertions

Assertions are not a way to conduct input validation.
Assertions are meant as a tool to validate the programmer.
Validation is a test conducted at runtime to find if unknown data is acceptable since input is unpredictable.
Assertions don't do this because it tests assumptions in internal logic that should always remain true.
You would assert if a string is NULL, and validate if the string length is less than x.
The assert for NULL is done since the programmer has control over the variable containing a value.
If the programmer made a logic error that skipped users inputting into this variable the assert would catch it.
The reason asserts shouldn't be used as validation is because they are removable.
You wouldn't want your validation getting yoinked out by a compiling flag.
The assumption is that if none of the asserts were triggered during testing then the program's internal state is fine.
However, if we look at the NULL assert example a few sentences ago, you may want to validate for NULL rather than assert.
It really depends on if the function is public/private and what the parameters are expected to be.
NASA has a whole rule on their usage of asserts which can be found in the NASA Power of 10 RuleSet chapter.
In short, assertions help enforce the design by contract principle since that is for the programmer to abide by.

#### Numeric Values

Numeric values require a little extra care when given.
There is of course the standard check for bounds, but overflows can occur if that isn't checked.
Overflows are a sneaky little bug that can occur in a variety of ways.
There is obviously arithmetic, but there is also type promotion and signedness which can hide some bugs.
With these more specific cases vulnerabilities can squeak by even when conducting proper validation.
Validation can't fix this though as it would be an issue of validation given the incorrect type to compare with.
It's not the fault of validation if the checks assume unsigned numbers, but allows for signed numbers without enforcing unsigned numbers.
This section won't cover the vulnerability of integers since that's in another chapter, but just know it is something to validate for.

#### UTF-8

Originally I was going to have a section explaining UTF-8 and how to validate it, and why it would be better to drop invalid UTF-8 than change it.
However, trying to explain how UTF-8 worked revealed it's a whole other can of binary worms, so I created a separate chapter for it.
Understanding UTF-8 is essential for the web since every website uses it.
UTF-8 has some quirks that allows for techniques similar to double encoding trying to hide characters but leaving the same interpretation.
It is actually mentioned in RFC 3629 overlong sequences can be used as a path traversal attack, so make sure that you are dealing with proper and valid UTF-8 before messing with it.

### Conclusion

When you are conducting the SAVE steps **DO NOT ROLL YOUR OWN FUNCTIONS UNLESS NECESSARY**.
Don't try to reinvent UTF-8 validation or canonization of a file path.
Most cases there will be a library or function to aid in the SAVE process if it's complicated.
Of course make sure that these libraries are trustworthy and maintained, as you wouldn't want a vulnerability from your escaping method becoming out of date.
It may not be an option all the time, so having to create your own may be necessary.
This is also why you should extensively test the SAVE functions because input is practically infinite, and you only want a segment of that infinity.
Remember that not every step of the SAVE process has to be conducted.
It is just the order the steps that are conducted that is necessary.
Oftentimes you may only conduct validation, and that's fine.

## Sources

Secure Coding in C and C++ by Robert C. Seacord

Secure Programming Cookbook for C and C++ by John Viega and Matt Messier

Code for the white/black list [SEI STR02](https://wiki.sei.cmu.edu/confluence/display/c/STR02-C.+Sanitize+data+passed+to+complex+subsystems)

[OWASP XSS Prevention](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)

[OWASP Double Encoding](https://owasp.org/www-community/Double_Encoding)

[Obfuscating Attacks Using Encodings](https://portswigger.net/web-security/essential-skills/obfuscating-attacks-using-encodings)

[RFC 3629](https://www.rfc-editor.org/rfc/rfc3629)

[Google Canonical URL](https://support.google.com/webmasters/answer/10347851?hl=en)

[Specify a canonical URL](https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls)
