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

Below is my commentary along with NASA's rationale.
Due to the fact that these are short safety critical guidelines it will of course not explain everything.
This is why I wanted insert my own piece of thought to see how some other more specific scenarios would apply.
I will take a stance that will focus more on how these rules can be applied in a general programming sense.
This will of course mean a more relaxed stance on some rules for the sake of being more applicable, but it does not mean the rule can not be implemented.
Taking a wider approach, although less restrictive in nature, does allow a conjuring on how these rules would apply to situations not explained in these guidelines.
NASA has their reasons and I wanted to see how well their reasons would translate into a typical programmer.
Of course their reasoning relates to C so naturally I will show C examples.
Now there is the consideration that these documents are pretty old.
NASA is probably using some other guideline that we don't know about.
It probably takes principles from the Power of 10 and JPL Coding Standard, but I don't know exact details.

I recommend that you read the sources to gain more incite into NASA's reasoning.
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
If anything it would be an advisory rule against their usage unless it is for their niche role.
TBut then again, that's basically just saying use them when they fit.
Preferably your loops would be a simple enough to where they are not needed or only one of these statement would be needed.

#### Recursion
It is true that recursion can create small easily readable functions, but they do have a cost behind the scene.
cNASA avoids recursion as they must have certainty in stack bounds.
Iterative solutions have a bound that can be determined statically, but finding a bound to recursion statically is much more difficult.
NASA want an acyclic function call graph that proves execution falls within bounds.
What I like to call the "recursion tax" where each method call adds its parameters, return pointer, and frame to the stack can pass the bounds of the stack if the tax becomes too much.
Your testing could show it is within bounds, but what happens during unexpected behavior?
In this case all you really know is it will either reach the base case or blow out the stack.
There are ways to make recursion safer such as limiting the number of calls or adding stack overflow checks.
There is even tail recursion optimization which helps in reducing most stack overflows, but there still looms the threat of stack overflows.
For saftey critical systems, recursion is too much of a risk compared to bounded iterative methods.
With the absence of recursion, NASA can handle run away code in a much simpler manner specified in rule 2.
The absence of recursion also keeps thread stacks with in bounds.
Since threads reside within the same memory space it could be possible for an unchecked recursive method to clobber another thread stack.
I do recognize the usage of recursion.
Some problems may just be too complex for iterative implementations like trees or parsing a JSON.
Depending on the language, recursion can be avoided, but it is more of an avoid it if you can for general programming.

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

I added the distinction to specify terminating loops.
The original Power of 10 document says "all loops", but later specifies non-terminating loops are exempt.
NASA says there should only be one non-terminating loop per task or thread for receiving and processing.
Loops like server loops or process schedulers, so an explicit while(true) loop with no exiting.

This is where the wording I felt was a little confusing in the original Power of 10 document.
As mentioned, it says all loops should have a "fixed upper bound", but often times you would take the length of something.
Would you then need to have the length obtained as well as a fixed upper limit in case the length is wrong?
Something like `for(int i = 0; i < (length of string) && i < (max upper bound); i++){. . .}`?
I feel like if that was the intent validation would be better like in rule 7.
Luckily the JPL Coding Standard clarifies the rule by saying it shall be possible for a static analyzer to affirm a bound.
This is to say if you can obtain the exact number of iterations as an integer it is okay.
Some languages prefer a for-each loop style which is fine as long as the length can be known.
NASA gives a more explicit quote here in the JPL Coding document.
> "For standard for-loops the loop bound requirement can be satisfied by making sure that the loop's variables are not referenced or modified inside the body of the loop".

//TEST THESE METHODS JUST IN CASE
//COME BACK TO THESE THE CONST IS MESSING UP STUFF
In this linked list example a limit is added since a pointer is not an exact ending.
```
Node* listSearch(const Node* node, int needle){
    int count = 0;
    while(node != NULL && count++ < MAX_ITERATIONS){
        if(node->value == needle)
            return (Node*)(node);

        node = node->next;
    }
    return NULL;
}
```

String example finding a character.
```
char* charSearch(const char* string, char needle){
    int length = strlen(string)
    for(int i = 0; i <= length; ++i){
        if(string[i] == needle)
            return (char*)(string + i);
    }
    return NULL;
}

```

Although a better implementation would be to provide a bound as a parameter.
```
/* here size includes the NUL byte */
char* charSearch(const char* string, char needle, int size){
    for(int i = 0; i < size - 1; ++i){
        if(string[i] == needle)
            return (char*)(string + i);
    }
    return NULL;
}

```

