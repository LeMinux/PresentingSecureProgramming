# Presenting Secure Programming

## Description

This is my little secure programming encyclopedia with what ever I have done when you read this.
Basically a little repo to help explain why some practices exist, why some behaviors are bad, and how things work.
I understand that security is pretty difficult to implement correctly.
There are so many tiny things you have to get right, and only one mistake to ruin it all.
For the most part it focuses more on C as I feel people are not taught it properly, but I'll have some stuff not strictly for C like SQL injections.
Universities may not teach some of these vulnerabilities.
To be honest, you're simply coding for the auto-grader.
However, knowing about these vulnerabilities and how systems work helps you be a better programmer in the long run.

## What Makes Something Vulnerable

The biggest revelation you can as a programmer is understanding that your code lives in a system.
I mean of course code lives in the system we have context switches, file systems, and networks, but have you thought about what that means?
The fact a process lives in the system is what leads to vulnerabilities and exploits because if the process was just itself what point would there be to exploit it.
By definition of a vulnerability it is a weakness that makes the system susceptible to attack or damage for an exploit to use.
Not every vulnerability necessarily leads to an exploit, but why introduce the risk of exploits in the first place.
There are a lot of factors that can make a system vulnerable, but there is one key element that makes use of flaws.
And that is another entity.
I say entity because it's not just malicious humans that are a concern but also malicious AI.
Regardless on what does the acting, something has to do the exploit.
This is why you have to keep the idea of the system in the back of your head.
Exploits can exist in anything such as hosts of a Call of Duty server becoming vulnerable to RCE (Remote Code Execution) attacks [Low Level Learning CoD Exploit](https://www.youtube.com/watch?v=ERlHfeVmq6g).

## Little Note

I am just one human making this, so I'll make mistakes.
I also don't have knowledge of everything.
If you find any mistakes or inadequate explanations let me know, and I'll try to fix them.
