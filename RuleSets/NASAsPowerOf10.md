# NASA's Power of 10

## Description

NASA's Power of 10 is a very powerful and strict rule set tailored to developing safety critical software.
This is software where people's lives, equipment, or the environment is at risk.
This has not stopped TigerBeetle using these rules for online transaction processing for businesses.
In a broad sense, it's software where people's lives depend on correct implementation.
Keep in mind as you read that these rules focus on **safety critical C Code**.
This means that some of NASA's reasoning relates to the woes of C and how to make C safer.
This results in people hardening their mind to these rules, but I believe people should not.
I feel it is important to read NASA's power of 10 as it changes your mind to be more defensive.
Not every situation is safety critical or uses a C like language.
In most situations this should be treated as guidelines to follow rather than strict adherence.

Below is my interpretation for NASA's rules.
Even if the rules are meant for saftey critical C, I want to see how applicable they are to general coding and other languages.
For example, the rule about the HEAP may not be practical to everyone, but understanding why it is banned helps you minimize it's usage.
Other than your language, implementation of the rules depends on your team's beliefs.
If you have a team like TigerBeetle that's enthusiastic about implementing NASA's power of 10 that's great.
If your team just wants to get the web app pushed maybe not.
If the team is yourself making a little personal project it would depend on what constraints you have.

I recommend you read the sources to see NASA's reasoning.
For example, a lot relates to static analysis.
The NASA power of 10 doc that most people see is a good document, but misses some details provided in the JPL C Standard and MISRA C documents.
I would heavily suggest you read the documents in sources.

## Note For Other Languages

I understand that this rule set is focused on C.
For example, the more C focused rules like HEAP usage, the preprocessor, and pointers can't apply to all languages.
Weakly typed and some OOP languages abstract away the HEAP taking away some control.
Some languages abstract away pointers into objects or arrays.
Some preprocessors amount to just import statements.
There is also a rule about compiling with max pedantic-ness which depends on your compiler.
Every language is different, so you should read security standards for your language.
For C there is SEI CERT, and web development has OWASP.
You may not be able to implement every rule, but some of NASA's rules relate to readability and defensive coding which any language can implement.

## The Rules

### 1. Restrict code to very simple control flow constructs

This rule in combination with 4 and 6 helps create clean code that's easy to audit for humans and tool-based analysis.
Readable code is considerably easier to make secure and maintain.
A simple control flow can reveal logic errors that otherwise could have remained hidden by weird control flow.
Basically, the rule aims to make your control flow as explicit as possible.

To help facilitate a simple control flow, NASA bans the usage of goto, setjmp, longjmp, and recursion.
From what I can see though, they do not say anything about break or continue statements.
I know some of my professors absolutely hated break and continue.
I see where the disdain comes from, but I personally don't agree with it.
They are useful, but they should not be abused.
They are restricted to loops and are constrained enough in what they do to flow.
Speaking of flow, NASA doesn't restrict functions to a single exit point.
Single exits can simplify things, but when you add validation it's often simpiler to exit early.

#### Recursion
It is true that recursion can create small easily readable functions, but they do have a cost behind the scenes.
NASA avoids recursion as they must have certainty in stack bounds.
They want to have an acyclic function call graph that proves execution falls within bounds.
What I like to call the "recursion tax" where each method call adds its parameters, return pointer, and frame to the stack can pass the bounds of the stack if the tax becomes too much.
Tail recursion optimization solves a big problem with recursion, but there still looms the threat of stack overflows.
Your testing could show it is within bounds, but what happens during unexpected behavior?
In this case all you really know is it should eventually reach the base case or blow out the stack.
With the absence of recursion, NASA can handle run away code in a simple manner specified in rule 2.
On top of that there is Threading.
Each thread has their own stack in the same memory space, so it is possible for a recursive function in a thread to completely clobber another thread.
I do recognize the usage of recursion.
Some problems may just be too complex for iterative implementations like trees or parsing a JSON.
Depending on the language, recursion can be avoided, but it is more of an avoid it if you can for general programming.

