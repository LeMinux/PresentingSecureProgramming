# NASA's Power of 10

## Description

NASA's Power of 10 is very powerful set of rules.
It is well known for it's strict rules tailored to creating saftey critical code.
These systems must be developed correctly, or they can result in death or injury of people.
Howevever, the emphasis is on **saftey critical C code**.
Most programmers are not developing saftey critical code, and most languages can't implement every rule.
Additionally, these rules do not explicity go over input sanitization or overflow checks.
Despite this, I feel it is at least important to know what rules you can implement given your circumstance.

Below is my interpretation and my personal take for NASA's rules.
I understand most programmers are not coding rovers or satellites, so not every rule may apply especially considering your language.
I would still suggest to read NASA's documentation as it provides insight into their expectations and reasonings.

## Note For Other Languages

Not every language can follow all 10 of these rules.
Weakly typed and OOP languages make it impossible to avoid the HEAP, and some languages abstract away pointers.
NASA has their reason for avoiding garbage collecting languages.
They can be unpredictable and take up extra over head.
Despite this, most languages should be able to follow all but 3, 9, and 10.
Rule 8 isn't relevant to most languages since the most you can do is import files.
Rules 9 and 10 are a little iffy based on the language.
Weakly typed languages can't follow rule 10 as they don't know the data type.
Imagine launching a rover in Python and it turns out you forgot to test a method containing a type error.
Rule 9 can also be harder to follow since some languages abstract pointers and dereferencing is implicit.

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

### 2. Give all terminating loops a fixed upper bound

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

### 3. Do not use dynamic memory after task initialization

I believe what they mean by "task initialization" are things such as creation of threads.
When creating a thread you can give it a fixed segment of memory for the thread's stack to use.

This rule can be especially hard to follow, but it has its reason.
It's a common rule for anything saftey critical, and is a general rule to avoid the HEAP with embedded systems.
You really wouldn't want to deal with fragmentation and best fit algortithms in a system that already doesn't have a lot of memory.
The most efficent use of memory is leaving no gaps which is what the stack does.

The rule aims to completely avoid all the issues the come with using the HEAP like.

```
use after free
memory leaks
dangling pointers
exhausting HEAP memory
pre-existing data in allocated bounds
buffer overflows in the HEAP
undeterministic behavior of garbage collectors
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

So how exactly would someone take dynamic input?
There are a couple of ways.
1. Set some maximum bound
2. Object pools
3. Ring buffers
4. Arenas

Now of course NASA's environment is different than most people.
I would say for your gerneral apps to avoid using explicit dynamic memory when possible, so using printf or fopen is fine.
Try to not fall into the trap where you must take exact sizes of the user's input.
You will want some bound or else some crafty user will take the entire memory of the OS.

### 4. Function Length should be printable on a page with one statement per line

RIP all the Java and C++ users :P.
This rule basically says to keep your functions smaller for easier auditing.
I believe this rule does not apply to comments.
The JPL Coding Standard and NASA power of 10 both say 60 lines of code.
Tiger Bettle also uses this rule and they have their limit at 70 lines.
I personally think 80 is the absolute maximum because if the function goes past 80 lines there needs to be reconsideration on logic.

NASA doesn't say anything about column limits though, but excessively long lines can hurt readability.
80 character column limit seems to be more prefered, even I try to stick by it, but It's not the end of the world if it goes past 80 characters.
100 characters is the maximum I would try, but I don't think anything should go to 120 characters.

Combined in this rule is having one line per statement.
This includes variable statements.

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

This is for more clarity.
It avoids statements like `int* x,y,z` where only x is actually a pointer and the rest are ints.
You would need to do `int* x, *y, *z` instead to make them all pointers.

NASA makes a notable exception for for loops since they are technically 3 statements together.
For loops are fine to keep in a single line.
This then raises the question of what about boolean expressions in ifs and whiles?
I think the preferance is to maintain one line if possible since it is technically one large
boolean statement. Although, sometimes the expressions can get a little long, so splitting into multiple lines can aid readability.
Honest to god if the conditional statement in an if statment is spread over 5 lines please
reconsider your logic. Same for if a function accepts too many parameters. NASA places a maximum of 6.
I believe the max is 6 since the 7th and beyond are placed on the stack instead of a register.

If you have troubles with trying to condense functions, TigerBettle suggests to keep your branching,
but the contents of the branch can be added into its own method. Also look for any repitition.
The benefit of adding them to methods also allows to you verify their arguments in a single place.

### 5. Assertion density should average 2 with assertions having no side effects and always boolean

If for what ever reason you hate all the other rules this rule you can't hate.
Assertions act on your assumptions.
The point is to act on behavior that **should** never happen in real execution.
The question people have is why have a check for something that shouldn't happen?
Well programmers make mistakes which often time only show up later, or bugs are hidden due to how logic is laid out.
Unit testing can help find errors, but the problem with unit tests is that you would need to write the test.
Especially when it comes to the nitty gritty testing, you may not test that behavior.
This isn't to say that unit tests are not useful; you should use both assertions and unit testing.
Your unit tests test expected and unexpected behavior, and your assertions will catch what should never happen.

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

### 6. Variables should be declared in their lowest scope

In C this is the best way to accomplish data hiding.
It also makes debugging easier by reducing the surface area of things to modify.
This rule discourages the use of using the same variable for different purposes too.
This rule works well in combination with rule 3 since once the function is done the stack is cleared of its work.
Within this rule is a prefereance for "pure" functions.
These are functions that don't modify global state, don't indirectly modify caller data, and don't store a local state.
This can be further aided with the use of const and enums.
Anything that shouldn't be modified should have const.
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
#define PI 3.14159F /* Constant */
#define XSTAL 10000000 /* Constant */
#define CLOCK (XSTAL/16) /* Constant expression */
#define PLUS2(X) ((X) + 2) /* Macro expanding to expression */
#define STOR extern /* storage class specifier */
#define INIT(value){ (value), 0, 0} /* braced initialiser */
#define CAT (PI) /* parenthesised expression */
T#define FILE_A "filename.h" /* string literal */
#define READ_TIME_32() \
    do { \
        DISABLE_INTERRUPTS (); \
        time_now = (uint32_t)TIMER_HI << 16; \
        time_now = time_now | (uint32_t)TIMER_LO; \
        ENABLE_INTERRUPTS (); \
    } while (0) /* example of do-while-zero */
```

\*The do-while one to me is a bit weird, but from what I've researched it seems to try and avoid the faults of the preprocessor.
The do-while is a way to declare variables in more complicated expressions, but this seems like a hack.

Below are listed as not compliant

```
/* the following are NOT compliant */
#define int32_t long /* use typedef instead */
#define STARTIF if( /* unbalanced () and language redefinition */
#define CAT PI /* non-parenthesised expression */
```

NASA further says when defining a macro you shall not define them inside a block or function, and the usage of #undef shall not be used.

The preprocessor can do much more than these defines and includes though.
Its operations includes conditional compilation, header guards, token pasting, and recursion.
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
This rules states that there shall only be on occurance of the '#' or "##" operators in a macro definition.
Rule 19.13 advises against using them entirely though.

This rule also advises against variatic arguments (like with printf), token pasting, and recursive macros.


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

[Tiger Bettle](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)

[MISRA C 2004](https://caxapa.ru/thumbs/468328/misra-c-2004.pdf)
