# NASA's Power of 10

## Description

NASA's Power of 10 is very powerful set of rules.
It is well known for it's strict rules tailored to creating saftey critical code.
Howevever, the emphasis is on **saftey critical C code**. Most programmers are not
developing saftey critical code, and most languages can't implement
every rule. Additionally, these rules do not explicity go over input sanitization or overflow checks.
Despite this, I feel it is at least important to know what rules you can implement given your circumstance.

Below is my interpretation and my personal take for NASA's rules. I understand most programmers
are not coding rovers or satellites, so not every rule may apply especially considering your language.
I would still suggest to read NASA's reasoning though as it provides insight into their expectations.

## Note For Other Languages

Not every language can follow all 10 of these rules. Weakly typed and OOP languages make it impossible to avoid the HEAP, and some
languages abstract away pointers. NASA has their reason for avoiding garbage collecting languages.
Despite this, most languages should be able to follow all but 3, 9, and 10. Rules 9 and 10
are a little iffy based on the language. Weakly typed languages can't follow rule 10 as they don't know the data type. Imagine launching
a rover in Python and it turns out you forgot to test a branch containing a type error. Rule 9 can also be harder to follow since
some languages abstract pointers and dereferencing is implicit.

### 1. Have a clear simple control flow

I like to think of this rule as having a clear path of branching.
Logic errors are the result of improper handling of branching, so if
you can make your flow more "laminar" and explicit it's easier to test and audit.
This includes early exiting from a function as it's more often the simplest solution.
This way you avoid unnecessary holding values and checks.

NASA in this rule also bans the use of goto, setjmp, longjmp, and recursion. I feel these were added
to help fix errors quickly. In the event of troubleshooting an error removing these constructs can help find it more quickly.

NASA avoid recursion as they must have certainty in boundedness. Embedded systems deal heavily with the stack, and they don't have much storage.
What I like to call the "recursion tax" where each method call adds its parameters, return pointer, and frame to the stack
can pass the bounds of the stack if the tax becomes too much. You also don't know when the recursion
will end. All you really know is that it should eventually reach the base case.
It can also be more difficult to troubleshoot as you now need to figure out how all these calls connect.
This doesn't mean if you're not using an embedded system you shouldn't worry.
Imagine a server running in an infinite loop using indirect recursion slowly using more of the stack,
but not returning back to the original calling function. Eventually the process accesses out of bound memory and the OS must kill the process.
I do recognize the usage of recursion, some problems may just be too complex for iterative implementations.
I would say to avoid using recursion if you can. You could implement linked list traversal as recursive, but an iterative solution is more simple and contained.

Setjmp and longjmp make sense as well given the embedded environment. it's like using a super sized out of scope goto.
I haven't used them, and I haven't had the need for them. Supposedly they are useful for getting out of deep errors. 
However, now you jumped back to a state with all the stuff you've just done.
You haven't reverted the code at all you have just jumped back to a section in the text segment and set the stack pointer to where it was at that state. Now
the programmer is left in a state where they can't free, close, or clean what they've just done. Now yes if you plan to immediately exit it might be fine, but
if not you leave yourself in a bad state.

Goto is a little weird. I've seen some valid uses for goto like to jump to handling errors, but I feel its usage should be minimal if at all.

### 2. Give all terminating hoops a fixed upper bound

Notice this says "terminating" loops. These are loops that are not expected to run forever.
Non-terminating loops should be verified they won't stop like waiting for network requests,
and there should only be one non-terminating loop per thread/task.

This rule mostly applies to loops that have a variable number of iterations. Examples would be traversing a linked list
or traversing a string. The max should be related to your assumptions on what would be an unreasonable amount of iterations.
If you are dealing with file paths what is the maximum length a file path can be?

However, in general programming you might have some while(true) waiting for some condition to exit.
In this case you would want to test that only that condition can terminate the loop.
You may have it so only a signal like SIGINT (CTRL + C) can be the only option
to terminate, but how secure this would be depends on your environment and implimentation.

Async functions I think should also fall under here. I didn't see anything about
asynchronous functions in NASA's documentation, but it is a common practice to set
a timeout for asynchronous things. This way your program won't hang there waiting, and you can return an error.

### 3. Do not use dynamic memory after initialization

This rule can be especially hard to follow, but it has its reason.
It's a common rule for anything saftey critical.
The rule aims to completely avoid all the issues the come with using the HEAP.

Things like
```
use after free
forgetting to free memory
using too much memory
buffer overflows in the HEAP
unreliability of garbage collectors
undermining ASLR protection
etc...
```

I would also like to add that alloca() should never be used. Each compiler implements it differently and it has no error status return.
Alloca() is described here https://www.man7.org/linux/man-pages/man3/alloca.3.html