Now, lets say you want to find the length of the string.
You may not have a terminating NUL byte which is your ending condition.
```
int myStringLength(const char* string){
    int count = 0;
    while(string[count] != '\0'){
        ++count;
        if(count > MAX_STRING_SIZE){
            /*exit or return error*/
        }
    }
    return count;
}
```
You could then use this to verify that you add a NUL byte to your strings.

#### Special Cases
Things are a little tricky with loops that are technically terminating but can be non-terminating or parsing files.
For the non-terminating but actually terminating loop this rule would say to add an explicit upper bound.
In these cases it would depend on if adding a limit makes sense.
A user can put as many wrong inputs as they want, but is it a login page or your app's menu?
If it is a login then it makes sense to add a time out on too many incorrect attempts.
An app menu not so much, but you can make the decision to add an upper bound on attempts.
Maybe the program is reading from a socket that keeps giving bad data.
Perhaps it's okay to block until good data, but if the context is time sensitive you would return an error after x attempts.
Either case it would have to be verified that only the specified condition can terminate the loop.
The same would go for files since you also don't know the exact end.
Even if you were given a gigantic file there is only as much storage on disk.
If a program depends on reading the whole file there wouldn't be a reason to add a bound.
Unless you have special criteria for files it should be fine to read until the end without a max bound.
A case where a limit could be necessary is to verify that a log file is only a certain amount of bytes.
//REWORD A LITTLE
The big consideration here is that normal programming allows for the program to eventually exit.
NASA wants to avoid such conditions which is why they want to ensure their non-terminating loops do not exit.

#### Async
I didn't see anything about asynchronous behavior in NASA's documentation, but it is a common practice to set a timeout for asynchronous things.
This way your program won't hang there waiting, and you can return an error.
Some special cases could fall under here.
These types of actions my not explicity be a loop, but in behavior it's like the non-terminating but terminating loop.

