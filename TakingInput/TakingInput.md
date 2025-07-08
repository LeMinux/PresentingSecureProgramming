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

- Definition: The process of lossless reduction of the input to its equivalent simplest form

The goal of this process is to turn ambiguity into a single well-defined equivalent interpretation while keeping the original intention.
If two different inputs resolve to the same output, then their canon result should be equal.
Canonicalization is most often seen with file paths and URLs.
Since file and URL inputs can have many forms of saying the same thing it is necessary to reduce them to a single accepted and equivalent form.
For file paths there are many paths you have to concern yourself with absolute and relative paths that can resolve to the same file.
The code block below shows just a few ways to get to a file like `/etc/passwd` which contains users on a Linux system that everyone can read.
```
passwd
/etc/passwd
../../../../../etc/passw
//////etc/passwd
/etc/../etc/passwd
./etc/passwd
```
The canon way to represent this file on Linux would be `/etc/passwd`, so a canon function should resolve all these inputs into `/etc/passwd`.
However, once symlinks join the party `/etc/passwd` may not be the actual canon path, so the symlink would need to be resolved to find the canon path.
Although, it is the programmer's decision if they want to accept symlink resolution, or simply return an error for invalid input.
Window file paths have absolute paths as well that look like `C:\Documents\Reports\Summer2025.pdf`.
It has the drive letter, the colon, and the backward slash to start at the root of the drive.
Of course Windows is Windows, so this website from Microsoft explains more about their unique paths [File Path Formats on Windows Systems](https://learn.microsoft.com/en-us/dotnet/standard/io/file-path-formats).

For URLs thing are even more tricky.
There are two kinds of canonicalization for a URL.
There is the one similar to how files are handled where the URL specifies a path, and a URL that Google uses to determine a singular resource.
The canonicalization for Google more so defines what it thinks is the most canon representation.
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
This kind of canonicalization is more so for Search Engine Optimization (SEO) to find your website and better optimize reccomendations.

When you are dealing with your own website, the same principle of canonicalization still stands, but there are more attacks to consider.
It is not just file traversal attacks but also XSS attacks, double encoding attacks, and UTF-8.
In order for sanitization to work effectively, the input needs to be converted to the canon form.
Encoding is a large issue as double encoding can be used to obfuscate intent, or one level of encoding can be used to mask a character.
As an example, some malicious input may be `<script>alert(0)</script>` as an XSS attack.
On the first level of encoding this input turns into `%3Cscript%3Ealert%280%29%3C%2fscript%3E`.
Without reducing to a canon form, a validation or sanitization function only checking for `<script>` will miss it because it is actually `%3Cscript%3E`.
The fix for this would be to decode the input, but attackers know this, so they may encode the input twice or even many times.
This turns all the % into %25, but it is still equivalent to the original text.
Using the previous example this would turn `%3Cscript%3Ealert%280%29%3C%2fscript%3E` into `%253Cscript%253Ealert%25280%2529%253C%252fscript%253E`
This XSS example would of course apply to path traversal attacks by turning `http://victim/cgi/../../winnt/system32/cmd.exe?/c+dir+c:\` into `http://victim/cgi/%252E%252E%252F%252E%252E%252Fwinnt/system32/cmd.exe?/c+dir+c:\`.
This specific example for path traversal was found at this OWASP guideline [OWASP Double Encoding](https://owasp.org/www-community/Double_Encoding).
Hopefully you can see why canonicalization is done first before sanitization and validation.

Now the examples given before are just for HTML encoding.
When you are dealing with international clients, or simply want to be up to standard UTF-8 is going to cause so much trouble.
UTF-8, just like with file paths, has many ways to represent the same character.
This is more so a fault in the design of the standard than an issue of encoding.
The standard does give a way to detect manipulation luckily.


### Normalization

- Definition: The process of lossy conversion of input data to the simplest or expected form

// find out the exact different in normalization and canonicalization

### Sanitization

- Definition: The process of ensuring that data conforms to the requirements of the subsystem to which it is passed.


#### Escaping

- Definition: 

Escaping input should only ever be reserved for cases where the realm of valid and malicious input have so much overlap that a system can expect to take bad tokens in certain cases.
The best way to avoid the risk of taking bad input is to simply not take it hence why the other methods above are better.

#### Output Sanitization

### Validation

//talk about validation before callign methods sometimes

- Definition: The process of ensuring that input data falls within the expected domain of valid program input

Validation of input means to check if input given falls within the realm of acceptability.
If input does not match the criteria of what your program deems as acceptable it is immediately dropped and is not processes further.
Once again, validation is the main decision factor in if input goes any further.
In certain cases sanitization may not be needed because if the input would require active sanitization then it can be denied.
Function arguments must always be validated or asserted.
When assertions vs validation should be conducted can be a fine line, but remember that assertions are for programmer mistakes.
Typically, it would mean asserting not NULL.


## Source

Secure Coding in C and C++ by Robert C. Seacord