#### Goto
Goto is a little weird.
Goto isn't inherently evil as some think.
A lot of the hatred is from a time where it was rampantly abused, and this hatred has been passed along.
I've seen some valid uses for goto like jumping to handle clean up.
Labeled breaks in Java are also an interesting case.
Goto has this niche usage that can aid in readability, yet feels like a forced eyesore.
It makes sense why it's banned for what it can bring, and its ban doesn't hurt anything.
For general programming you very rarely will need something like goto.
If you must use goto think about how the code and be refactored.

#### Setjmp() LongJmp()
Setjmp and longjmp make sense to ban given the embedded environment and safety critical requirements.
Even the man page suggests they should be avoided as they make code much more difficult to read.
Setjmp() saves the program state into env passed in for longjmp() to restore back to.
It's basically a super sized out of scope goto without the label.
I haven't used them since I was never in a position to use them.
Supposedly they are useful for getting out of deep errors or for exception handling.
However, rules 5 and 7 should catch the exceptions before they occur.
Its usage can bring a few vulnerabilities.
For example, the man page says automatic storage variables are unspecified under certain conditions after a longjmp().
Automatic storage specifies block scope and is the default.
This GeekForGeeks page explains storage classes (Storage Classes in C)[https://www.geeksforgeeks.org/storage-classes-in-c/].
These two shall not be used in general programming.

### 2. Give all terminating loops a statically determinable upper-bound

I added the distinction to specify terminating loops.
The original wording says "all loops", but later specifies non-terminating loops are exempt.
NASA says there should only be one non-terminating loop per task or thread for receiving and processing.
Loops like waiting for network requests or server loops.

This is where the wording I felt was a little confusing in the original Power of 10 document.
As mentioned, it says all loops should have a fixed upper bound, but lots of times you would take the length of something.
Would you then need to have the length obtained as well as a fixed upper limit in case the length is wrong?
Something like `for(int i = 0; i < (length of string) && i < (max upper bound); i++){. . .}`?
I feel like if that was the intent of the wording validation of the length would be better.
Luckily the JPL Coding Standard clarifies the rule by saying it shall be possible for a static analyzer to affirm a bound.
This is to say if you can obtain the exact number of iterations as an integer it is okay.
This would also apply to for-each loops too since it is implicit.
NASA gives a more explicit quote here in the JPL Coding document.
> "For standard for-loops the loop bound requirement can be satisfied by making sure that the loop's variables are not referenced or modified inside the body of the loop".

In this linked list example a limit is added since there is no known ending.
```
Node* listSearch(const Node* node, int needle){
    int count = 0;
    while(node != NULL && count++ < MAX_ITERATIONS){
        if(node->value == needle)
            return node;

        node = node->next;
    }
    return NULL;
}
```

String example obtaining a length
```
char* charSearch(const char* string, char needle){
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
/* here size includes the NUL byte* /
char* charSearch(const char* string, char needle, int size){
    for(int i = 0; i < size - 1; ++i){
        if(string[i] == needle)
            return string + i;
    }
    return NULL;
}

```

Lets say you want to find the length of the string.
You may not have a terminating NUL byte which is your ending condition
Here you can not get the length, so you would give a bound.
I'll give a an error condition this time.
```T
int myStringLength(const char* string){
    int count = 0;
    while(string[count] != '\0'){
        if(count > MAX_STRING_COUNT){
            /*exit or return error*/
            return -1
        }
        ++cTount;
    }
    return count;
}
```
You could then use this to verify that you add a NUL byte to your strings at that length.

//still not happy with this
#### Special Cases
Things are a little tricky with loops that are technically both or parsing files.
I couldn't find exact wording on how to handle these conditions, so I will give my educated guess.
Case 1 is a while loop that blocks until it reaches a condition to exit.
Like taking user input.
Case 2 is reading from a file given by the user which could have any size.
Even if you were given a gigantic file there is only as much storage on disk.

As one of my professors would say it depends.
A user can put as many wrong inputs as they want, but is it a login page or your app's menu?
If it's a login then it makes sense to add a time out limit on too many incorrect attempts.
An app menu not so much, but you can make the decision to add an upper bound on attempts.
Files do have an implied ending to them.
Unless you have special criteria for files it should be fine to read until the end without a max bound.

#### Async
I didn't see anything about asynchronous functions in NASA's documentation, but it is a common practice to set a timeout for asynchronous things.
This way your program won't hang there waiting, and you can return an error.

#### Task Timeout
Regex is one example.
There are some "evil regex" patterns that can act as a Denial of Service.
This Wikipedia article explains about it (Wikipedia ReDoS)[https://en.wikipedia.org/wiki/ReDoS]

### 3. Do not use dynamic memory after initialization

I'm not entirely sure what they mean by "task initialization" in the JPL C Standard doc.
It might be for threads assigned to do a task or a method that does a task?
I think it's more than likely when the program finishes initialization.

This rule can be hard to follow, but it has its reason.
It's a common rule for anything safety critical, and it is a general rule to avoid the HEAP with embedded systems.
You wouldn't want to deal with fragmentation and best fit algorithms in a system that doesn't have a lot of memory.
There is also an aspect of unpredictability in memory allocators that can affect performance.
With all memory strictly on the stack, NASA can statically determine the upper bound on stack usage.

The rule aims to completely avoid all the issues that come with using the HEAP like.

```
use after free
memory leaks
dangling pointers
exhausting HEAP memory
pre-existing data in allocated bounds
buffer overflows in the HEAP
unpredictable behavior of garbage collectors
unpredictable behavior of memory allocators
```

This means avoiding functions like
- malloc()
- calloc()
- realloc()
- free()
- alloca() (https://www.man7.org/linux/man-pages/man3/alloca.3.html)
- sbrk()

also functions that internally use dynamic memory like.
- the printf family
- strdup()
- fopen()

So how exactly would someone imitate dynamic behavior?
There are a couple of ways.
1. Set some maximum bound
2. Object pools
3. Ring buffers
4. Arenas

Now of course NASA's environment is different than most people.
You could make that game without dynamic memory, but your team and boss may not like it.
I can't say to everyone to avoid dynamic memory for all programs.
I can say to keep explicit dynamic allocation to a minimum, but usage of printf or fopen is fine.
This way you have as few mallocs to keep track of, and you have ease of use.
Perhaps a stack array passed to a functon with a specified bound parameter is better.
I don't believe dynamic memory is evil, but it can certainly be mismanaged easily.
If you handle it properly that's good, but each extra allocation is a risk.

### 4. Function Length should be printable on a page with one statement per line

RIP all the Java and C++ users :P.
This rule basically says to keep your functions small and concise for easier auditing.
It incentivises breaking up work into tasks that are concise.
This also means easier unit testing as you have now created concise units.
I believe this rule does not apply to comments.
The JPL Coding Standard and NASA power of 10 both say 60 lines of code.
TigerBeetle uses this rule as well, but they have their limit at 70 lines.
Another part of this rule is a maximum of 6 parameters.
6 could be the magic number since the 7th and beyond are placed on the stack instead of a register.
I think the more simple reason is for ease of use and simplicity.
Personally for me having more than 4 parameters is too much

NASA doesn't say anything about column limits in these documents, but excessively long lines can hurt readability.
80 character column limit seems to be more preferred, even I try to stick by it, but it's my soft limit.
100 characters is my hard limit.

Combined in this rule is having statements and declarations on separate lines.

```
int obtain_value = getValue(), obtain_value2 = getAnotherValue();
char* first = some_string, second = some_string + 1;
```

should be

```
int obtain_value = getValue();
int obtain_value2 = getAnotherValue();
char* first = some_string;
char* second = some_string + 1;
```

one line if statements would be like

```
if( x < 5 )
    flag = 1
```

I didn't include curly brackets as what ever coding style is chosen would determine it.

This rule aims for more clarity.
It avoids statements like `int* x,y,z` where only x is actually a pointer and the rest are ints.
You would need to do `int* x, *y, *z` instead to make them all pointers.

NASA makes a notable exception with for loops since they are technically 3 statements together.
For loops are fine to keep in a single line.
This then raises the question of what about boolean expressions in ifs and whiles?
I think the preference is to maintain one line if possible since it is technically one large boolean statement.
Although, sometimes the expressions can get a little long, so splitting into multiple lines can aid readability.
Just don't make the conditional span like 5 lines.

If you have trouble with trying to condense functions, TigerBeetle suggests to keep your branching, but the contents of the branch can be added into its own method.
Also look for any repetition.
The benefit of adding them to methods also allows to you verify their arguments in a single place and creates another unit to test.

### 5. There shall be minimally an average of 2 assertions per function with assertions containing no side-effects and must be boolean

If for what ever reason you hate all the other rules this rule you can't hate.
Assertions act on your assumptions.
The point is to act on behavior that **should** never happen in real execution.
The question people have is why have a check for something that shouldn't happen?
Well programmers make mistakes which often time only show up later, or bugs are hidden due to how logic is laid out.
Code also changes in development, so assertions can help enforce the new assumptions.
Basically assertions are guards for the programmer to catch their egregious mistakes.
Unit testing can help find errors, but the problem with unit tests is that you would need to write the test.
You probably won't write a test for something that should never happen.
This isn't to say that unit tests are not useful; you should use both assertions and unit testing.
Your unit tests test expected and unexpected behavior, and your assertions will test your assumptions.

So where do you use assertions?
- verify pre-conditions of functions
- verify post-conditions of functions
- verify parameter values
- verify return values
- verify loop invariants

If you notice, these are checking if actions are abiding by its contract

Where do you **NOT** use assertions?
- Validating user input
- Public facing methods
- Handling expected errors (like file open failure)

In these cases you should **VALIDATE** instead.
This is because assertions are removable for performance reasons.
If you want to modify the behavior of the default assertions, or don't want them to be removable you can create your own.
Programs that run infinitely probably don't want to exit the program on assertion failure (especially if your machine is out in space).
Instead you would want to log it.

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

Defining an assertion like this allows NASA to log the error with a specified routine and allows for error return.

### 6. Data objects should be declared in their lowest scope

In C this is the best way to accomplish data hiding.
It also makes debugging easier by reducing the surface area of things to modify.
I would help too if variable names are clear.
If a variable is out of scope then it can't be directly modified.
For the most part, in C it would be declaring the variable at the lowest scope, but there is the static modifier for functions and extern.
You can use the static modifier to declare a function at file scope.
More specifically it's indicating internal linkage.
It's kind of like creating a private method since it'll be usable only in the source file.

```
static void someFunction(){
    . . .
}
```

The opposite of this would be the usage of `extern`.
This specifies external linkage.
extern is like making a global variable that is declared in the header file that later gets defined.
By default functions are extern in header files hence why you define them in the source file.
It's a way to extend the visibility to many source files.
These should only be declared in the header file, and to be included where it is used.

This rule discourages the use of using the same variable for different purposes, and shadowing a variable.
Shadowing a variable can be a problem with extern, so be careful.
This rule works well in combination with rule 3 since once the function is done the stack is cleared of its work.
Within this rule is a preference for "pure" functions.
NASA says these are functions that do not touch global data, avoid storing local state, and do not modify data declared in the calling function indirectly.
This can be further aided with the use of const and enums.
Anything that shouldn't be modified should have a const modifier.

### 7. Check all return values of non-void functions and validate passed in parameters

This is the most forgotten rule and is very helpful to catch bugs.
A lot of bugs slip by simply because the return value was not checked.
In the most extreme cases you would check the results of printf, but NASA says in cases where the return doesn't matter to cast as void.
so this -> `(void)printf("%s", "Hi")`.
This way it is explicity said "I am ignoring this", but also allows for questioning if it should be ignored.
If you are not choosing to ignore the error status, you should check it.
This will help with troubleshooting in some cases as you won't continue with erroneous behavior.

Validating parameters is probably the most important rule to have in any security focused rule.
Public functions are well. . . public, so they could accept any kind of input.
Therefore, it is important to make sure the public function can actually use the parameters it was given.
Private functions should also validate their parameters, but here you can get away with using assert statements.
Essentially this is just validation.
This promotes the principles of creating "total functions" in where functions can handle any input.
Weakly typed languages may have a more difficult time with this, but I think the type should be validated/asserted.
Types are an assumption in weakly typed languages, and you should check your assumptions.

However, you don't always create the functions.
Sometimes you are using a provided function that may not do validation.
In these cases it's applicable to check the parameters before calling the function.
Conceptually I feel it is better to include the validation in your functions since it's more intuitive.
Functions can be thought of as interfaces.
You plug in your values and expect some value.
Depending on what value you get is what you'll do.
Having to remember to check the parameters before calling can often be forgotten, and it isn't expected.

MISRA C 2004 rule 20.3 mentions some ways of conducting validation
- Check the values before calling the function.
- Design checks into the function.
- Produce wrapped versions of functions, that perform the checks then call the original function.
- Demonstrate statically that the input parameters can never take invalid values.

### 8. The preprocessor should be left for simple tasks like includes and simple macros

The preprocessor can make debugging more difficult since it obfuscates the actual value.
Remember the preprocessor is basically just copy and paste, so debuggers will see the value 8 instead of LENGTH_MAX.
In combination with this obfuscation, it is very important that macros are syntactically valid.
There shall be no ';' at the end of a macro definition.
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

\*The do-while one to me is a bit weird, but from what I've researched it seems to try and avoid the faults of the preprocessor.
The do-while is a way to declare variables in more complicated expressions, maintaining a scope, and having to insert a semi-colon at the end.
It's a bit of a hack though.

Below are listed as not compliant

```
/* the following are NOT compliant */
#define int32_t long    /* use typedef instead */
#define STARTIF if(     /* unbalanced () and language redefinition */
#define CAT PI          /* non-parenthesised expression */
```

NASA further says when defining a macro you shall not define them inside a block or function, and the usage of #undef shall not be used.

The preprocessor can do much more than these defines and includes though.
Its operations includes conditional compilation, header guards, token pasting, and recursive macros.
I gotta be honest recursive macros just sounds evil.

Conditional compilation are the statements like `#if, #ifdef, #elif, #else, #ifndef, #endif`.
You have probably used them for header guards.
```
/*construct for a header guard*/
#ifndef <HEADER_FILE>
#define <HEADER_FILE>

/*your declarations here*/

#endif
```

NASA says this is about how far you should go with these conditionals, but sometimes it is unavoidable.
If you must use them beyond the standard header guard, all `#else, #elif, and #endif` must reside in the same file as their `#if or #ifdef`.
Adding too many conditional compilations will exponentially create more test cases.
On the topic of header files, MISRA C 2004 rules 8.1, 8.8, 19.1, 19.2, 19.15, 20.1 explains more details.

Token pasting is probably something most new people to C haven't even heard about.
Their usage is defined by using '#' or "##" inside the #define macro.
That little assert statement in rule 5 is a good example with "#e".
The '#' turns the parameter you passed in into a string literal, and "##" concatenates two tokens.
Both NASA documents says to not use token pasting, but rule 5 with the assert statement has it.
It could be argued it's a simple macro, but I think it's more from MISRA c 2004 rule 19.12.
This rules states that there shall only be one occurrence of the '#' or "##" operators in a macro definition although Rule 19.13 advises against using them entirely.

Oddly enough they include variadic argument lists in here.
I suppose it's a double exclusion since you can do variadic arguments with macros and functions.
Usage of __VA_ARGS__ allows you to make a variadic macro, but under this rule that's not a simple macro.
variadic functions are like printf.
There isn't an explicit reason why variadic functions are banned, but I think it's probably to reduce complexity and allow static analysis.
Personally I've never needed to use a variadic function, and when I did think about using one I simplified my code instead.

### 9. Pointers should at most have two levels of dereferencing

The NASA Power of 10 doc most people see says "no more than one level of dereferencing should be used."
To align more with the JPL C Standard and MISRA I made it "two levels of dereferencing."
This restriction applies to the declaration of a pointer saying there should be no more than two levels of indirection.
Some examples are
```
int8_t * s1;    /* compliant */
int8_t ** s2;   /* compliant */
int8_t *** s3;  /* not compliant */

void someFunction(char* some_parameter){. . .}   /* compliant */
void someFunction(char** some_parameter){. . .}  /* compliant */
void someFunction(char*** some_parameter){. . .} /* not compliant */
```
If you want to see more examples look at MISRA C advisory rule 17.5.

This way 2D arrays or pointer to pointers can be used.
Most of the time you'll only ever need two levels of indirection.
This is a "should" rule, but you'll need a strong reason for that 3D array or array of 2D arrays.

The point of this rule is to improve code clarity.
I've seen people create quadruple pointers and thinking how did they even get there.
Having multiple dereferences, especially with usage of pre/post incremenation, can be confusing.
There are three dereferencing operators.
They are `[], *, ->`.
- \* is the standard dereferencing operator
- -> is for accessing a member from a struct pointer
- [] is dereferencing with a given offset
These operations should not be hidden in a macro or be inside typedef declarations.
These operations should be explicit as they are the culprits for segmentation faults.

Avoid things like
```
typedef int8_t* INTPTR
INTPTR* some_pointer; /*creating an implicit double pointer*/

#define GET_VALUE(x) (*x)
GET_VALUE(*x) /* expands to **x */
```

There is also another aspect of dereferencing which is pointer arithmetic.
MISRA C rules 17.1 - 17.4 explain some rules on what is best.
In summary array indexing shall be the only form of pointer arithmetic, and pointer arithmetic shall only be done within arrays.

This rule also discourages heavily the usage of function pointers unless they are a constant function pointer.
This is mostly for static analyzers and tool checkers.
There isn't a way to know where the function pointer will go since it's run time dependent.

### 10. Compile with all pedantic flags and all warnings

This depends on the compiler.
for gcc there is `-Wextra -Werror -Wpedantic`.
There is also a built in ASAN in gcc by using `-fsanitize=address`.
Note that you should not ship out your code with ASAN enabled it's for debugging memory.

According to the JPL C Coding Standard, NASA uses `gcc –Wall –Wpedantic –std=iso9899:1999` (iso9899:1999 is C99).
I use `gcc -Wall -Werror -Wpedantic` for my code.

There are also other flags for gcc like
```
-Wtraditional
-Wshadow
-Wpointer-arith /*included in -Wpedantic*/
-Wcast-qual
-Wcast-align
-Wstrict-prototypes
-Wmissing-prototypes
```

## Sources

[Nasa's Power of 10](https://web.eecs.umich.edu/~imarkov/10rules.pdf)

[JPL C Coding Standards](https://github.com/stanislaw/awesome-safety-critical/blob/master/Backup/JPL_Coding_Standard_C.pdf)

[MISRA C 2004](https://caxapa.ru/thumbs/468328/misra-c-2004.pdf)

[Tiger Beetle](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)

[Low Level NASA Power of 10 Video](https://www.youtube.com/watch?v=GWYhtksrmhE)
Thank you Low Level for getting me interested in NASA's Power of 10 in the first place
