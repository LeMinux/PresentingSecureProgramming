# NASA's Power of 10

## Description

NASA's Power of 10 is very powerful set of rules.
It is well known for it's strict rules tailored to creating saftey critical code.
These systems must be developed correctly, or they can result in death or injury of people.
Howevever, the emphasis is on **saftey critical C code**.
This means a lot of NASA's reasoning is related to the woes of C and how to make C more safer.
Most programmers are not developing saftey critical code, and some languages can't implement every rule.
Despite this, I feel it is at least important to know what rules you can implement given your circumstance.

Below is my interpretation for NASA's rules.
Keep in mind as you read that these rules are for **saftey critical C Code**.
NASA has their rules for a reason, but you'll more than likely have different rules.
I want to see how applicable these rules are to general coding or other languages.
From the sources I have read they really just regurgitate NASA's rules which is nice but not inciteful.
The NASA power of 10 doc that most people see is a good document, but it doesn't provide the more niche details as the JPL C Standard and MISRA C documents.
I would heavily suggest you read the documents in sources as it provides insight into NASA's expectations and reasonings.

## Note For Other Languages

I understand that this rule set is focused on C.
If you are concerned about security read up about security standards for your language.
For example, the more C focused rules like HEAP usage, preprocessor, and pointers can't apply to all languages.
Weakly typed and OOP languages make it impossible to avoid the HEAP.
Some languages abstract away pointers into objects or arrays.
Some preprocessors amount to just import statements.
There is also the rule about compiling with max pedanticness which favors strongly typed languages.
However, some of NASA's rules relate to readability and defensive coding which any language can implement.
Reading these rules can help change your mindset into at least trying to be more defensive.

## The Rules

### 1. Restrict code to very simple control flow constructs

This rule in combination with 4 and 6 helps create clean code that's easy to audit for humans and tool-based analysis.
A simple control flow can reveal logic errors that otherwise could have remained hidden.
It also incentivises breaking up work into tasks.

To help facilitate a **very** simple control flow, NASA bans the usage of goto, setjmp, longjmp, and recursion.
From what I can see though, they do not say anything about break or continue statements.
I know some of my professors absolutely hated break and continue.
Compared to what NASA bans though, break and continue aren't that bad.
They are restricted to just loops, and are explicit enough in what they do to flow.
Speaking of flow, early exiting from a funtion is a valid option for NASA.
Again it just depends on what's the simpler and most readable in relation to flow.

NASA avoids recursion as they must have certainty in boundedness.
They want to have an acyclic function call graph to prove execution falls within bounds.
What I like to call the "recursion tax" where each method call adds its parameters, return pointer, and frame to the stack can pass the bounds of the stack if the tax becomes too much.
Perhaps your testing shows it is within bounds most of the time, but what happens during unexpected behavior?
In this case all you really know is that it should eventually reach the base case or blow out the stack.
With the absence of recursion, NASA can handle run away code in a simple manner specified in rule 2.
Threading is also a concern.
Each thread has their own stack in the same memory space, so it is possible for a recursive function in a thread to completely clobber another thread.
Of course this would depend on how the threads are implemented.
I do recognize the usage of recursion.
Some problems may just be too complex for iterative implementations like trees or parsing a JSON.
I doubt that NASA is parsing JSONs on Mars though.
Depending on your constraints, I would say to avoid using recursion if you can as any recursive solution can be implemented as an iterative one.

Setjmp and longjmp make sense given the embedded environment and saftey critical requirements.
I haven't used them since I was never in an environment to use them.
From my understanding it's like a super sized out of scope goto which just sounds like the complete opposite of a simple control flow.
Supposedly they are useful for getting out of deep errors or useful for exception handling.
However, because of rules 5 and 7 the exceptions should be caught before they occur.
This isn't to say exception handling is bad, it's just that C has a different way of catching errors.
Langauges that have exception handling it is good to use.
For the most part in normal programming these two methods don't need to be used at all.

Goto is a little weird.
Goto isn't inheriently evil as some think.
I've seen some valid uses for goto like jumping to handle clean up.
Deep nested loops as well, but I think fixing the deep nesting would be better.
When there wasn't structured constructs like for and while it would of course be abused.
There simply wasn't another option for flow.
However, we have structured programming now.
Goto now adays I feel is a signal of breaking control flow or trying to force its usage.
It feels more like you've programmed yourself into a corner and goto is the only way out.

### 2. Give all terminating loops a fixed upper bound

