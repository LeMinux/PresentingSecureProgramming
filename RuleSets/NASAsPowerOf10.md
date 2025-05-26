# NASA's Power of 10

## Description

NASA's Power of 10 is a very powerful guideline with 10 simple rules tailored to developing safety critical software.
This is software where failure can risk harm to people or the environment, or where equipment serves a vital role that can't be lost.
However, nothing says these rules can not apply to less extreme scenarios.
In a broad sense, it is software where people depend on correct implementation to avoid catastrophe.
One example, is TigerBeetle using these rules for online transaction processing for businesses.
Businesses may not be considered saftey critical, but they have business critical components that must stay operable to avoid heavy loses.
For these cases that require a focus on secure programming, NASA's Power of 10 is fantastic guideline.
However, one big caveat is that NASA's Power of 10 is **NOT** all encompassing on secure programming.
Its purpose is to act as 10 simple, memorable, and effective guidelines to help in creating reliable and robust code.
These rules do not go over how to avoid vulnerabilities or other best practices which is why you should read security standards for your language.
Speaking of languages, keep in mind that these guidelines focus on **safety critical C Code**.
This means some of NASA's justification relates to the woes of C and how to make C safer.
This results in people hardening their mind to these rules, but I believe people should not.
NASA has their requirements because failure results in a lost rover, but you're requirements may not be as strict.
In the general case these should be treated as guidance rather than strict adherence.
Some rules apply to C-like languages while other rules are simply good practices to have for any language.
So despite this one catch, I feel it is important to read NASA's power of 10 for the fact it alters your mind to be more defensive and considerate on how you program.

//MENTION EMBEDDED SYSTEMS
Below is my commentary along with NASA's word.
Due to the fact that these are short, safety critical guidelines it will of course not explain everything.
This is why I wanted insert my own piece of thought to explain further what these rules mean.
I will take a stance that will focus more on how these rules can be applied in a general programming sense.
This will of course mean a more relaxed stance on some rules for the sake of being more applicable, but it does not mean the rule can not be implemented.
Taking a wider approach, although less restrictive in nature, does allow a conjuring on how these rules would apply to situations not explained in these guidelines.
NASA has their reasons and I wanted to see how well their reasons would translate into a typical programmer.
Of course their reasoning relates to C so naturally I will show C examples.
Now there is the consideration that these documents are pretty old.
NASA is probably using some other guideline that we don't know about.
It probably takes principles from the Power of 10 and JPL Coding Standard, but I don't know exact details.

I recommend that you read the sources to gain more incite into NASA's reasoning.
Especially so if you want to read their rationale which I have purposely avoided so you would go read :P.
For example, a lot relates to static analysis.
The NASA power of 10 doc that most people see is a good document, but it is a little out of date.
The JPL C Coding Standard comes after the Power of 10 document and refines some of the original rules.
Once again, I would heavily suggest you read the documents provided in sources.

## The Rules

### 1. Restrict code to very simple control flow constructs

This rule in combination with 4 and 6 helps create clean code that's easy to audit for humans and tool-based analysis.
Readable code is considerably easier to make secure and maintain.
A simple control flow can reveal logic errors that otherwise could have remained hidden.
Basically, the rule aims to make control flow as explicit as possible especially for static analyzers.
If a static analyzer is unable to understand the control flow NASA says to rewrite to code so that it is understandable.
To accomplish this goal, NASA bans the usage of goto, setjmp, longjmp, and recursion.
Additionally, NASA is perfectly okay with multiple exit points from a function.
They say a single exit point can simplify control flow, but an early exit can often times be the more simple solution.
Such cases would be validation of parameters or abiding by the fail fast principle.

#### Break & Continue

From what I read, NASA did not say anything about break or continue statements.
Now of course breaks are completely fine in switch cases it is more so its usage in loops that are of concern.
MISRA C 2004 states a rule that bans continue and rescinded a rule banning break, but this was made in 2004.
These two statements are strictly limited to loops, so they are not as devious as goto or setjmp/longjmp.
They act as a shortcut to end the loop or start a new iteration, so their effect on flow are understood.
Of course like any tool it can be abused to make unreadable code.
This is especially true when they are used in nested conditionals in a single loop like so.
```
#include <stdio.h>

int main(void){
    for(int i = 0; i < 10; ++i){
        if( i > 5 ){
            if( i > 6 ){
                if( i > 8 ){
                    break;
                }
                printf("Loop count is %d\n", i);
            }
            continue;
        }
        printf("Loop count is %d\n", i);
    }
    puts("Out of loop.");
}

Output:
Loop count is 0
Loop count is 1
Loop count is 2
Loop count is 3
Loop count is 4
Loop count is 5
Loop count is 7
Loop count is 8
Out of loop.
```
This is a silly example, but it's to show that deep breaks are problematic.
However, proper usage can increase readability.
Typical use case are leaving a loop early once a specific condition occurs, or loop and a half cases.
Finding a specific value in an array, or calling a function in a standard for loop that can return an error.
It may not make sense to add an extra variable into the conditionalor check for error each iteration.
Sometimes they offer a more simple solution.
It would not make much sense to completely ban their usage.
If anything it would be an advisory rule against their usage unless it is foTBut then again, that's basically just saying use them when they fit.
Preferably your loops would be a simple enough to where they are not needed or only one of these statement would be needed.

#### Recursion

