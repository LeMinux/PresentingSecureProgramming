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
The fact a process lives in the system is what makes vulnerabilities and exploits possible because if the process was just itself what point would there be to exploit it.
By definition of a vulnerability, it is a weakness that makes the **system** susceptible to attack or damage for an exploit to use.
The system could be an operating system, a database, a network, or even a CAN bus in a car.
Any underlying system or communication between systems that an exploit can use to conduct its deed to obtain a desired result.
Of course, the existence of a system does not make something instantly vulnerable, nor does a vulnerability in code instantly mean an exploit.
There are a lot of factors that can make a system vulnerable such as misconfigurations, poorly written code within, or humans clicking phishing links.
Some common patterns are known to create vulnerabilities, but some exploits are so creative nobody would have thought it was possible.
It is not easy to say how vulnerable a system is because you may have not known they even existed.
If we look at Stuxnet, it abused many vulnerabilities in multiple systems, but the system was air gapped which prevented remote execution of an exploit.
In order to conduct the numerous exploits they had to use a human as a vulnerability to plug in an infected USB into the enrichment facility.
Once plugged in, the malware had to then spoof feedback to not arouse suspicious and destroy the centrifuges.
This is a basic explanation of Stuxnet, and doesn't do it justice.
To this day it is probably still the most advanced piece of malware created requiring multiple zero-day vulnerabilities in multiple systems.
To give another example, hosts of older Call of Duty server are vulnerable to RCE (Remote Code Execution) attacks [Low Level Learning CoD Exploit](https://www.youtube.com/watch?v=ERlHfeVmq6g) because a guy reverse engineered the network stack originating from Quake.
These two examples bring in another crucial point of some other entity having a desire to conduct exploits.
I say entity because it's not just malicious humans but also malicious AI or scripts.
Regardless on what does the acting, something has to find and do the exploit.
So what really makes something vulnerable is bad code in a system, and someone else with intent to use that bad code against you.
However, if more secure code was implemented from the beginning it would make systems much less vulnerable.

## Little Note

I am just one human making this, so I'll make mistakes.
I also don't have knowledge of everything.
If you find any mistakes or inadequate explanations let me know, and I'll try to fix them.