Notice this says "terminating" loops.
Non-terminating loops, like waiting for network requests, should be verified they won't stop.
NASA says there should only be one non-terminating loop per task or thread for receiving and processing.
These are also explicity non-terminating loops not loops that are non-terminating until some condition.

This rule mostly applies to loops that have a variable number of iterations.
An examples would be traversing a linked list, or traversing a string.
NASA says that an analyzer should statically prove a limit.
The max should be related to your assumptions on what would be an unreasonable amount of iterations.
Basically if you reach this number of iterations something has for sure gone wrong.
If you are dealing with file paths what is the maximum length a file path can be?

In general programming though, you might have some while(true) running until some exit condition.
Perhaps a program that only end when a user clicks to exit the program.
In this case you would want to test that only that condition can terminate the loop.
NASA doesn't really have a statement for this scenario.

Async functions should also get similar treatment.
I didn't see anything about asynchronous functions in NASA's documentation, but it is a common practice to set a timeout for asynchronous things.
This way your program won't hang there waiting, and you can return an error.
Regex should also have a timeout depending on the regex.
There are some "evil regex" patterns that can act as a Denial of Service.
This wikipedia article explains about it (Wikipedia ReDoS)[https://en.wikipedia.org/wiki/ReDoS]

### 3. Do not use dynamic memory after task initialization

I believe what they mean by "task initialization" are things such as the creation of threads.
When creating a thread you can give it a fixed segment of memory for the thread's stack to use.

This rule can be especially hard to follow, but it has its reason.
It's a common rule for anything saftey critical, and it is a general rule to avoid the HEAP with embedded systems.
You really wouldn't want to deal with fragmentation and best fit algortithms in a system that already doesn't have a lot of memory.
The most efficent use of memory is leaving no gaps which is what the stack does.
As a result of this, NASA can statically determine the upper bound on stack usage.

The rule aims to completely avoid all the issues the come with using the HEAP like.

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

So how exactly would someone create dynamic behavior?
There are a couple of ways.
1. Set some maximum bound
2. Object pools
3. Ring buffers
4. Arenas

Now of course NASA's environment is different than most people.
I can't say to everyone to avoid dynamic memory for all programs.
I would say for general programming to avoid using explicit dynamic memory when possible, so using printf or fopen is fine.
Perhaps an array you pass to a functon with a specified bound parameter is better.
This way you have as few mallocs to keep track of.
You will want some bound or else some crafty user will take the entire memory of the process.
I don't believe dynamic memory is evil, but it can certainly be mismanaged easily.
Now some cases you may need dynamic memory, so be sure you know how to handle it.

### 4. Function Length should be printable on a page with one statement per line

RIP all the Java and C++ users :P.
This rule basically says to keep your functions small and concise for easier auditing.
I believe this rule does not apply to comments.
The JPL Coding Standard and NASA power of 10 both say 60 lines of code.
Tiger Bettle also uses this rule and they have their limit at 70 lines.

NASA doesn't say anything about column limits in these documents, but excessively long lines can hurt readability.
80 character column limit seems to be more prefered, even I try to stick by it, but It's not the end of the world if code goes past 80 characters.
100 characters is the maximum I would try for less verbose languages.
For more verbose languages I don't think anything should go to 120 characters.

Combined in this rule is having one line per statement and declaration.

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

I didn't include curly brackets as what ever coding style is choosen would determine it.

This rule aims for more clarity.
It avoids statements like `int* x,y,z` where only x is actually a pointer and the rest are ints.
You would need to do `int* x, *y, *z` instead to make them all pointers.

NASA makes a notable exception for for loops since they are technically 3 statements together.
For loops are fine to keep in a single line.
This then raises the question of what about boolean expressions in ifs and whiles?
I think the preferance is to maintain one line if possible since it is technically one large boolean statement.
Although, sometimes the expressions can get a little long, so splitting into multiple lines can aid readability.
Honest to god if the conditional statement in an if is spread over 5 lines please reconsider your logic.
Same for if a function accepts too many parameters.
NASA places a maximum of 6.
I believe the max is 6 since the 7th and beyond are placed on the stack instead of a register.

If you have trouble with trying to condense functions, TigerBettle suggests to keep your branching, but the contents of the branch can be added into its own method.
Also look for any repitition.
The benefit of adding them to methods also allows to you verify their arguments in a single place.

### 5. There shall be minimally an average of 2 assertions per function with assertions containing no side-effects and must be boolean

If for what ever reason you hate all the other rules this rule you can't hate.
Assertions act on your assumptions.
The point is to act on behavior that **should** never happen in real execution.
The question people have is why have a check for something that shouldn't happen?
Well programmers make mistakes which often time only show up later, or bugs are hidden due to how logic is laid out.
Code also changes in development, so assertions can help enforce the new assumptions.
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
If you want to modify the behavior of the default assertions, or don't want them to be removable (TigerBettle) you can create your own.
Programs that run infinitely probably don't want to exit the program on assertion failure (especially if your machine is out in space).
Instead you would want to log it.

NASA defines an assertion like this

```
#define c_assert(e) ((e) ? (true) : \
tst_debugging("%s,%d: assertion '%s' failed\n", \
__FILE__, __LINE__, #e), false)
```

or on one line

`#define c_assert(e) ((e) ? (true) : tst_debugging("%s,%d: assertion '%s' failed\n", __FILE__, __LINE__, #e), false)`

They give an example usage like this

```
if (!c_assert(p >= 0) == true) {
    return ERROR;
}
```

Defining an assertion like this allows NASA to log the error with a specified routine and allows for error return.

### 6. Data objects should be declared in their lowest scope

In C this is the best way to accomplish data hiding.
It also makes debugging easier by reducing the surface area of things to modify.
If a variable is out of scope then it can't be directly modified.
For the most part, in C it would be declaring the variable at the lowest scope, but there is the static modifier for functions and extern.
You can use the static key word to declare a function at file scope.
More specifically it's specifying internal linkage.
It's kind of like creating a private method since it'll be just in the .c file.
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
Within this rule is a prefereance for "pure" functions.
NASA says these are functions that do not touch global data, avoid storing local state, and do not modify data declared in the calling function indirectly.
This can be further aided with the use of const and enums.
Anything that shouldn't be modified should have a const modifier.
I would like to add to this rule to keep variable names clear for easier auditing.

### 7. Check all return values of non-void functions and validate passed in parameters

This is the most forgotten rule and is very helpful to catch bugs.
In the most extreme cases you would be checking the results of printf, but NASA says in cases where the return doesn't matter to cast as void.
so this -> `(void)printf("%s", "Hi")`.
This way it is explicity saying "I am ignoring this", but also allows for questioning if it should be ignored.
If you not choosing to ignore the error status, you should check it.
This will help with troubleshooting in some cases as you won't continue with erronous behavior.
According to MIRSA C 2004 rules though, checking parameters is considered a more robust means of error prevention.

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
In combination with this obfuscation, it is very important that macros are syntatically valid.
There shall be no ';' at the end of a macro definition.
The allowed macros are explained in MISRA C 2004 rule 19.4.
- Constant values
- Constant expressions
- Macros expanding into an expression
- Storage class specifiers
- braced initialiser
- Parenthesised expressions
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
#define INIT(value){ (value), 0, 0} /* braced initialiser */
#define CAT (PI)                    /* parenthesised expression */
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
It's a bit of a hack.

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
This rules states that there shall only be one occurance of the '#' or "##" operators in a macro definition.
Rule 19.13 advises against using them entirely though.

Oddly enough they include variatic argument lists in here.
I suppose it's a double exclusion since you can do variatic arguments with macros and functions.
Usage of __VA_ARGS__ allows you to make a variatic macro, but under this rule that's not a simple macro.
Variatic functions are like printf.
There isn't an explicit reason why variatic functions are banned, but I think it's probably to reduce complexity.
Personally I've never needed to use a variatic function, and when I did think about using one I simplified my code instead.

### 9. Pointers should at most have two levels of dereferencing

The NASA Power of 10 doc most people see says "no more than one level of dereferencing should be used."
To align more with the JPL C Standard and MISRA I made it "two levels of dereferencing."
This restriction applies to the declaration of pointer saying there should be no more than two levels of indirection.
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
- \* is the standard dereferencing operator,
- -> is for accessing a member from a struct pointer, and
- [] is dereferencing with a given offset (hence zero indexing).
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

This rule also discourages heavily the usage of function pointers unless they are a constant function pointer
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

[Tiger Bettle](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)

[MISRA C 2004](https://caxapa.ru/thumbs/468328/misra-c-2004.pdf)

[Low Level NASA Power of 10 Video](https://www.youtube.com/watch?v=GWYhtksrmhE)
Thank you Low Level for getting me interested in NASA's Power of 10 in the first place