It is true that recursion can create small easily readable functions, but their hidden cost is too much of a risk for saftey critical systems.
What I like to call the recursion tax, where each method call adds its parameters, return pointer, and frame to the stack, can pass the bounds of the stack if the tax becomes too much.
(As a side the calling convention of an architecture would determine if a parameter is added to the stack or a register)
Your testing could show it is within bounds, but what happens during unexpected behavior?
In this case all you really know is it will either reach the base case or blow out the stack.
There are ways to make recursion safer such as limiting the number of calls or adding stack overflow checks.
There is even tail recursion optimization which helps in reducing most stack overflows, but it does not get rid of it entirely.
In the eyes of safety there is no need to introduce such risk if any recursive implementation can be done iteratively.
This way bounds can be verified by static analyzers analyizing an acyclic function call graph, and the common worry of run away code is handled by rule 2.
The absence of recursion also keeps thread stacks with in bounds.
Since threads reside within the same memory space it could be possible for an unchecked recursive method to clobber another thread stack.
Now of course just because you avoid recursion does not make you immune to stack overflows.
Creating excessively large stack frames can still stack overflow, but it is easier to catch with static analysis.
I do recognize the usage of recursion for general applications.
Some problems may just be too complex for iterative implementations like trees or parsing a JSON.
Unless you are using a purely functional language, recursion can be avoided, but it is more of an avoid it if you can for general programming.

#### Goto

