Note that I am not quite done with this.
It is at least good enough for me to make public though.
A little easter egg for those who look at this is that this is made entirely in vim.

# NASA's Power of 10

## Description

NASA's Power of 10 is a very powerful guideline with 10 simple rules tailored to developing safety critical software.
This is software where failure can result in death, harm the environment, or lose critical equipment.
These guidelines have this in mind, but nothing says they are solely for these scenarios.
In a broad sense, it is software where people depend on correct implementation to avoid catastrophe.
One example is TigerBeetle using these rules for online transaction processing for businesses.
Businesses may not be considered safety critical, but they have business critical components that must stay operable to avoid heavy loses.
For these cases that require a focus on secure programming, NASA's Power of 10 is fantastic guideline.
However, one big caveat is that NASA's Power of 10 is **NOT** all encompassing on secure programming.
Its purpose is to act as 10 simple, memorable, and effective guidelines to help in creating reliable and robust code.
These rules do not go over how to avoid vulnerabilities or other best practices which is why you should stil read security standards for your language.
Speaking of languages, keep in mind that these guidelines focus on **safety critical C Code**.
This means some of NASA's justification relates to the woes of C and how to make C safer.
This results in people hardening their mind to these rules, but I believe people should not.
In the general case these should be treated as guidance rather than strict adherence.
Some of the rules apply to C-like languages while other rules are simply good practices to have for any language.
So despite this catch, I feel it is important to read NASA's power of 10 for the fact it alters your mind to be more defensive and considerate on how you program.

Below is my commentary on the rules with what they mean and what it means for other constructs.
I purposely did not include NASA's rationale explicitly in here because I did not want this be another copy and paste document about their rules.
I also want you to read the documents :P.
These guidelines assume the reader already has a pretty good understanding on why NASA has their rationale.
It assumes the reader knows about embedded systems, the importance of analysis, and working with a team of programmers.
To keep these rules short and understandable NASA can not explain everything.
To help fill in a gap I thought existed I wanted to create a document on what a normal programmer would think.
Albeit a programmers who really likes secure programming.
I wanted take a stance that will focus more on how these rules can be applied in general programming.
This will of course mean a more relaxed stance on some rules for the sake of being more applicable, but it does not mean the rule can not be implemented.
If anything it would be an argument about practicality rather than feasibility.
Taking a wider approach does allow a conjuring on how these rules would apply to situations not explained in these guidelines.

I recommend that you read the sources to gain more incite into NASA's reasoning.
For example, a lot relates to static analysis.
There is also the consideration that these documents are much older and reference older material.
This is not to say the rules are void because of their age, but more so to keep in mind that technology and stigma at the time was a consideration.
The NASA power of 10 doc that most people see is a good document, but the same rules are refined in the JPL C Coding Standard.
Once again, I would heavily suggest you read the documents provided in sources.

## The Rules

### 1. Restrict code to very simple control flow constructs

This rule in combination with 4 and 6 helps create clean code that's easy to audit for humans and tool-based analysis.
Code with an easy to follow control flow is easier to secure, maintain, and find bugs.
A simple control flow can reveal logic errors that otherwise could have remained hidden.
Basically, the rule aims to make control flow as explicit as possible especially for static analyzers which can get confused.
If a static analyzer is unable to understand the control flow NASA says to rewrite to code so that it is understandable.
To accomplish this goal, NASA bans the usage of goto, setjmp, longjmp, and recursion.
Additionally, NASA is perfectly okay with multiple exit points from a function.
They say a single exit point can simplify control flow, but an early exit can often times be the more simple solution.
Such cases would be validation of parameters or abiding by the fail fast principle.

#### Break & Continue

From what I read, NASA did not say anything about break or continue statements.
Now of course breaks are completely fine in switch cases it is more so its usage in loops that are of concern.
These two statements are strictly limited to loops, so they are not as devious as goto or setjmp/longjmp.
They act as a shortcut to end the loop or start a new iteration, so their effect on flow are understood.
Of course like any tool it can be abused to make unreadable code.
This is especially true when they are used in nested ifs in a single loop like so.
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
From what I read though, a single break per loop is acceptable in certain circumstances, but continue is not allowed.
Continue is more so banned since it is a little unnecessary in that the next iteration will continue if it reaches the bottom of the loop anyway.
In some cases it is more problematic since continue is skipping everything below it like in the example above where it skips printing 6.
Break on the other hand does have a use where some condition can terminate the loop early, but a loop should only have one early exit point.
It can be used sparingly in the right circumstances such as finding a specific value in an array, or calling a function in a standard loop that can return an error.
Sometimes a condition is not know until it gets into the iteration, and break offers a simple solution to handle it.
In cases where a loop can have two outcomes, or break offers a more simple clear solution it is acceptable.

#### Recursion

It is true that recursion can create small easily readable functions, but their hidden cost is too much of a risk for safety critical systems.
What I like to call the recursion tax, where each method call adds its parameters\*, return pointer, and frame to the stack, can pass the bounds of the stack if the tax becomes too much.
Your testing could show it is within bounds, but what happens during unexpected behavior?
In this case all you really know is it will either reach the base case or blow out the stack.
There are ways to make recursion safer such as limiting the number of calls or adding stack overflow checks.
There is even tail recursion optimization which helps in reducing most stack overflows, but it does not get rid of it entirely.
In the eyes of safety there is no need to introduce such risk if any recursive implementation can be done iteratively.
This way bounds can be verified by static analyzers analyzing an acyclic function call graph, and the common worry of run away code is handled by rule 2.
The absence of recursion also keeps thread stacks with in bounds.
Since threads reside within the same memory space it could be possible for an unchecked recursive method to clobber another thread stack.
Now of course just because you avoid recursion does not make you immune to stack overflows.
Creating excessively large stack frames can still stack overflow, but it is easier to catch with static analysis.
I do recognize the usage of recursion for general applications.
Some problems may just be too complex for iterative implementations like trees or parsing a JSON.
Unless you are using a purely functional language, recursion can be avoided, but it is more of an avoid it if you can for general programming.

