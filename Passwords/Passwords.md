# Passwords

Wait I thought this was secure programming why are passwords on here?

Best passwords are they ones you don't remember.
EVERYONE should use a password manager.
I'm tired of people just not using one because they feel too good for it.
Humans can't remember 100s of passwords.
Even then, if you want to make them memorable this would require making shorter slighlt variations in a password.
Or you could commit the greatest security sin and reuse the same password for everything WHICH YOU **SHOULD NOT DO**!

## Brute Force

Don't trust those basic password strength indicators.
They really just go off length or arbritary complexity.
You enter a 11 length password like "1l!k3ch33sE" and it says it's good, but in reality this is an incredibly weak password.
The true measure of password strength is how many bits of entropy a password contains.
This password only has about 20 bits of entropy, but what exactly does this mean.
Bits of entropy is measure of how tough it would be to brute force a password.
It's kind of like a measure of all the potential ranges of characters added together.
numbers go from 0 - 9, so their range is 10.
The English alphabet has 26 characters lower and uppercase so a range of 26.
Special characters on a typical keyboard `!@#$%^&*()-_=+\`~\\|[]{}"';:/?.>,<` has a range of 32.
If you include a space in that list then it become 33.
It is mathmatical formula of 
```
E = L * log_2(R)

E = Bits of entroyp
L = Length of password
R = Total character range
```
However there is a catch.
This only applies to brute forcing, so more sophisticated attacks that can detect dictionary words can make your password weaker.
Making passwords like "correct battery horse staple" does have a character range 58 (26 for lowercase alpha + 33 for special charactesr including the space) with a length of 28.
Using this in the formula `28 * log_2(58) = `



You can take the number and put it to the power of 2 (2^(bits of entropy)) and it'll give you how many guesses it would take to reach half way to an answer.

To get this number higher you need to add more bits; thus making your passwords longer generally increases bits of entropy.
Of course you need a mixture of complexity in there as well.

## Dictionary Attacks

## OSINT