This rule is especially tailored to embedded systems that NASA uses. You really wouldn't want to deal with fragmentation and
best fit algortithms in a system that already doesn't have a lot of memory. The most efficent use of memory is leaving no
gaps which is what the stack does.

So how exactly would someone take dynamic input? There are a couple of ways.
1. Set some maximum bound
2. Object pools
3. Ring buffers
4. Arenas

Now of course NASA doesn't accept input in the traditonal sense. I would say for your tradional apps to avoid using dynamic memory when possible.
Try to not fall into the trap where you must take exact sizes of the user's input. You will want some bound or else your user input will take the
entire memory of the OS.

### 4. Function Length should be printable on a page with one statement per line

RIP all the Java and C++ users :P
This rule basically says to keep your functions smaller for easier auditing. Tiger Bettle also uses this rule and they have their limit at 80.
I personally like to have the limit at 80 because if the function goes past 80 lines there may need to be reconsideration on branching. Now
this rule applies to the actual code and not comments, but if you need to have a paragraph comment to explain something probably rethink it.
Your code should also be clear just on its own, so I would like to add to this rule to keep variable names clear. Tiger Bettle
has their own style on function names.

It also suggests to have one line per statement. Honest to god if you have an if statment spread over 3 lines please
reconsider your logic.

If you have troubles with trying to condense functions, TigerBettle suggests to keep your branching,
but the contents of the branch can be added into its own method. Also look for any repitition.

### 5. Assertion density should average 2

If for what ever reason you hate all the other rules this rule you can't hate. Assertions act on your assumptions.
Basically think of you putting yourself into the code to check one assumption you know must be true.

Proper usage of assertions can be confusing though.

This rule goes hand in hand with rule 7 in checking your parameters.

### 6. Variables should be declared in their lowest scope

In C this is the best way to accomplish data hiding.
It also makes debugging easier, and reduces the surface area of things to corrupt.
This rule works well in combination with rule 3 since once the function is done the stack
is cleared of its work, and doesn't leave crumbs.

### 7. Check all return values of non-void functions and validate passed in parameters

This is the most forgotten rule and is very helpful to catch bugs.
In the most extreme cases you would be checking the results of printf, but NASA
says in cases where the return doesn't matter to case as void
so this -> (void)printf("%s", "Hi")

You should also check the parameters passed into the function to ensure they are usable.
Weakly typed languages may have a more difficult time with this, but I think the types 
should be validated. That might just be the strongly type bias in me though. To be fair though
you're making an assumption that this variable is a certain type, and you should assert your assumptions.

### 8. The preprocessor should be left for simple tasks like includes and simple macros

The preprocessor can make debugging more difficult since it obfuscates the actual value.
Remember the preprocessor is basically just copy and paste, so debuggers will see the value
8 instead of LENGTH_MAX.

This rule also advises against variatic arguments (like with printf), token pasting, and recursive macros.
I gotta be honest recursive macros just sounds evil.

NASA also says to avoid conditional compilation if possible since it makes exponentially more test cases. 

### 9. Pointers should only use one level of dereferencing

This rule also discourages heavily the usage of function pointers. The justification makes sense as how exactly does a static
analyzer even know where to go.

Levels of dereferencing can be confusing too. I've seen people deal with quadruple pointers and thinking how did they even get there.
Structs can help, but they can either increase confusion or lessen it. This rule doesn't prohibit multi level pointers, it just says be smart about them.
If you do need to dereference more than one level I would say to have a middle variable to keep intention clear.

<probably use a linked list example instead>
char** array_of_strings = {. . .}
char* string_from_array = *(array_of_strings + x)
char first_letter = *string_from_array

instead of 
char** array_of_strings = {. . .}
char first_letter = *(*(array_of_strings + x))

Yes you could use array subscript notation, but this is just an example. 

### 10. Compile with all pedantic flags and all warnings

This depends on the compiler and is more suited for strongly typed languages.
for gcc there is `-Wextra -Werror -Wpedantic.`
There is also a built in ASAN in gcc by using `-fsanitize=address`

NASA uses `gcc –Wall –pedantic –std=iso9899:1999`

There are also other flags like
```
-Wtraditional
-Wshadow
-Wpointer-arith
-Wcast-qual
-Wcast-align
-Wstrict-prototypes
-Wmissing-prototypes
-Wconversion
```

## Sources

[Nasa's Power of 10](https://web.eecs.umich.edu/~imarkov/10rules.pdf)

[JPL C Coding Standards](https://yurichev.com/mirrors/C/JPL_Coding_Standard_C.pdf)

[Tiger Bettle]()