\* The calling convention of the architecture would determine if a parameter is added to the stack or a register

#### Goto

Goto is a little weird.
It is viewed as a monster of the past for those who lived it and a cursed relic for those who haven't.
There was good reason for the hatred, and with structured programming becoming the new thing goto was exhiled.
Now that some time has past, with structured programming and OOP as the standard, goto kind of... just exists.
Although I suppose Linux kernel devs could argue some points with their do-while goto loops.
Now adays goto has this one very special specific use case to jump to error handling.
MEM12-C explains how this could be used [MEM12-C](https://wiki.sei.cmu.edu/confluence/display/c/MEM12-C.+Consider+using+a+goto+chain+when+leaving+a+function+on+error+when+using+and+releasing+resources)
This is touted as the best use case for goto in trying to increase readability.
It is of course still possible to avoid goto for a more structured approach, but this can be less readable.
If we want to abide by the rule of what would be more simple, there could be an argument to use goto specifically for this.
It could also be argued that goto is not needed and to stick to standard flow to avoid bringing issues related to goto.
Without an official statement I would assume NASA still completely bans goto.
For general programming I would advise against using goto.
It is not needed 99% of the time, but it could be useful that incredibly rare 1%.

#### Setjmp() LongJmp()

Setjmp() and longjmp() make sense to ban given the embedded environment and safety critical requirements.
Even the man page suggests avoiding using these two as they make code much more difficult to read.
If you do not know what these two methods do, setjmp() saves the program state into a passed in env for longjmp() to restore back to.
it is basically a super sized out of scope goto without the label.
I haven't used them since I was never in a position to use them.
Supposedly they are useful for getting out of deep errors or for exception handling.
However, rules 5 and 7 should catch the exceptions before they occur.
Additionally, NASA prefers to pass the error up the chain because of rule 7.
The usage of setjmp/longjmp can also bring in more problems than what it wants to solve.
For example, the man page mentions that automatic storage variables are unspecified under certain conditions after a longjmp().
Automatic storage being variables that are removed once out of scoped.
For general programming there is not a reason to use these two.

### 2. Give all terminating loops a statically determinable upper-bound

I added the distinction to specify terminating loops since explicit non-terminating loops are exempt from this rule.
Such non-terminating loops would be like a server loop, a process scheduler, or anything for receiving and processing.
Of which NASA says there should only be one non-terminating loop per task or thread.

The original wording from Power of 10 wording specifies "all loops must have a fixed upper-bound".
When I first read this rule I was initially perplexed about what it meant for implementation.
Did this mean NASA just never used functions like strlen or pass in size arguments?
Did this just mean to strictly use constant variables to sent bounds for array like structures?
This was probably the original intention since the length of a constant would not change.
Although what would be the proper handling when dynamic length was needed?
Since the length obtained is not fixed would it needed to be along side a fixed bound as well?
Something like `for(int i = 0; i < (length of array) && i < (max upper bound); i++){. . .}`?
This seems unnecessary though as would rule 5 and rule 7 check for this?
Luckily the JPL Coding Standard clarifies the rule by saying it shall be possible for a static analyzer to affirm the bound.
This is to say if you can obtain the exact number of iterations as an integer it is okay.
An explicit quote from the JPL Document says
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
    for(int i = 0; i < length; ++i){
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

NASA does not code for ordianary users.
It is not like a user is going to specify a file with -f or upload a file.
Applying this rule to a more general environment is then a little more tricky.
This rule is pretty easy to apply when traversing a structure where there are bounds, but this is not always the case.
Cases where the condition to terminate is outside your control, but your desire is to get out that loop come to mind.
Cases such as
- user input
- waiting for an event
- Waiting for the return value.
- Retrying a failed task.
  
Technically a bound can be placed on everything through the scientific power of picking a number.
This is a valid option to comply with this rule
For example, apt when prompting for Y/N to upgrade will only give you one try.
apt could give you many tries, but it was probably more simple this way than polling until proper input is given.
Maybe the program is reading from a socket that keeps giving bad data.
Perhaps it's okay to block until good data, but if the context is time sensitive returning an error after x attempts would make sense.
Either way it would have to be verified that only the specified conditions can terminate the loop.
The same would go for files, but they are not as clear cut.
Adding a limit would depend on what the file is for.
If a program depends on reading the whole file like reading line by line there would not be a reason to add a bound.
The program does not care how big the file is it is infact using it as a loop.
It really just cares about if the lines are valid.
Some cases the size of the file does matter.
Maybe it is expected that a file is only ever a certain size, so the program never reads past an amount of bytes even if the file is changed midway.
Generally it would depend.
It may make sense to add a bound it may not make sense.

#### Async & Sync

This topic is relevant to this rule since this is talking about predictable execution of multiple processes.
I do not have much knowledge in this for embedded systems, so I will mostly be quoting NASA.
NASA's power of 10 does not say anything about synchronous or asynchronous behavior.
Handling this kind of behavior is instead talked about in the JPL Coding Standard.
To maintain predictability NASA says that inter-process communication (IPC) should be the only way tasks communicate with each other.
Additionally, the way a task gets this information should be obtained from a single point in the task.
NASA claims that proper usage of IPC promotes separation of concerns and modularity while avoiding the need for error-prone semaphores, locks, or interrupts.
When it comes to shared memory NASA says ownership of objects should be passed around.
The JPL document also mentions threads which would need synchronization inside a process.
NASA says to never use task delays as it is a guessing game on how long a thread should wait which leads to race conditions.
Semaphores and locks should also be avoided, but if they must be used the locking and unlocking should be paired in the same function body.
The only exception they mention is a produce-consumer style of locking.
This is an attempt to prevent dead-lock where threads are waiting for a lock to be released, but they hold the lock other processes need.
Below I will provide some sources that explain this better than I can.

[Geek for Geeks IPC](https://www.geeksforgeeks.org/inter-process-communication-ipc/)

[Wikipedia IPC](https://en.wikipedia.org/wiki/Inter-process_communication)

[Geek for Geeks Semaphores](https://www.geeksforgeeks.org/semaphores-in-process-synchronization/)

[StackOverFlow locks, mutex, and semaphores](https://stackoverflow.com/questions/2332765/what-is-the-difference-between-lock-mutex-and-semaphore)

#### Task Timeout

Task time outs is setting a time limit that the program will wait for a task to finish.
This is useful to have on servers, so that a long running task can not be abused to create a DDoS attack.
Regex is one example.
There are some "evil regex" patterns that can act as a Denial of Service.
This Wikipedia article explains about it [Wikipedia ReDoS](https://en.wikipedia.org/wiki/ReDoS).
There may also be an asynchronous task like a network connection that is taking too long, so the program gives up and returns an error.

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

Even NULL checks after a malloc does not guarantee that the malloc was successful.
Linux's malloc() is optimistic and only allocates the memory once it is going to be used.
This can result in a crash from using memory thought to be available.
For these reasons dynamic memory is banned, but it is not banned entirely.
Most people take this as a rule to never use dynamic allocation which is not entirely true.
It forbids using dynamic memory at run time, but it can be used at the initialization phase to set a bound.
This would be the phase either before the call to main, or in main but calls to other functions to set things up.
Here the program can figure out how much memory it would need in total and make it.
In NASA's words they force the application to live in a fixed, pre-allocated area of memory.
Essentially they avoid the issue with the HEAP by making a single large allocation and then never freeing it.
This is what the NASA Power of 10 Document implies at least.
In the JPL document it says "after task initialization" which I believe refers to threads.
This would mean that the threads created would not be able to use dynamic memory.
What I am more confused about though is what does this mean for the task that is initializing the threads?
Is main the only thread allowed to make other tasks, or since main is thread 0 allocation for all threads is done at its initialization?
I am not entirely sure about this, but a safe bet is to initialize everything at program startup.

This would also mean some functions that return dynamic memory like strdup().
This could also mean standard library functions that internally use dynamic memory are banned, but I'm not entirely sure.
The printf family is one example.
Printf uses xmalloc which would abort the program on allocation failure.
I suppose this could be used as a safety check and ensure boundaries are not past, but that sounds dangerous.
They do include printf in rule 7, but that could just be an example.
Printf could also be avoided for other reasons like synchronization.
Perhaps there is a different implementation of printf that makes it safer.
The working suggests that only explicit dynamic memory is banned.

Explicit dynamic memory calls are these functions
- malloc()
- calloc()
- realloc()
- free()
- alloca()*
- sbrk()

\*alloca uses the stack, but still should not be used. The man page explains [alloca() man page](https://www.man7.org/linux/man-pages/man3/alloca.3.html).

Some ways to imitate dynamic behavior
1. Set maximum bounds for input
2. Object pools
3. Ring buffers
4. Arenas
5. Pre-allocate

NASA's environment is different than most people.
I can't say to avoid dynamic memory completely for all general programs, but I can say to keep explicit allocation to a minimum.
This way as few mallocs need to be tracked, and it allows usage of the printf family or fopen.
Dynamic memory can very easily be mismanaged, so it is important to use it only when necessary.
Each extra allocation is another risk so handle it properly.

### 4. Function Length should be printable on a page with one statement per line

The principle of this rule is to treat your functions as small logical units.
Longer "everything" functions are often a sign that logic is poorly thought out, or that stratification is needed.
Not only is it harder to debug a large function because of its size, but it also much slower to understand in the first place.
Having to scroll down or jjjjjjjj/kkkkk to find far separated code can feel like walking into many rooms and forgetting why you are there in the first place.
So you jump back to where you had a foot hold of understanding because "ahh it was that variable I am concerned about".
Then you scroll too far down trying to find where you are stuck.
Creating smaller functions keeps the logic within one screen, so it is much easier to audit and find mistakes.
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
Spinroot's interpretation is defined by actual code excluding comments and empty lines.
They take the file and normalize it to account for different styles and then count each line.

#### All the Single Lines

What every interpretation had in common though, was that each statement and declaration should be on separate lines.
This is to avoid cheating the rule with statements like `unsigned int i, n, h, w, x, y, mw;` or `int i, j = 1`.
It avoids statements like `int* x,y,z` where only x is actually a pointer and the rest are ints.
You would need to do `int* x, *y, *z` instead to make them all pointers.
Statements that can create confusion at first glace like `int i, j = 1` are also avoided.
Here both i and j are assigned one, but at first glance it can seen as if i is assigned a default value and j as 1.
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

This is difficult to read because the conditional is split and the incremenation is dangling there.
Now I understand that the casting is pushing this to be a very long line.
Excluding indentation, it would span 95 columns and the hard limit could be 80.
```
 for (char_ptr = str; ((unsigned long int) char_ptr & (sizeof (longword) - 1)) != 0; ++char_ptr)
    if (*char_ptr == '\0')
      return char_ptr - str;
```

There are ways to fix it that I won't go over.
Just know that edge cases like these can exist.

#### Ifs and Whiles

The mention about for-loops got me a little curious on what this meant for ifs and whiles.
The conditional statement is separated by && and || (or even bitwise & |) instead of semicolons.
Sometimes these boolean expressions can get a little long, so what does this rule mean for them?
I think the preference is to maintain a single line if possible, or even better just have a simple boolean expression.
This is not always possible, so to aid readability separation is acceptable.
Usage of a function would also work.

```
/* one line if */
/* curly brackets inclusion would depend on coding style */
if( x < 5 )
    flag = 1

if( x < 5 ){
    flag = 1
}

/* long conditional one line */
if( index > 5 && other_variable < index && some_other_thing / 2 >= index){

}


/* long conditional split */
/* splitting would depend on coding style */
if(
    index > 5 &&
    other_variable < index &&
    some_other_thing / 2 >= index
){

}

if(booleanFunction(index, other_variable, some_other_thing)){

}

```

#### Function Parameters

Another part of this rule is a preferred maximum of 6 parameters.
Having too many parameters can harm clarity not just for the function itself, but also for the callee function needing all those parameters.
Personally for me, having more than 4 parameters is too much.
There is also a more technical reason that the 7th and beyond parameters are placed on the stack instead of a register, so their values could get corrupted indirectly.
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
Typically assertions are removed for user convenience in non-safety critical applications, but safety critical systems may want to keep them.
If you want to modify the behavior of the default assertion, or don't want them to be removable you can create your own.

This brings up a question on how to write an assertion.
Assertions should
- Evaluate strictly to a boolean expression
- Contain no side effects
- Have a recovery action on failure
- Be proven that it can fail or hold

```
assert(a - b) /* not a boolean expression */

assert(++x > 10) /* assertion changes the value of x */

if(my_assert(some_pointer == NULL) == true ){
    x = 5;
} /* no recovery taken */

int sum = a + b;
assert(sum - b == a) /* a + b - b  == a will always be true even in overflows */
```

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

They also mention static assertions which are assertions that are checked at compile time.
NASA gives this as an example `c_assert( 1 / ( 4 – sizeof(void *));`.
This will trigger a divide by zero warning if the compiler is using a 32-bit machine.
This is because 32-bit systems have pointers that are 4 bytes while 64-bit systems use 8 bytes.

### 6. Data objects should be declared in their lowest scope

In C this is the best way to accomplish data hiding.
If a variable is out of scope then it can't be modified or referenced.
This has the benefit of reducing what can be corrupted and makes debugging easier.
For the most part, this is as simple as declaring the variable at the point of first use for automatic storage variables.
However, C has some other neat features that makes this rule slightly more complicated.

#### Static

Typically `static` is know for declaring a variable that persists within a function.
For the most part this should be avoided as it is an easy way to create side effects.
However, static in C can be used on a function to specify that its scope is within the file.
More specifically it is indicating internal linkage.
It is kind of like creating a private method since it will be usable only in that source file.
These type of functions should **NOT** be declared in the header file, and they should reside in just the source file.
Defining a static method in the header file would give each file that includes the header a separate function definition.
It defeats the purpose of specifying internal linkage, and really is not necessary.
Although If you were crazy you could try to make your very own Java Interface in C if you really wanted to.

Example of defining a static method
```
static void someFunction(){
    . . .
}
```

#### Extern

The opposite of `static` in C would be `extern`.
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
It is basically a function that strictly takes what it is given and will give the same result each time when given identical arguments.
This can be aided with the use of const and enums to declare that this is something that won't be modified.
Const especially should be used on reference types whenever possible.
This wikipedia article explains a little more [Pure Functions Wikipedia](https://en.wikipedia.org/wiki/Pure_function)

### 7. Check all return values of non-void functions and validate passed in parameters

This rule is the flip side of rule 5.
Just like rule 5, this rule is critical to defensive coding, and can be implemented in any language.
While rule 5 is for checking if programmers are making errors, validation checks if the data given has errors.
There is an expectation that invalid data can be given, or it makes sense to check for invalid data and return an error.
Essentially this rule helps to create robust programs that can handle most situations.

#### Return Value Checking

There is not much of a reason that the return value of functions should not be checked.
The only case where the return value would not matter is if the case of error and success results in the same response.
NASA gives printf and close as an example.
In such matters, casting to void is an acceptable way to explicitly express this `(void)printf("%s", "Hi")`.
This way others know the return value is purposely ignored, but also allows for questioning if it should be ignored.
In most cases though the return value should be checked because it is main way C communicates something went wrong.
This is especially true if the function needs to propagate the error up the call chain.
This type of behavior would also extend into programmer made functions.
As the function is being created there is a thought about what can go wrong with each step.
Since you are checking for error status you have an incentive to return an error status.

#### Validating Parameters

Validating parameters is one of the most important rule to have in any security focused guideline.
So many vulnerabilities occur from simply not checking parameters especially in public functions.
Public functions are well. . . public, so they can accept any kind of input from anywhere.
Therefore, it is important to make sure that public functions can actually use the parameters it was given.
Private functions should also validate their parameters although depending on the context assertions can be used.
In either case, the principle of creating total functions is preferred where functions can handle any input.
This means creating functions that can handle any kind of input.
It does not matter whether the parameters are valid or invalid the function will handle it accordingly.

Example of validating parameters using the third example from rule2.
```
/* here size includes the NUL byte* /
char* charSearch(const char* string, char needle, int size){
    if(string == NULL || !isalnum(needle) || size <= 0)
        return NULL;

    for(int i = 0; i < size - 1; ++i){
        if(string[i] == needle)
            return string + i;
    }
    return NULL;
}
```

However, you don't always create the functions.
Sometimes you are using a provided function that does not conduct validation.
NASA gives the example of strlen(0) and strncat(str1, str2, -1).
In these cases it is applicable to check the parameters before calling the function.
Conceptually it is better to include validation in your functions since it is more intuitive for the caller.
Functions can be thought of as interfaces.
You plug in your values and expect some value.
Depending on what value you get is what you'll do.
Having to remember to check the parameters before calling to ensure a valid result is not expected.

MISRA C 2004 rule 20.3 mentions some ways of conducting validation
- Check the values before calling the function.
- Design checks into the function.
- Produce wrapped versions of functions, that perform the checks then call the original function.
- Demonstrate statically that the input parameters can never take invalid values.

#### Try/Catch

The way try/catch uses this rule is. . . interesting.
I do not expect NASA to use try/catch as it violates creating an explicit clear control flow specified in rule 1 and violates predictable execution.
In fact, goto and setjmp/longjmp are banned in rule 1, and they are the only two mechanisms that could implement a pseduo exception system in C.
All this rule is saying is to check the return value of the function and to check the validity of parameters.
It is as simple as creating a clear line of if statement, but people did not like ifs all over their code so try/catch was created.
The question is how does try/catch implement this rule?
For validation it is pretty easy.
It would functionally be the same except it just returns a more specifc exception rather than a sentinel value.
```
/* using modified example from above */
int searchWrapper(String string, char needle){
    if(string == NULL || !isalnum(needle))
        throw new IllegalArgumentException("Null argument given")

    return string.indexOf(needle)
}

```

Higher level languages tend to avoid status errors because exceptions are a way to force compliance.
The way C handles errors allows for errors to be silently ignored if not checked for hence this rule's existence.
Hence why it is a feature that exceptions will bubble up to what ever can handle it, and if it reaches the very top the program crashes.
Although it is not like C can not do this.
NASA mentions it themselves that error values must be checked to return it up the call chain in effect creating this bubbling effect.
It is just more clean looking in higher level languages.
The more nuanced part of try/catch is the how it applies to checking the return value of functions.
An exception is not exactly a return value.
It is an indication of error that so happens to act as a return value when it occurs.
This is where the nuance in the implementation of this rule exists because how it is treated as a return is dependent on the language's main philosophy.

#### Easier to Ask For Forgiveness than Permission (EAFP)

This philosophy encourages assuming you have valid behavior, but when some exception occurs to handle it.
The thinking is more like "oopsie can't do that lets try this instead".
Python is one such language.
try/catch is used as the control flow mechanism acting more like if/else, and tends to use the try/catch itself as lazy validation.
In a way exceptions are treated as a return, so it is part of control flow.
This kind of philosophy would not pair well with safety critical systems as it is hoping to encounter an error first before handling it.
Additionally C is not going give you forgiveness.

Example of EAFP:
```
try:
    value += dict_["key"]
except KeyError:
    pass
```

#### Look Before You Leap (LBYL)

Languages that have a philosophy of LBYL act to prevent an exception happening in the first place.
This may be because there is no exception handling system like in C and Go, or performance cost when an exception occurs is a larger concern like in Java or C++.
It typically handles expected common control flow rather than catching a commonly expected exception.
Simple if statements are preferred for simple validation rather than exceptions.
More complicated validation could encapsulate the effort into a try if the validation is known to be robust.
It reserves exceptions for cases where it is truly exceptional that expected behavior faltered, or when an exception is outside the programmer's control.

Example of LBYL:
```
if "key" in dict_:
    value += dict_["key"]
```

#### How Does This Rule Affect Try/Catch

In reality a mix of both philosophies will be used in coding.
It is true that LBYL can create race conditions, so EAFP is preferred sometimes.
A good example is opening a file.
It is better to simply try and open the file rather than test if it exists then open it as that exposes a race condition.
In C this would be an fopen/open call and checking directly afterwards if it is NULL/-1.
It is not like C is strictly a LBYL language, it just handles exceptions by returns.
Try/catch just takes out the error portion of the return.
It puts the error handling into its own separate explicit place if it were to occur.
This mean if the caller got their return with no exceptions it is an expected return.
It does not mean however that it is the desired value.
The return value could be empty, or some other expected indication of invalidity.
As an example Java's indexOf returns -1 if it could not find what it was given.
This means that rule 7 still applies but checking for issues is split.
There is the side checking the expected return, and there is a side checking the exceptional return.
Sometimes try/catch the only way to catch any kind of error because the return is always valid.
Although, the programmer is not forced to catch an exception if they can't handle it.
It is perfectly acceptable to just try and have the catch somewhere up above.
Only handle exceptions that can be handled at that exact point.
It is important to not swallow bubbled up exceptions because it can leave the program in a bad state.
As a note, simply printing out a message is not handling an error.
It's like pointing out the house is on fire then going back to watching TV.
However, it is important to know what exactly is on fire.
Yes the exception tells me there is a fire, but what in the control flow triggered it.
It could be several function calls deep or masked within nested operations like `array1[array2[x]]`.
This is why try blocks should be confined to what can actually throw sparks.

//program encased ni try 

### 8. The preprocessor should be left for simple tasks like includes, simple macros, and header guards

In C, the preprocessor is a tool that allows the code to be altered just before compiling.
It is essentially a text substitution tool capable of simplifying tasks, but also capable of creating stupidly unreadable code.
It is a very powerful obfuscation tool that if used haphazardly can harm readability for humans, tool based checkers, and debuggers.
With this obfuscation, it is important that the macro itself is syntactically valid which would mean encasing the body in parenthesis or curly brackets.
Within the macro itself it should not hide pointer dereferencing or declarations.
The Macros themselves should reside only in the header file and not in the middle of scope or functions.

So what exactly would be a simple macro?
Simple can be subjective, but listed below is for sure simple.
- File inclusion
- Constant values
- Constant expressions
- String literals
- Braced initializer

Below can be simple, but can be complex depending on what is being done.
- Macro expanding into an expression
- Do while zero construct

The do-while one is a bit weird.
From what I've researched it seems to try and avoid the faults of the preprocessor.
It is a way to create more complicated expressions while maintaining scope and having to insert a semi-colon at the end.
It's a little bit of a hack, but compiler optimization will remove the do while portion.

shown below are some examples
```
#include <stdio.h>                  /* including standard library */
#include "MyHeader.h"               /* including programmer made header */
#define FILE_A "filename.h"         /* string literal */
#define PI 3.14159F                 /* Constant */
#define XSTAL 10000000              /* Constant */
#define CLOCK (XSTAL/16)            /* Constant expression */
#define PLUS2(X) ((X) + 2)          /* Macro expanding to expression */
#define INIT(value){ (value), 0, 0} /* braced initializer */
#define READ_TIME_32() \
    do { \
        DISABLE_INTERRUPTS (); \
        time_now = (uint32_t)TIMER_HI << 16; \
        time_now = time_now | (uint32_t)TIMER_LO; \
        ENABLE_INTERRUPTS (); \
    } while (0)                     /* example of do-while-zero */
```

Below are things the preprocessor should not be used for.
- Redefining the language
- Hide pointer dereferencing

```
/* the following are NOT compliant */
#define int32_t long          /* use typedef instead */
#define STARTIF if(           /* unbalanced () and language redefinition */
#define CAT PI                /* not syntactically valid */
#define DEREF(p) ((*(p)) + 2) /* dereferencing */
```

The C preprocessor can do much more than simple defines and includes though.
It is quite an extensive tool with a few secrets.
Below I will explain some of the secret powers and if they should be used.

#### Function Like Macros

Function like macros are not banned under NASA's rule, but caution should still be used.
In basic terms, a function like macro is defined as any macro that takes in arguments.
They can even be used as a way to ignore types as long as the proper type expected is passed.
it is defined like `#define <name of macro>(<arguments>) <definition using arguments>`.
Note that there is no space after the name and parenthesis for the arguments.
This is because if there is a space it would create an object like macro instead.
A few examples are below.
```
#define MAX(a,b)  ((a)>(b) ? (a):(b))
#define MIN(x,y)  ((x)<(y)) ? (x):(y))
#define SQUARE(z) ((z) * (z))
#define ADD_TWO (a, b) ((a) + (b)) /* not valid. The macro expands to (a, b) ((a) + (b))*/
```

Now remember that the preprocessor will just copy and paste the values into the expression.
This is why the arguments are surrounded in parenthesis to maintain correct order of operations.
If an expression like `3 + 4 * 9` were used in SQUARE without parenthesis it would expand to `3 + 4 * 9 * 3 + 4 * 9` instead of `(3 + 4 * 9) * (3 + 4 * 9)`.
This would mean an evaluation of 147 instead of 1521.
However this doesn't solve other side effects like incremenation.
Using an expression like `MAX(x++, y - 1);` in the MAX macro would result in `(x++) > (y - 1) ? (x++):(y - 1);`.
This can result in x getting incremented twice and seemingly give the correct post-fix value if it is the max value.
This can also lead to unspecified behavior in the SQUARE macro `SQUARE(++some_int); - > ((++some_int) * (++some_int));`.
One way to avoid this kind of side effect is to use the typeof() preprocessor method, but this is GNU specific.
`#define SQUARE(x) ({ typeof (x) _x = (x); _x * _x; })`.
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
In C, these statements are used as header guards like so
```
#ifndef <HEADER_FILE>
#define <HEADER_FILE>

/*your declarations here*/

#endif
```

NASA says this is how far you should go with these conditionals.
NASA is strictly against conditional compilation in any context, and any use of them outside of header guards will need heavy justification.
This is because they create different versions of code that can make it difficult to test effectively.
NASA gives an example of 10 conditional compilations creating 2^10 possible versions which would be 1,024 things to test.
Imagine having to debug 1,024 different versions each with a different source code.
It is not like static analysis could help because it would not know what would be compiled.
Then there has to be a consideration on if changes in one version will affect all the other versions.
Very quickly this becomes a mess to test and understand.
From what I have read the most preferred way to handle different platform is to use separate files, and to link according to the environment.
It may not be possible to avoid the dangers of conditional compilation though.
If you must use conditional compilation beyond the standard header guard, all `#else, #elif, and #endif` must reside in the same file as their `#if, ifndef, or #ifdef` as per rule 23 in the JPL Standard.

#### Token Pasting

Token pasting is probably something most new people to C haven't even heard about.
Its usage is defined by using "##" inside the #define macro.
This operation takes two tokens and concatenates them into one token.
Example: `#define combine(arg1, arg2) arg1 ## arg2`
This example would combine arg1 and arg2 into one token.
In these two examples both would print out 3.
```
#define xy 3
#define combine(arg1, arg2) arg1 ## arg2
printf("%d\n", combine(x, y));

-----------------------------------------------

#define combine(arg1, arg2) arg1 ## arg2
Some
int xy = 3;
printf("%d\n", combine(x, y));

```
However if you were to surround x and y in quotes it would create "x""y" which is not a valid token.
Token pasting is sneaky little tactic that makes it hard to read what the intention is.
It's like reading two unrelated things, but some how it just made something.
It can very quickly create hard to read code for humans and tools, so NASA bans it to keep things simple.

#### Stringize
On the other hand '#' is the stringize operator, and it turns the given parameter into a string.
It allows for a more dynamic way to create string literals.
The assert statement in rule 5 is a good example.
The way that it accomplishes this is by surround the argument in double quotes.
If there are already double quotes it will escape them.
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
It just turns the given parameter into a string, so it doesn't allow for sneaky stuff like token pasting or recursive macros.

#### Recursive Macro Calls

The thing about Macros is that they are not recursive.
Once the macro expands it will not expand into itself again if it was directly from the previous pass.
This is refereed to as `painted blue`.
People have gotten around it by deferring one extra step so the macro expands into another expansion that calls the desired macro.
In effect it is basically a hack to get around the preprocessor and it creates incredibly unreadable code.
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

This StackOverFlow post explains in more detail [recursive preprocessor to create a while loop](https://stackoverflow.com/questions/319328/how-to-write-a-while-loop-with-the-c-preprocessor/10542793#10542793).

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

This was found at this StackOverFlow post [variadic macro for function defining](https://stackoverflow.com/questions/48284705/how-to-use-variadic-macro-arguments-in-both-a-function-definition-and-a-function).
Their usage also tends to lead to unreadable code like with recursive calling macros.

#### Variadic Functions

Although not explicitly a preprocessor defined behavior, defining variadic functions are also banned.
The rule does specify anything with variadic behavior using ellipses (anything with ...), and the JPL Coding Standard references specifically MISRA C 2004 Rule 16.1.
There is not an explicit reason why defining variadic functions are banned, but I think it is probably to reduce complexity and allow better static analysis.
It could also be because of rule 7 in needing to verify function parameters.
Normal function parameters have an explicit type, but variadic functions can accept any number of arguments that can be any type with no way to verify type.
They are also an easy way to introduce security risks due to improper usage or passing in unexpected values.
Personally I've never needed to use a variadic function, and when I did think about using one I simplified my code instead.

### 9. Pointers should at most have two levels of dereferencing

Pointers are an essential tool in C, but as NASA says even the most experienced misuse it.
They are the cause of a lot of segmentation faults, security vulnerabilities, and bad code, so it is important that their use is limited and clear.
Once again NASA points to static analyzers and humans having potential trouble understanding the flow.
Originally, the NASA power of 10 doc only allowed one level of dereferencing, but the JPL document changed it to no more than two levels of dereferencing.
As an extension, this means declaration of pointers should have no more than two levels of indirection.
I guess the reason for JPL altering the rule is be less restrictive and allow direct usage of 2D arrays and pointers to pointers.
Pointers are a large data type, so NASA may have wanted to reduce stack usage by decreasing holding value pointers.
Most of the time though you will only ever need two levels of indirection, but programming is programming and there are exceptions with justification.
These cases are pretty rare, so sticking to two levels is much preferred.
Below are some examples from MISRA C advisory rule 17.5.
```
int8_t * s1;    /* compliant */
int8_t ** s2;   /* compliant */
int8_t *** s3;  /* justification needed */

void someFunction(char* some_parameter){. . .}   /* compliant */
void someFunction(char** some_parameter){. . .}  /* compliant */
void someFunction(char*** some_parameter){. . .} /* justification needed */

/* Not from MISRA C */
/* if more than 2 levels is required */

int8_t*** three_dim_array = < some address >
for(int i = 0; i < LENGTH_OF_THREE_DIM; ++i){
    int8_t** two_dim_holding_value = three_dim_array[i]
    /* stuff done with holding value */
}

```

#### Function Pointers

Function pointers on the other hand are advised to be avoided unless it is const.
The original NASA Power of 10 document completely prohibited function pointers due to static analyzer concerns.
The JPL document then changed this to allow const function pointers since static analyzers could follow const function pointers.
Apart from static analyzers, rule 1 would apply to function pointers.
Function pointers that keep changing values off dynamic input makes it difficult to determine where the code will end up.
If function pointers are to be used, they should be as explicit as possible to know where they go.

#### Dereferencing

There are multiple ways to dereference something, so this rule isn't just strictly on the usage of \*.
Rule 27 in the JPl document is clear in saying
> Statements should contain no more than two levels of dereferencing per object.
The three dereferencing operators are `[]`, `*`, and `->`.
- \* is the standard dereferencing operator
- -> is for accessing a member from a struct pointer
- [] is dereferencing with a given offset in arrays

These operations should not be hidden in a macro or inside typedef declarations.
```
typedef int8_t* INTPTR
INTPTR* some_pointer; /*creating a double pointer and hard to figure out what the intent is */

#define GET_VALUE(x) (*x)
GET_VALUE(*x) /* expands to **x */
```

The act of dereferencing should be clear as it is one of the most common cases for a segmentation fault or memory bug.
It should be clear what is getting dereferenced and in what order.
Using parenthesis is quite helpful to explicitly show the order.
Below are some examples.
```
/* This example uses all three just to show a point */
*some_struct->pointer_array[x]
vs
*((some_struct->pointer_array)[x])

*p++
vs
(*p)++
or depending on intention
*(p++)

```

#### Pointer Arithmetic

Pointer arithmetic and comparison shall be limited to just array objects and within the bounds of said array object.
The most preferred arithmetic method is using the `[]` operator to access elements.
It is explicit in saying it is done on an array and at this index.
The index should be validated that is it within bounds, and that overflows have not occured.
You do not need to account for the size of the elements when indexing since it is handled automatically.
`struct_array + 1` will go one index forward while `struct_array + sizeof(struct)` will index forward how ever much the size of the struct is.
This means if the size of the struct is 8 it will index 8 times instead of 1 time.
MISRA C rules 17.1 - 17.4 explains some other rules on what is best.

### 10. Compile with the most pedantic compiler settings with no warnings and check daily with static analyzers

This rule is language dependent, but popular enough languages should have several tools that are free or proprietary.
NASA says there is no excuse to not use these tools for any development, and they are right.
If you want to take security more seriously looking into static analyzers is a great step.
The usage of a static analyzer actually helps to forcefully implement some of these rules especially rule 1.
If the static analyzer or compiler gets confused because of control flow then it means rule 1 is broken.
A good compiler can give quite deep warnings, but a static analyzer can go into even more detail.
For example, NASA mentions a lot about bounds in their rules which a static analyzer can determine, but not a strict compiler.
A compiler can combine some aspects of a static analyzer for convenience, but it may not be as extensive.
Once again this depends on the language.
C has great compilers, but weakly typed languages may barely have any flags for checking.
Combined with the fact that each language has their own issues it is more beneficial to use a tool meant to catch those issues.

#### C

C has a few compilers like GCC and Clang, but I will only go over GCC since that is what I know.
The most basic flags in GCC that help with getting as many errors as possible are `-Wall -Wextra -Werror -Wpedantic`.
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
This is a very helpful flag for catching those pesky buffer overflows or off by one errors.
Note that you should not ship out your code with ASAN enabled since it is for debugging memory and adds overhead.
In recent development, GCC now comes with a static analyzer with the `-fanalyzer` option family if gcc is configured to use it.
This option looks at program flow, and tries to find bugs like double frees and leaked open files.
It can even help with rule 1 wth the `-fanalyzer-too-complex` flag which warns the user if the internal limit is reached.
For a list of static analyzers for C Spinroot shows some here [Spinroot Static Analyzers for C](https://spinroot.com/static/).

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

I have not really used Java extensively, but this is here to show that sometimes you just need to look at the man page to know what options you have.

#### Python

Python has options like `-b -Werror -Walways -X dev`
There is also the `-I` option for isolating the program.
It does this by ignoring Python's environment variables, and removes the script's path from sys.path.
This is more of a security option than a compilation option though.
Due to python being an interpreted language it does not have as many options compared to C or Java.
For weakly typed languages it would be more beneficial to use a static analyzer to catch errors faster.

#### Other Languages

This wikipedia article shows some static code analyzers available [Wikipedia list of static code analysis](https://en.wikipedia.org/wiki/List_of_tools_for_static_code_analysis)
It is not an extensive list of all that is available, but most languages have some form of static analysis.
Even more obscure languages like R have an option to use, and apparently there is a talk about static code analysis for APL.
Why anyone would use these languages in a serious context who knows, but this is just to show a point that there are options.

## Conclusion

Hopefully now you understand what NASA's Power of 10 means.
It is not just a security guideline, but a mindset to follow.
TigerBeetle is not wrong in stating that these rules will change how you code forever.
You are more conscious in how you code for yourself and others.
You appreciate what it means to make robust code because it is not just about handling incorrect data.
It is having a plan for whatever can go wrong.
You try your very best to make code that is as correct as possible.
NASA knows that these rules may seem draconian, especially with rules like 3 and 1, but remember these guidelines were developed where lives depend on correctness.
Applications like planes, nuclear power plants, cars, or medical machines have people's lives at risk.
You are right to say not every situation is safety critical and does not require these rules.
You are right to say that it is impossible for some languages to follow every rule here.
However, maybe the question is not if you can implement every rule, but what rules you can implement.
Yes, these rules are for C, but this should not block you from taking another look and finding out what you can do.
To show this, the table below will visual what category a rule relates to, and the reason as to why or why not the rule is C specific.

| Rule | Category |  C Specific | Reason       |
| :--: | :------: | :---------: | :----------: |
| 1    | Code Clarity<br>Predictable Execution | No | Control flow is created by the programmer. |
| 2    | Predictable Execution | No | Any loop can be set to have bounds. |
| 3    | Predictable Execution | Yes | C and C++ manually manage memory.<br> Garbage collected languages do not have as much control. |
| 4    | Code Clarity | No | Programmers make large functions. |
| 5    | Defensive Coding | No | Assertions can be created in any language. |
| 6    | Defensive Coding<br>Clear code | No  | Any language with scope can declare at lowest scope. |
| 7    | Defensive Coding | No | Any language with functions and returns can check them. |
| 8    | Code Clarity | Yes | Not all languages have a preprocessor as extensive as C. |
| 9    | Code Clarity<br>Predictable Execution | Yes | Not all languages can control pointers like C can.<br>OOP or weakly typed languages still have them implicitly but are used differently. |
| 10   | Language Compliance | No | C just so happens to have great compilers compared to other languages.<br>Any popular enough language has a static analyzer |

## Sources

[Original NASA's Power of 10](https://spinroot.com/gerard/pdf/P10.pdf)

[Other NASA's Power of 10](https://web.eecs.umich.edu/~imarkov/10rules.pdf)

[JPL C Coding Standards](https://github.com/stanislaw/awesome-safety-critical/blob/master/Backup/JPL_Coding_Standard_C.pdf)

[Spinroot Power of 10 Explanations](https://spinroot.com/p10/index.html)

[MISRA C 2004](https://caxapa.ru/thumbs/468328/misra-c-2004.pdf)

[Guidelines on Software for Use in Nuclear Power Plant Safety Systems](https://www.nrc.gov/docs/ML0634/ML063470583.pdf)

[Tiger Beetle](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)

[Low Level NASA Power of 10 Video](https://www.youtube.com/watch?v=GWYhtksrmhE)
Thank you Low Level for getting me interested in NASA's Power of 10 in the first place