#### Task Timeout
Task timeouts are more applicable to servers to prevent DDos attacks, but can very well be used in other situations.
Regex is one example.
There are some "evil regex" patterns that can act as a Denial of Service.
This Wikipedia article explains about it (Wikipedia ReDoS)[https://en.wikipedia.org/wiki/ReDoS].

### 3. Do not use dynamic memory after initialization

This is a common rule for anything safety critical or in embedded systems.
This rule only permits dynamic memory at the initialization phase of the program.
Basically memory that you allocate all at once and then never free.
Most people take this as a rule to never use dynamic allocation at all which is partly correct.
It is forbidden to use dynamic memory at run time, but at initialization it is used to set a bound.
An example could be parsing a config file that determines how much memory would be needed.
By avAoiding dynamic memory at run time it avoids
```
use after free
memory leaks
fragmentation
dangling pointers
exhausting HEAP memory
buffer overflows in the HEAP
missing real time deadlines due to waiting for memory
unpredictable behavior of garbage collectors
unpredictable behavior of memory allocators
```
Essentially this is avoiding all the issues with the HEAP by just not freeing anything or adding anything new.
This then gives a bound that can be checked.


This means avoiding functions like
- malloc()
- calloc()
- realloc()
- free()
- alloca()*
- sbrk()

\*alloca uses the stack, but still should not be used. The man page explains (alloca() man page)[https://www.man7.org/linux/man-pages/man3/alloca.3.html].

//FIND OUT ABOUT INTERNAL DYNAMIC MEMORY 
This would also mean some functions that return dynamic memory like strdup().
What I'm not entirely sure about are standard library functions that internally use dynamic memory.
The printf family is one example.
Printf uses xmalloc which would abort the program on allocation failure.
I suppose this could be used as a safety check and ensure boundaries are not past?
They do include printf in rule 7, so I assume this is more a ban on explicit usage of dynamic memory.

So how exactly would someone imitate dynamic behavior?
There are a couple of ways.
1. Set maximum bounds for input
2. Object pools
3. Ring buffers
4. Arenas
5. Pre-allocate

Now of course NASA's environment is different than most people.
I can't say to avoid dynamic memory for all general programs.
I can say to keep explicit dynamic allocation to a minimum, but usage of printf or fopen is fine.
This way you have as few mallocs to keep track of, and you have ease of use.
I don't believe dynamic memory is evil, but it can certainly be mismanaged easily.
If you handle it properly that's good, but each extra allocation is a risk.
Just make sure that you read up on how to safely use it.

### 4. Function Length should be printable on a page with one statement per line

RIP all the Java and C++ users :P.
This rule basically says to keep your functions small and concise for easier auditing.
It incentivises breaking up work into tasks.
This may mean easier but perhaps more unit testing.
I believe this rule does not apply to comments.
The JPL Coding Standard and NASA power of 10 both say 60 lines of code.
TigerBeetle uses this rule as well, but they have their limit at 70 lines.
Another part of this rule is a maximum of 6 parameters.
6 could be the magic number since the 7th and beyond are placed on the stack instead of a register.
I think the more simple reason is for ease of use and simplicity.
Personally for me, having more than 4 parameters is too much.
NASA does not say anything about column limits in these documents, but excessively long lines can hurt readability.
80 character column limit seems to be more preferred, even I try to stick by it, but it is my soft limit.
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

Separating each movement of the code into lines provides more clarity.
It avoids statements like `int* x,y,z` where only x is actually a pointer and the rest are ints.
You would need to do `int* x, *y, *z` instead to make them all pointers.
There is a notable exception to for loops since they are technically 3 statements.
For loops should stay on a single line.
This brought me to thinking about boolean expressions in ifs and whiles.
I think the preference is to maintain one line if and whiles since it is technically one large boolean statement.
Although, sometimes the expressions can get a little long, so splitting into multiple lines can aid readability.

If you have trouble with trying to condense functions, TigerBeetle suggests to keep your branching, but the contents of the branch can be added into its own method.
Also look for any repetition to turn into a function.
The benefit of adding them to methods also allows to you to follow rule 7 even more.

### 5. There shall be minimally an average of 2 assertions per function with assertions containing no side-effects and must be boolean

If for what ever reason you hate the other rules, this rule you can't hate.
Assertions are critical to any defensive coding mind set, and they should be used in any coding context.
Assertions act on a programmer's assumptions that should always remain true or false.
You can think of assertions as landmines for bugs during development.
NASA makes a point that unit testing does catch 1 bug every 10 to 100 lines, but combining unit testing with assertions catches much more bugs.
This makes sense as they are meant to capture different aspects of development.
The problem with unit tests is that you would need to write that test.
You probably won't write a test for something you never expected to happen.
However, assertions can't execute your code like a unit test can.
Assertions also can't give exact answer like a unit tests as they more so narrow down what is expected behavior.
A unit test is able to say I expect the answer to be 5 while an assertion can only say the post-condition is greater than zero.
Together they create a powerful testing strategy that is able to catch much more bugs than using either alone.

So where do you use assertions?
- verify pre-conditions of functions
- verify post-conditions of functions
- verify parameter values
- verify return values
- verify loop invariants

If you notice, these are checking if actions are abiding by its contract.

Where do you **NOT** use assertions?
- Validating user input
- Public facing methods verifying parameters
- Handling expected errors (like file open failure)
- Data outside of your control

In these cases you should **VALIDATE** instead like in rule 7.
Do not use assertions on user provided data.
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


How do you write an assertion?
- Evaluates strictly to a boolean expression
- Contains no side effects
- A recovery action is taken on failure

### 6. Data objects should be declared in their lowest scope

In C this is the best way to accomplish data hiding.
It also makes debugging easier by reducing the surface area of things to modify.
Creating clear variable names is also helpful.
If a variable is out of scope then it can't be modified or referenced.
For the most part, in C it would be declaring the variable at the lowest block scope, but there is the static modifier and extern.

#### Static
You can use the static modifier to declare a function at file scope.
More specifically it is indicating internal linkage.
It is kind of like creating a private method since it will be usable only in the source file.

```
static void someFunction(){
    . . .
}
```

static methods should only be defined in the source file and not defined in the header file.
Defining a static method in the header file would then give each included file a separate function definition.
Although I suppose you could try to make your very one Java Interface in C if you really wanted to.

You can also create static varaibles that persist between method calls, but this is avoided in favor of pure functions.
Generally you want to avoid creating static variables in methods as it is a pretty easy way to create side effects.

#### Extern
The opposite of static would be `extern`.
This specifies external linkage.
extern is like making a global object that is declared in the header file that later gets defined in the source file to be passed around.
It is a way to extend the visibility to many source files.
By default functions are extern in header files hence why you define them in the source file.
You can of course define extern variables, but caution should be used with them.
NASA says if two extern variables have the same name, but different types it can create undefined behavior.

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
Within this rule is a preference for "pure" functions.
NASA says these are functions that do not touch global data, avoid storing local state, and do not modify data declared in the calling function indirectly.
This can be further aided with the use of const and enums.

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

[MISRA C 2004](https://caxapa.ru/thumbs/468328/misra-c-2004.pdf)

[Guidelines on Software for Use in Nuclear Power Plant Saftey Systems](https://www.nrc.gov/docs/ML0634/ML063470583.pdf)

[Tiger Beetle](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md)

[Low Level NASA Power of 10 Video](https://www.youtube.com/watch?v=GWYhtksrmhE)
Thank you Low Level for getting me interested in NASA's Power of 10 in the first place