Goto is a little weird.
It is viewed as a monster of the past for those who lived it and a cursed relic for those who haven't.
There was good reason for the hatred, and with structured programming becoming the new thing goto was exhiled.
Now that some time has past, with structured programming and OOP as the standard, goto kind of... just exists.
Although I suppose Linux kernel devs could argue some points with their do-while goto loops.
Now adays goto has this one very special specific use case to jump to error handling.
MEM12-C explains how this could be used (MEM12-C)[https://wiki.sei.cmu.edu/confluence/display/c/MEM12-C.+Consider+using+a+goto+chain+when+leaving+a+function+on+error+when+using+and+releasing+resources]
This is touted as the best use case for goto in trying to increase readability.
It is of course still possible to avoid goto for a more structured approach, but this can be less readable.
If we want to abide by the rule of what would be more simple, there could be an argument to use goto specifically for this.
It could also be argued that goto is not needed and to stick to standard flow to avoid bringing issues related to goto.
Without an official statement I would assume NASA still completely bans goto.
For general programming I would advise against using goto.
It is not needed 99% of the time, but it could be useful that incrediably rare 1%.

#### Setjmp() LongJmp()

Setjmp() and longjmp() make sense to ban given the embedded environment and safety critical requirements.
Even the man page suggests avoiding using these two as they make code much more difficult to read.
If you do not know what these two methods do, setjmp() saves the program state into a passed in env for longjmp() to restore back to.
it is basically a super sized out of scope goto without the label.
I haven't used them since I was never in a position to use them.
Supposedly they are useful for getting out of deep errors or for exception handling.
However, rules 5 and 7 should catch the exceptions before they occur.
Additionally, NASA prefers to pass the error up the chain because of rule 7.
The usage of setjmp()/longjmp() can also bring in more problems than what it wants to solve.
For example, the man page mentions that automatic storage variables are unspecified under certain conditions after a longjmp().
Automatic storage being block scoped variables.
For general programming there is not a reason to use these two.

### 2. Give all terminating loops a statically determinable upper-bound
//MENTION ABOUF FILE SIZES

I added the distinction to specify terminating loops since explicit non-terminating loops are exempt from this rule.
Such non-terminating loops would be like a server loop, a process scheduler, or anything for receiving and processing.
Of which NASA says there should only be one non-terminating loop per task or thread.

The original wording from Power of 10 wording specifies "all loops must have a fixed upper-bound".
When I first read this rule I was initially perplexed about what it meant for implementation.
Did this mean NASA just never used functions like strlen or pass in size arguments?
Did this just mean to strictly use constant variables to sent bounds for array like structures?
What would you do if you needed to use a length function or length parameter?
Since the length obtained is not fixed would you then need to provide a fixed bound as well?
Something like `for(int i = 0; i < (length of array) && i < (max upper bound); i++){. . .}`?
This seems unecessary though as would rule 5 and rule 7 check for this?
Luckily the JPL Coding Standard clarifies the rule by saying it shall be possible for a static analyzer to affirm a bound.
This is to say if you can obtain the exact number of iterations as an integer it is okay.
NASA then points out
> "For standard for-loops the loop bound requirement can be satisfied by making sure that the loop's variables are not referenced or modified inside the body of the loop".
Some languages prefer a for-each loop style which is fine as long as the length can be known and does not change.

In this linked list example a limit is added since finding NULL does not give exact iterations.
```
Node* listSearch(Node* node, int needle){
    int count = 0;
    while(node != NULL && count++ < MAX_ITERATIONS){
        if(node->value == needle)
            return node;

        node = node->next;
    }
    return NULL;
}
```

String example finding a character.
```
char* charSearch(char* string, char needle){
    int length = strlen(string)
    for(int i = 0; i <= length; ++i){
        if(string[i] == needle)
            return string + i;
    }
    return NULL;
}

```

Although a better implementation would be to provide a bound as a parameter.
```
/* here size includes the NUL byte */
char* charSearch(char* string, char needle, size_t size){
    for(size_t i = 0; i < size - 1; ++i){
        if(string[i] == needle)
            return string + i;
    }
    return NULL;
}

```

Now, lets say you want to find the length of the string.
It's similar to the linked list example in where searching for a NUL byte does not give exact iterations.
```
int myStringLength(const char* string){
    int count = 0;
    while(string[count] != '\0'){
        ++count;
        if(count > MAX_STRING_LENGTH){
            /*exit or return error*/
        }
    }
    return count;
}
```
You could then use this to verify that your strings are of a certain length.

#### General Cases

Applying this rule to a more general environment is a little more tricky.
This rule is pretty easy to apply when traversing a structure where you can find bounds, but this is not always the case.
Cases where the condition to terminate is outside your control, but your desire is to get out that loop come to mind.
Cases such as
- user input
- waiting for an event
- Waiting for the return value.
- Retrying a failed task.
Technically a bound can be placed on everything through the scientific power of picking a number.
The question would be if it makes sense to.
A user can put as many wrong inputs as they want, but is it a login page or your terminal app menu?
If it is a login then it makes sense to add a time out on too many incorrect attempts.
A terminal menu not so much, but a decision can be made to add an upper bound on attempts.
Maybe the program is reading from a socket that keeps giving bad data.
Perhaps it's okay to block until good data, but if the context is time sensitive returning an error after x attempts would make sense.
Either way it would have to be verified that only the specified conditions can terminate the loop.
The same would go for files, but their sizes can be determined.
Even if you were given a gigantic file there is only as much storage on disk.
Adding a limit would depend on what you are using the file for.
If a program depends on reading the whole file there would not be a reason to add a bound.
Maybe it is expected that a file is only ever a certain size, so the program never reads past an amount of bytes.
Generally it would depend.
It may make sense to add a bound it may not make sense.


#### Async

I didn't see anything about asynchronous behavior in NASA's documentation, but it is a common practice to set a timeout for asynchronous things.
This way your program won't hang there waiting, and you can return an error.

#### Task Timeout

Task timeouts are more applicable to servers to prevent DDos attacks, but can very well be used in other situations.
Regex is one example.
There are some "evil regex" patterns that can act as a Denial of Service.
This Wikipedia article explains about it (Wikipedia ReDoS)[https://en.wikipedia.org/wiki/ReDoS].

### 3. Do not use dynamic memory after initialization

This is a common rule for embedded systems and anything safety critical.
Dynamic memory can be unpredictable, hard to manage, and hurt performance.
There are also countless issues related to the HEAP such as
- use after free
- memory leaks
- fragmentation
- dangling pointers
- exhausting HEAP memory
- buffer overflows in the HEAP
- missing real time deadlines due to waiting for memory
- sensitive data left in HEAP
- unpredictable behavior of garbage collectors
- unpredictable behavior of memory allocators

Even NULL checks after a malloc does not gaurentee that the malloc was successful.
Linux's malloc() is optimistic and only allocates the memory once it is going to be used.
This can result in a crash from using memory thought to be available.
For these reasons dynamic memory is banned, but it is not banned entirely.
Most people take this as a rule to never use dynamic allocation which is not entirely true.
It forbids using dynamic memory at run time, but it can be used at the initialization phase to set a bound.
This would be the phase either before the call to main, or in main but calls to other functions to set things up.
Here the program can figure out how much memory it would need in total and make it.
This is what the NASA Power of 10 Document says at least.
In the JPL document it mentions "task initalization" which I am not entirely sure on what it means.
Is this talking about the creation of threads or a method setting up memory before doing its job or any broad definition of a task?
My hunch is that it is talking about threads as they are commonly refered to as tasks, and their job is to complete a task.
Would this definition allow the usage of the HEAP during the run time to initialize a task, or would the this need to be accounted for in the very first allocation?
Is this what allows funtions like printf to be used?

In NASA's words they force the application to live in a fixed, pre-allocated area of memory.
Essentially they avoid the issue with the HEAP by making a single large allocation and then never freeing it.

During run time it means avoiding functions like
- malloc()
- calloc()
- realloc()
- free()
- alloca()*
- sbrk()

\*alloca uses the stack, but still should not be used. The man page explains (alloca() man page)[https://www.man7.org/linux/man-pages/man3/alloca.3.html].
//INCLUDE SOMETHING ABOUT VARIATIC ARRAY LENGTH DECLARING

This would also mean some functions that return dynamic memory like strdup().
What I'm not entirely sure about are standard library functions that internally use dynamic memory.
The printf family is one example.
Printf uses xmalloc which would abort the program on allocation failure.
I suppose this could be used as a safety check and ensure boundaries are not past?
They do include printf in rule 7, so I assume this is more a ban on explicit usage of dynamic memory.

Some ways to imitate dynamic behavior
1. Set maximum bounds for input
2. Object pools
3. Ring buffers
4. Arenas
5. Pre-allocate

NASA's environment is different than most people.
I can't say to avoid dynamic memory completely for all general programs, but I can say to keep explicit allocation to a minimum
This way as few mallocs need to be tracked, and it allows usage of the printf family or fopen.
Dynamic memory can very easily be mismanaged, so it is important to use it only when necessary.
Each extra allocation is another risk so handle it properly.

### 4. Function Length should be printable on a page with one statement per line

The principle of this rule is to treat your functions as small logical units.
Longer "everything" functions are often a sign that logic is poorly thought out, or that stratification is needed.
Not only is it harder to debug a large function because of its size, but it also much slower to understand in the first place.
Having to scroll down or jjjjjjjj/kkkkk to find far seaparated code can feel like walking into many rooms and forgetting why you are there in the first place.
So you jump back to where you had a foot hold of understanding because "ahh it was that variable I am concerned about".
Then you scroll too far down trying to find where you are stuck.
Creating smaller functions keeps the logic within one spot, so it is much easier to audit and find mistakes.
In combination with rule 1, functions are even more understandable with clear flow.

#### UnitTesting
The rule would have a tie with unit testing.
Since functions are broken up into units it makes logical sense to test those units.
With the units being smaller it helps keep tests small, but allows for much more through testing.
It would be less likely to forget a test case if the unit has a strict job rather than many jobs combined.
It would also mean less need for hacky mocking to prevent execution from going further.

#### Interpretation
The exact interpretation of this rule can vary.
NASA's Power of 10 says 60 lines of code, but generally what can be printed on a single page in standard reference format.
The JPL Coding Standard says 60 lines of text, but includes 60 lines of code from the Power of 10.
TigerBeetle uses a hard limit of 70 lines.
The Spinroot site says 60 is typical, but an reasonable value between 50 - 100 works.
Spinroot's interpretation of what a line is is defined by actual code excluding comments and empty lines.
They take the file and normalize to count each line.

##### All the Single Lines
What every interpretation had in common though, was that each statement and declaration should be on separate lines.
This is to avoid cheating the rule with statements like `unsigned int i, n, h, w, x, y, mw;` or `int i, j = 1`.
It avoids statements like `int* x,y,z` where only x is actually a pointer and the rest are ints.
You would need to do `int* x, *y, *z` instead to make them all pointers.
Statements that can create confusion at first glace like `int i, j = 1` are also avoided.
Here both i and j are assigned one, but at first glance be seen as i assinged a default value and j as 1.
Some more examples I will provide below.
```
/* not abiding by rule */
int obtain_value = getValue(), obtain_value2 = getAnotherValue();
char* first = some_string, second = some_string + 1;
int i, j = 1;

/* abiding by rule */
int obtain_value = getValue();
int obtain_value2 = getAnotherValue();
char* first = some_string;
char* second = some_string + 1;
int i = 1;
int j = 1;
```

#### For Loops
There is a notable exception to for loops since they are technically 3 statements.
The three statements in a for loop are just fine to keep in a single line since it is convention.
An unfortunate edge case can be seen in the glibc strlen() source code.
```
for (char_ptr = str; ((unsigned long int) char_ptr
			& (sizeof (longword) - 1)) != 0;
       ++char_ptr)
    if (*char_ptr == '\0')
      return char_ptr - str;
```

This is difficult to read mostly because the conditional is split and the incremenation is dangling there.
Now I understand that the casting is pushing this to be a very long line.
Excluding indentation, it would span 95 columns and the hard limit could be 80.
```
 for (char_ptr = str; ((unsigned long int) char_ptr & (sizeof (longword) - 1)) != 0; ++char_ptr)
    if (*char_ptr == '\0')
      return char_ptr - str;
```

I won't go over fixes.
Just know that edge cases like these can exist.

#### Ifs and Whiles
The mention about for-loops got me a little curious on what this meant for ifs and whiles.
The conditional statement is separated by && and || (or even bitwise & |) instead of semicolons.
Sometimes these boolean expressions can get a little long, so what does this rule mean for them?
I think the preference is to maintain a single line if possible, or even better just have a simple boolean expression.
This is not always possible, so to aid readability separation is acceptable.

one line if statements would be like
I didn't include curly brackets as what ever coding style is chosen would determine it.
```
if( x < 5 )
    flag = 1
```

#### Function Parameters
Another part of this rule is a prefered maximum of 6 parameters.
Having too many parameters can harm clarity not just for the function itself, but for the callee.
Personally for me, having more than 4 parameters is too much.
There is also a more technical reason that the 7th and beyond parameters are placed on the stack instead of a register, so their values could get courrupted indirectly.
This is more of a side reason though, and the main reason is for improved clarity.

#### Column Limits
NASA does not say anything about column limits in these documents, but excessively long lines can hurt readability.
80 seems to be more preferred, but it tends to more of a soft limit for most people.
100 characters seems to be the more acceptable hard limit, and it is what I stick by.

### 5. There shall be minimally an average of 2 assertions per function with assertions containing no side-effects and must be boolean expressions

If for what ever reason you hate the other rules this rule you can't hate.
NASA makes a point that unit testing catches 1 bug every 10 to 100 lines, but combined with assertions unit testing catches much more bugs.
Of course it is obvious that adding more checks will catch more bugs, but this a superficial way to look at it.
Unit testing and assertions complement each other since they capture different aspects of development.
Assertions test a programmer's assumptions that should always remain true or false.
They are meant to catch errors strictly from a programmer rather than errors from handling data.
Unit testing is there to test expected or expected-unexpected inputs to give a pass or fail.
It is there to actually run the unit and find out if the unit does its job correctly.
Since they are capturing opposite sides of development this is why more bugs are caught.
Both of these techniques should be used in any coding context.
It is the best way a programmer can remain sane that their code is as correct as possible.

So where do you use assertions?
They are used to verify the principle of designing by contract.
This would mean
- verify pre-conditions of functions
- verify post-conditions of functions
- verify loop invariants

Where do you **NOT** use assertions?
- Validating user input
- Public facing methods verifying parameters
- Handling expected errors (like file open failure)
- Data outside of your control

In these cases you should **VALIDATE** like in rule 7.
Do not use assertions on things you can't say should **ALWAYS** be true or false.
This is because assertions are removable for performance reasons.
The idea is that during development the assertion never triggered, so it should be safe to remove.
An argument can be made if assertions should be removed in the first place since debugging never stops in programming.
For general cases assertions are typically removed for user convenience, but safety critical systems would want to keep them.
If you want to modify the behavior of the default assertion, or don't want them to be removable you can create your own.

This brings up a question on how to write an assertion.
Assertions should
- Evaluate strictly to a boolean expression
- Contain no side effects
- Have a recovery action on failure
- Be proven that it can fail or hold

NASA defines an assertion like this
```
#define c_assert(e) ((e) ? (true) : \
tst_debugging("%s,%d: assertion '%s' failed\n", \
__FILE__, __LINE__, #e), false)
```

They give an example like this
```
if (!c_assert(p >= 0) == true) {
    return ERROR;
}
```
This way NASA is able to change the logging function if they need and it returns an error.

They also mention static assertions which would depend on what compiled the program.
Something like `c_assert( 1 / ( 4 – sizeof(void *));`.
This will trigger a divide by zero warning if the compiler is using a 32-bit machine.
This is because 32-bit systems have pointers that are 4 bytes while 64-bit systems use 8 bytes.

### 6. Data objects should be declared in their lowest scope

In C this is the best way to accomplish data hiding.
If a variable is out of scope then it can't be modified or referenced.
This has the benefit of reducing what can be courrupted and makes debugging easier.
For the most part, this is as simple as declaring and/or defining the variable at the point of first use.
However, C has some other neat features that makes this rule slightly more complicated.

#### Static
Typically `static` is know for declaring a variable that persists within a function.
For the most part this should be avoided as it is an easy way to create side effects.
However, static can be used on a function to specify that its scope is within the file.
More specifically it is indicating internal linkage.
It is kind of like creating a private method since it will be usable only in that source file.
These type of functions should **NOT** be declared in the header file, and they should reside in just the source file.
Defining a static method in the header file would give each file that includes the header a separate function definition.
It defeats the purpose of specifying internal linkage, and really is not necessary.
Although I suppose you could try to make your very own Java Interface in C if you really wanted to.

Example of defining a static method
```
static void someFunction(){
    . . .
}
```

#### Extern
The opposite of `static` would be `extern`.
This specifies external linkage.
extern is like making a global object that is declared in the header file that later gets defined in the source file to be passed around.
It is a way to extend the visibility to many source files.
By default functions are extern in the header file hence why you define them in the source file.
You can of course define extern variables, but caution should be used with them.
NASA says if two extern variables have the same name, but different types it can create undefined behavior.
Just make sure that extern objects are unique.

#### Shadowing and Reuse
Other sub-rules included are discouraging shadowing variables and variable reuse for different unrelated purposes.
```
int x = 10;
for(int x = 0; x < 10; ++x){
    /* x is shadowed here */
}
```
In the example above this would result in the loop executing 10 times instead of 0 times.
Shadowing can result in unexpected behavior since it won't refer to the variable you think.
one way to avoid shadowing is to create explicit names.
Perhaps including units into the variable itself can distinguish different length variables.
The rule about variable reuse is to create better readability.
Using a length variable for many unrelated purposes can make debugging more difficult as you then need to find which effectively different length variable is the issue.

#### Pure Functions
Within this rule is a preference for `pure functions`.
NASA says these are functions that do not touch global data, avoid storing local state, and do not modify data declared in the calling function indirectly.
It is basically a function that strictly takes what it is given and will give the same result each time with identical arguments.
This can be aided with the use of const and enums to declare that this is something that won't be modified.
Const especially should be used on reference types whenever possible.
This wikipedia article explains a little more (Pure Functions Wikipedia)[https://en.wikipedia.org/wiki/Pure_function]

### 7. Check all return values of non-void functions and validate passed in parameters

This rule is the flip side of rule 5, and just like rule 5 it can be implemented in any language.
A lot of bugs slip by simply because the return values or parameters were not checked.

#### Return Value Checking
In the most extreme cases you would check the results of printf, but NASA says in cases where the return does not matter to cast as void.
so this -> `(void)printf("%s", "Hi")`.
This way others know the return value is purposely ignored, but also allows for questioning if it should be ignored.
Checking the return value of methods that give one is justa good practice in general.
This will help with troubleshooting in some cases as you won't continue with erroneous behavior.
This would also extend into you creating methods.
Since you are checking for error status you have an incentive to return an error status.

#### Validating Parameters
Validating parameters is probably the most important rule to have in any security focused rule.
So many vulnerabilities occur from simply not checking parameters especially in public functions.
Public functions are well. . . public, so they can accept any kind of input from anywhere.
Therefore, it is important to make sure the public function can actually use the parameters it was given.
Private functions should also validate their parameters, but here you can get away with using assert statements.
This promotes the principles of creating total functions in where functions can handle any input.
Weakly typed languages may have a more difficult time with this, but I think the type should be validated/asserted.
Types are an assumption in weakly typed languages, and you should check your assumptions.

Example of validating parameters using the third example from rule2.
```
/* here size includes the NUL byte* /
char* charSearch(const char* string, char needle, int size){
    if(string == NULL || !isalnum(needle) || size < 0)
        return NULL;

    for(int i = 0; i < size - 1; ++i){
        if(string[i] == needle)
            return string + i;
    }
    return NULL;
}
```

However, you don't always create the functions.
Sometimes you are using a provided function that may not do validation.
NASA gives the example of strlen(0) and strncat(str1, str2, -1).
Here undefined behavior can occur.
In these cases it is applicable to check the parameters before calling the function.
Conceptually I feel it is better to include the validation in your functions since it is more intuitive.
Functions can be thought of as interfaces.
You plug in your values and expect some value.
Depending on what value you get is what you'll do.
Having to remember to check the parameters before calling can often be forgotten, and it is not expected.

MISRA C 2004 rule 20.3 mentions some ways of conducting validation
- Check the values before calling the function.
- Design checks into the function.
- Produce wrapped versions of functions, that perform the checks then call the original function.
- Demonstrate statically that the input parameters can never take invalid values.

### 8. The preprocessor should be left for simple tasks like includes, simple macros, and header guards
//TALK ABOUT NOT REDEFINING LANGAUEE

The preprocessor can make debugging more difficult since it obfuscates the actual value.
This can make it difficult for tools to verify the code, and for humans to read.
It is also a concern in debugging since the actual value is placed instead of the define tag.
The preprocessor is basically just copy and paste, so debuggers will see the value 8 instead of LENGTH_MAX.
In combination with this obfuscation, it is very important that macros are syntactically valid and contain no side effects.
NASA further says when defining a macro you shall not define them inside a block or function, and the usage of #undef shall not be used.
This extends into include statements where only preprocessor components or comments should precede an include.

The allowed macros are explained in MISRA C 2004 rule 19.4.
- Constant values
- Constant expressions
- Macros expanding into an expression
- Storage class specifiers
- braced initializer
- Parenthesized expressions
- String literals
- Do while zero construct\*

shown below
```
/* The following are compliant */
#define PI 3.14159F                 /* Constant */
#define XSTAL 10000000              /* Constant */
#define CLOCK (XSTAL/16)            /* Constant expression */
#define PLUS2(X) ((X) + 2)          /* Macro expanding to expression */
#define STOR extern                 /* storage class specifier */
#define INIT(value){ (value), 0, 0} /* braced initializer */
#define CAT (PI)                    /* parenthesized expression */
T#define FILE_A "filename.h"        /* string literal */
#define READ_TIME_32() \
    do { \
        DISABLE_INTERRUPTS (); \
        time_now = (uint32_t)TIMER_HI << 16; \
        time_now = time_now | (uint32_t)TIMER_LO; \
        ENABLE_INTERRUPTS (); \
    } while (0) /* example of do-while-zero */
```

\*The do-while one is a bit weird, but from what I've researched it seems to try and avoid the faults of the preprocessor.
The do-while is a way to create more complicated expressions while maintaining scope and having to insert a semi-colon at the end.
It's a little bit of a hack, but compiler optimization will remove the do while portion.

Below are listed as not compliant
```
/* the following are NOT compliant */
#define int32_t long    /* use typedef instead */
#define STARTIF if(     /* unbalanced () and language redefinition */
#define CAT PI          /* non-parenthesised expression */
```

The C preprocessor can do much more than simple defines and includes.
It is quite an extensive tool that allows for ease of use, or absolute spagetti disguised as cohesion.
Below I will explain some of the powers it can bring and wether NASA bans it.

#### Function Like Macros
Function like macros are not banned under NASA's rule, but certain usages can be dangerous.
In basic terms, a function like macro is defined as any macro that takes in arguments.
it is defined like `#define <name of macro> (<arguments>) <definition using arguments>`.
For simple expressions it allows you to ignore the type, so you do not need to create several funtions to handle many types.
It can also be for expressions that don't need to be a function since they are so short, and function overhead is a concern.
A few examples are below.
```
#define MAX(a,b)  ((a)>(b) ? (a):(b))
#define MIN(x,y)  ((x)>(y)) ? (x):(y))
#define SQUARE(z) ((z) * (z))
```
Now remember that the preprocessor will just copy and paste the values into the expression.
This is why the arguments are surrounded in parenthesis to maintain correct order of operations.
If an expression like `3 + 4 * 9` were used in SQUARE without parenthesis it would expand to `3 + 4 * 9 * 3 + 4 * 9` instead of `(3 + 4 * 9) * (3 + 4 * 9)`.
This would mean an evaluation of 147 vs 78.
However this doesn't solve other side effects like incremenation.
Using an expression like `MAX(x++, y - 1);` in the MAX macro would result in `(x++) > (y - 1) ? (x++):(y - 1);`.
This can result in x getting incremented twice and seemingly give the correct post-fix value if it is the max value.
This can lead to unspecified behavior in the SQUARE macro `SQUARE(++some_int); - > ((++some_int) * (++some_int));`.
One way could be to use the typeof() preprocessor method, but this is GNU specific.
`#define Square(x) ({ typeof (x) _x = (x); _x * _x; })`.
A more simple way would be to conduct the side effect before the macro.
```
++x;
SQUARE(x);
```
Other ways include using inline functions over a function like macro to enforce type and remove side effects.
The big picture here is that this rule specifies **simple** macros.
If a macro would be better off as a function, make a function instead.

#### Conditional Compiling

Conditional compilation are the statements like `#if, #ifdef, #elif, #else, #ifndef, #endif`.
You have probably used them for header guards.
```
#ifndef <HEADER_FILE>
#define <HEADER_FILE>

/*your declarations here*/

#endif
```

NASA says this is about how far you should go with these conditionals, but sometimes it is unavoidable.
If you must use them beyond the standard header guard, all `#else, #elif, and #endif` must reside in the same file as their `#if or #ifdef`.
A max limit of 2 is prefered.
Adding too many conditional compilations will exponentially create test cases.
On the topic of header files, MISRA C 2004 rules 8.1, 8.8, 19.1, 19.2, 19.15, 20.1 explains more details.
//go a little more into header file practices

#### Token Pasting
Token pasting is probably something most new people to C haven't even heard about.
Its usage is defined by using "##" inside the #define macro.
This operation takes two tokens and concatenates them into one token.
A define like `#define combine(arg1, arg2) arg1 ## arg2` would combine arg1 and arg2 into one token.
For example these two examples would print out 3.
```
#define xy 3
#define combine(arg1, arg2) arg1 ## arg2
printf("%d\n", combine(x, y));

-----------------------------------------------

#define combine(arg1, arg2) arg1 ## arg2
int xy = 3;
printf("%d\n", combine(x, y));

```
However if you were to surround x and y in quotes it would create "x""y" which is not a valid token.
Token pasting can very quickly create hard to read code for humans and tools, so NASA bans it to keep things simple.

#### Stringize
On the other hand '#' is a stringize operator and turns the given parameter into a string.
The assert statement in rule 5 is a good example.
The way that it accomplishes this is by surround the argument in double quotes.
If there are already double quotes it will escape it.
```
#define TO_STRING(x) #x
printf("1> %s\n", TO_STRING(Big Ol Cheese Blocks));
printf("2> %s\n", TO_STRING("Big Ol Cheese Blocks"));
printf("3> %s\n", TO_STRING("Big Ol ""Cheese Blocks"));
printf("4> %s", TO_STRING("Big Ol \"Cheese Blocks"));

Output:
1> Big Ol Cheese Blocks
2> "Big Ol Cheese Blocks"
3> "Big Ol ""Cheese Blocks"
4> "Big Ol \"Cheese Blocks"
```
Stringize is allowed since it is limited in what it can do.

#### Recursive Macro Calls
The thing about Macros is that they are not actually recursive.
Once the macro expands it will not expand into itself again if it was directly from the previous pass.
This is refered to as `painted blue`.
People have gotten around it by defering one extra step so the macro expands into another expansion that calls the desired macro.
In effect it is basically a hack to get around the preprocessor and it creates incrediably unreadable code.
It would look something like this.
```
#define EVAL1(x) x
#define EVAL2(x) EVAL1(EVAL1(x))
#define EVAL3(x) EVAL2(EVAL2(x))
#define EVAL(x)  EVAL3(EVAL3(x))

#define REPEAT_1(macro, x) macro(1, x)
#define REPEAT_2(macro, x) REPEAT_1(macro, x) macro(2, x)
#define REPEAT_3(macro, x) REPEAT_2(macro, x) macro(3, x)

#define PRINT(idx, val) printf("Index %d: %s\n", idx, val);

REPEAT_3(PRINT, "Hello") /* usage */
```
This StackOverFlow post explains in more detail (recursive preprocessor to create a while loop)[https://stackoverflow.com/questions/319328/how-to-write-a-while-loop-with-the-c-preprocessor/10542793#10542793].

#### Variadic Macros
Usage of __VA_ARGS__ allows you to make a variadic macro and sometimes is used for recursive calling macros.
It's usage tends to lead to macro chaining like this.
```
#define ESC(...)  __VA_ARGS__

#define APPLYTWOJOIN_0(f,j,e)            ESC e
#define APPLYTWOJOIN_2(f,j,e,t,v)      f(t,v)
#define APPLYTWOJOIN_4(f,j,e,t,v,...)  f(t,v) ESC j APPLYTWOJOIN_2(f,j,e,__VA_ARGS__)
#define APPLYTWOJOIN_6(f,j,e,t,v,...)  f(t,v) ESC j APPLYTWOJOIN_4(f,j,e,__VA_ARGS__)
#define APPLYTWOJOIN_8(f,j,e,t,v,...)  f(t,v) ESC j APPLYTWOJOIN_6(f,j,e,__VA_ARGS__)
```
This was found at this StackOverFlow post (variadic macro for function defining)[https://stackoverflow.com/questions/48284705/how-to-use-variadic-macro-arguments-in-both-a-function-definition-and-a-function].
Their usage also tends to lead to unreadable code like with recursive calling macros.

#### Variadic Functions
Although not explicitly a preprocessor defined behavior, defining variadic functions are also banned.
The rule does specify anything with variadic behavior using ellipses (anything with ...), and the JPL Coding Standard references specifically MISRA C 2004 Rule 16.1.
variadic functions are like printf.
There is not an explicit reason why defining variadic functions are banned, but I think it is probably to reduce complexity and allow better static analysis.
It could also be because of rule 7 in needing to verify function parameters.
Normal function parameters have an explicit type, but variadic functions can accept any number of arguments that can be any type with no way to verify type.
They are also an easy way to introduce security risks due to improper usage or passing in unexpected values.
Rule 2 could also apply, but if you ever do use variadic functions a length should be given instead of soley relying on the ending NULL.
Personally I've never needed to use a variadic function, and when I did think about using one I simplified my code instead.

### 9. Pointers should at most have two levels of dereferencing

The NASA Power of 10 doc says "no more than one level of dereferencing should be used."
To align more with the JPL C Standard I made it "two levels of dereferencing."
This way 2D arrays or pointer to pointers can be used.
This also means declaration of pointers should have no more than two levels of indirection.
Most of the time you'll only ever need two levels of indirection, but there may be the rare case where more is required.
Two examples are an array of 10 images with images represented as a 2D array of pixels, or changing the address of a 2D array.

```
int8_t * s1;    /* compliant */
int8_t ** s2;   /* compliant */
int8_t *** s3;  /* not compliant */

void someFunction(char* some_parameter){. . .}   /* compliant */
void someFunction(char** some_parameter){. . .}  /* compliant */
void someFunction(char*** some_parameter){. . .} /* not compliant */
```
If you want to see more examples look at MISRA C 2004 advisory rule 17.5.

Function pointers on the other hand are advised to be avoided unless it is const.
The original NASA Power of 10 document completely avoided function pointers, but the JPL Coding Standard revised it to allow const function pointers.
Both documents advise against the usage of non-const function pointers.
This is so static analyzers and tool checkers can conduct their checks normally.
There is not a way to know where the function pointer will go since it is run time dependent.

In general, the point of this rule is to improve code clarity and reduce pointer misuse.
Having multiple dereferences, especially with usage of pre/post incremenation, can be confusing.
If more levels of dereferencing are needed then use a middle variable for clarity.
There are three dereferencing operators.
They are `[], *, ->`.
- \* is the standard dereferencing operator
- -> is for accessing a member from a struct pointer
- [] is dereferencing with a given offset in arrays
These operations should not be hidden in a macro or be inside typedef declarations.

```
typedef int8_t* INTPTR
INTPTR* some_pointer; /*creating an implicit double pointer*/

#define GET_VALUE(x) (*x)
GET_VALUE(*x) /* expands to **x */
```
These operations should be explicit as they are the culprits for segmentation faults.

There is also another aspect of dereferencing which is pointer arithmetic.
MISRA C rules 17.1 - 17.4 explain some rules on what is best.
In summary array indexing shall be the only form of pointer arithmetic, and pointer arithmetic shall only be done within arrays.

### 10. Compile with the most pedantic compiler settings with no warnings and check daily with static analyzers


This rule is language dependent, but popular enough languages have several tools.
With the history of C, This rule is a large part in why NASA uses C.
There is extensive tool support for C which allows for much more thorough checks.
A compiler can conduct basic checks, but a static analyzer can go into more detail.
A compiler can combine some aspects of a static analyzer for convenience, but it may not be as extensive.
For example, NASA mentions a lot about bounds in their rules which a static analyzer can determine, but not a strict compiler.

#### C
Some basic GCC options are `-Wextra -Werror -Wpedantic`.
According to the JPL C Coding Standard, NASA uses `gcc –Wall –Wpedantic –std=iso9899:1999` (iso9899:1999 is C99).
Although the document was written before C11 was released, so they may not use C99 anymore.
Enforcing a standard is helpful since flags like -Wpedantic will change their behavior based off the standard.
Some other GCC options include
```
-Wtraditional
-Wshadow
-Wpointer-arith /*included in -Wpedantic*/
-Wcast-qual
-Wcast-align
-Wstrict-prototypes
-Wmissing-prototypes
```
There is also a built in ASAN in gcc by using `-fsanitize=address`.
Note that you should not ship out your code with ASAN enabled since it is for debugging memory and adds overhead.
There is also the `-fanalyzer` flag in GCC that can be used for static analysis.

#### Java
Javac has options like `-Xlint:all -Werror -deprecation`.
A few other -Xlint options are listed below.
```
cast: Warns about the use of unnecessary casts.
classfile: Warns about the issues related to classfile contents.
deprecation: Warns about the use of deprecated items.
finally: Warns about finally clauses that do not terminate normally.
static: Warns about the accessing a static member using an instance.
try: Warns about the issues relating to the use of try blocks ( that is, try-with-resources).
unchecked: Warns about the unchecked operations.
varargs: Warns about the potentially unsafe vararg methods.
```

#### Python
Python has options like `-Werror -Walways -X dev`
There is also the `-I` option for isolating the program.
It does this by ignoring Python's environment variables, and removes the script's path from sys.path.
Due to python not being a compiled language it does not have as many options compared to C or Java.
There are static analyzers for Python though.

#### Other Languages
Depending on the language, there may be third party static analyzers to add additional aid.
This wikipedia article shows some static code analyzers available (Wikipedia list of static code analysis)[https://en.wikipedia.org/wiki/List_of_tools_for_static_code_analysis]

## Conclusion
//Just write something down to get an idea
So those are the rules.
In a broad sense these rules can be summarized into three catagories.
Those are predictable execution, defensive coding, and code clarity.
// Coudl make a table here
C specific rules
3, 8, 9

Rules that apply to any langauge
1, 2, 4, 5, 6, and 7

Depends on the language
8, 9, 10

Rules 2 and 3 are in the predictable execution catagory.
Rules 5, 6, 7, and 10 relate to defensive coding
Rules 1, 4, 8, 9

## Sources

[Original NASA's Power of 10](https://spinroot.com/gerard/pdf/P10.pdf)

[Other NASA's Power of 10](https://web.eecs.umich.edu/~imarkov/10rules.pdf)

[JPL C Coding Standards](https://github.com/stanislaw/awesome-safety-critical/blob/master/Backup/JPL_Coding_Standard_C.pdf)

[Spinroot Power of 10 Explanations](https://spinroot.com/p10/index.html)

[MISRA C 2004](https://caxapa.ru/thumbs/468328/misra-c-2004.pdf)

[Guidelines on Software for Use in Nuclear Power Plant Saftey Systems](https://www.nrc.gov/docs/ML0634/ML063470583.pdf)

[Tiger Beetle](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)

[Low Level NASA Power of 10 Video](https://www.youtube.com/watch?v=GWYhtksrmhE)
Thank you Low Level for getting me interested in NASA's Power of 10 in the first place
