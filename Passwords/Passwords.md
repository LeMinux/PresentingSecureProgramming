# Passwords

Wait I thought this was secure programming why are passwords on here?
Well this chapter extends beyond just making passwords.
You need to know how to store your passwords as well as keys that you treat like passwords.
Password security goes beyond complexity.

## Storing Password

There are two aspects to storing your password.
One is for yourself to remember, and one is for the server to remember.
I'll go over the server side first.
When you submit a password you're actually not sending your password.
I mean you are, but it's not what you typed.
It is instead a transformation of what your password is because sending your password over as plain text is insecure.
You may say HTTPS exists, but that keeps the password safe during the transmission of data.
Sure you are protected from sniffing attacks, but if a data breach occurs and your password is in plain text that's an easy grab.
Thus, the server has to store your password securely so that when a data breach occurs your password is not immediately compromised.
It also has to be sent securely to avoid putting a password in plain text via logging.
This is done via hashing your password.

### Hashing

A hash is a function that turns unique input into unique output where you can't use the output to determine the input.
A common algorithm is sha256 which I'll use for some examples.

```
/* comment start */
as a side note if you want to use !! in a string make sure to use single quotes!
A string like "wow!!" will create a string of wow + <your last ran shell command>.
If your shell was like
$ ls
<result of ls>
$ echo -n "wow!!" > file.txt

$
/* comment end */

file.txt will contain wowls since ls was the last ran command.

example_text_1.txt
sha256("I AM GOING TO THE STORE TO BUY CHEESE!!") -> 29434a6859e36e143950810e3e15ae294dd65b0b9fe274595486951a80780b42

example_text_2.txt
sha256("DEAR GOD THERE IS NO CHEESE") -> 1897c6f5d790eca919e9d0620beb139059330949617a5397b3aa72938275b54a

example_text_3.txt
sha256("I AM GOING tO THE STORE TO BUY CHEESE!!") -> ce45dd87e22cf79c399cb91288e1655b69b9803ceaf4f4fe68b2d957f1669666

example 1
```

In example 1 there are three strings and their resulting hashes.
You can see that each one is completely different even including the last string which is one character off the first string.
This is called the avalanche effect where one change creates larger changes which is used by encryption as well.
This is great because it means someone can't change text by a character attempting to guess around your original text.
It's also great to determine if files have changed in any amount which is useful for back up software or version control.
This way you can only add what files have changed.
However, it's important to use modern hash functions that are cryptographically secure to ensure you have unique hashes.
This is because hashing always has the risk of collisions where two unique inputs give the same output hash.
MD5 has been deprecated because of this.
It is possible under MD5 to calculate a collision, so that different content is claimed to be the original.
If you used a file as a key, with MD5 it would be possible for an attacker to create a different file resulting in the same MD5 hash to gain access.
The problem is we actually can't 100% guarantee that an algorithm is collision resistant.
We can only say it is incredibly rare for it to occur thus making it cryptographically secure.
From the sounds of things you may think hashing and encryption are similar enough to be used interchangeable.
This is in fact not true.
Hashes are one-way, and in effect treat the data itself as the key.
The only way to "crack" a hash is to guess the original text and see if it matches the expected hash.
Encryption is a two-way function creating a larger attack vector, and introduces a logistical challenge in storing a viable key securely.
Encryption is also slower than hashing which can create usability issues.
Because of these problems, you should always hash rather than encrypt.

### Salting

Even with a collision resistant hash you have to factor in typical human behavior.
Humans love to reuse passwords, or create easy, short passwords.
Passwords such as `Password123`, `qwerty`, `abdc1234`, `1111`, `admin`, etc.
Taking into account that hashes of the same input result in the same output you can see how this creates a problem.
Hashes can't be reversed, but it's not that difficult to compute a table of hashes corresponding to their input text.
This is known as a rainbow table attack.
These tables can be terabytes in size, but they hinge on the fact that hashes are one-to-one (in theory).
If we remember the avalanche effect, all it takes is one small change in the input to completely change the output.
This is what salting does.
When hashing the password, some additional data is added along with the password.
This makes a hash \[salt + data\] rather than just \[data\] providing that different input we need to hide identical passwords.
Additionally, if hashed passwords are leaked an attacker can't figure out who uses identical passwords across different services.
However, remember that hashes mask what the input was, so the server has to store the salt with the user.
It is not insecure to do this, as the password is not known, but a data breach reveals this salt allowing for that salt to be used in brute forcing commonly used passwords.
At this point this would be a dictionary attack instead of rainbow table since we are computing hashes on the fly.
All a salt does is simply makes it impossible for someone to precompute a rainbow table since they don't know the salt until they get to that user's database entry.
This means someone trying to crack passwords would have to make a rainbow table per each user entry.
If someone had a dictionary of 14 million words trying to attack 3 million unique salts (users) that would be 42 trillion guesses.
A salt does not necessarialy provide additional password security, but it can certainly make it more difficult to find the correct hash.
Typically, the salt is prepended or appended the password which is easy for an attack to just generate two hashes with those different salt locations.
However, you can place the salt however you want into the password as long as your service knowns what to do.
The challenge would then be to hide your hash implementation.
You may not need to do this though as the only requirement for a salt is to be unique as to not accidentially create identical hashes, and long enough so that someone can't precompute all possible passwords will all possible salts.
It goes without saying that **you should NOT use the same salt** across different passwords.
I mean that's literally defeating the purpose of salting, yet I have heard people do this.
Nowadays, modern password hashing algorithms force you to include a salt, or it automatically adds a salt.
If we take a look at bcrypt it creates a salt by itself and embeds the salt within the hash in the format of
```
$2[a|b|x|y]$[work factor]$[22 character salt][31 character hash]
```

### Peppering

Peppering is an additional layer of security that can be added on top of salting.
While salting provides security to individual passwords, peppering provides security to the entire database.
As mentioned in the salting section, if a data breach occurs the salted passwords can still be brute forced because the salt is known.
A pepper makes it so that even if the database were to leak no hash can be cracked because additional information is hidden.
A pepper works by hashing every password with the same pepper, and keeping the pepper a locked down secret.
However, because every password is using the same pepper you want to combine peppering with salting to avoid identical hashes.
Salts provided protection against rainbow tables, so the next step is protecting against dictionary attacks.
As long as the hacker can't get the pepper they are unable to make any kind of guess by only holding the database.
In effect a pepper can be a salt.
This is what pre-hashing a pepper is effectively doing by adding the pepper with the password before hashing like a salt.
However, since the pepper is kept a secret you can treat it as a key in a form of authentication.
This is what post-hashing does by hashing the salt + password first then conducting an HMAC on the hash with the pepper as the key.
Just like with salting, some modern password hashing algorithms provide an option to include a pepper.
The main distinguishing factor for a pepper is that it's a secret, so you could theoretically use a secret pepper per user if you wanted to.
The obvious challenge is having to keep the pepper a secret whether it's shared or not.
The pepper must be stored correctly, and without having the application or services leak it through an API, memory, files, or logs.
You should not hard code the pepper into the source code as your source code can leak.
The pepper should also not be stored in some random file because your file system can be infiltrated or files can leak through directory traversal attacks.
It's best to store it in a place designed to keep secrets.
If a shared pepper is compromised, then every password must be reset since they are tied to the pepper.
This would mean telling every single user to reset their password next time they login.
Some people may not like a pepper because of the extra challenges, and if it leaks you have gained no advantage.
However, the pepper forces an adversary to gain access to where it is stored just to they can start a dictionary attack.
A simple SQL injection will not suffice to obtaining passwords when a pepper is used.
It's an extra layer of security with its entire basis being the fact it is a secret so that you keep your advantage.

### Choosing How to Hash

You should choose a hashing algorithm that was designed for hashing passwords.
These are algorithms that are
- Purposely slower
- Has a tunable work factor
- Does not need to hide the fact it is used
- Resistant to GPU brute force
- Accepts all unicode codepoints

We'll start from the top and work our way down.
I know it sounds weird to purposely use something slower as normally we always want the fastest thing.
The problem with being very quick is that it means very fast feedback.
This is great if you are hashing many large files, but passwords aren't the length of files.
Most people create very short passwords probably around 8 - 12 characters abiding by the minimum password requirements.
With such short lengths, a fast hashing algorithm, like SHA256, means much faster brute forcing.
By using a slightly slower algorithm, brute forcing can be mitigated by a good margin.
The speed can be further configured with a work factor that is stored within the hash itself.
The work factor controls how many iterations of work the algorithm will do.
The advantage to having a configurable work factor rather than having a generally slower algorithm is that it can be adjusted to evolving technology.
As technology gets faster the ability to brute force is faster, so the work factor has to increase overtime to maintain a sufficient slowness.
Sufficient slowness being around less than a second as any slower users start to complain, and you risk a denial of service attack.
Since the work factor is built into the hash, you have rehash with the new work factor to maintain security.
This can be done sneakily by rehashing on the user's next login, or simply forcing the user to reset the password.
Additionally, the work factor changes the resulting has since it's going through a different amount of iterations.
In this Argon2i example where I'm running the shell command you can see how the parameter for iterations (-t) changes the hash.
```
$ echo "SuperSafePasswrdLmao" | argon2 "g0Ob3r@sPace" -m 12 -t 3 -p 1
Type:           Argon2i
Iterations:     3
Memory:         4096 KiB
Parallelism:    1
Hash:           73c7e04606f321c0c13da582ac86a4b79b716730d05a646141bf48d41051bf0f <------- hash here
Encoded:        $argon2i$v=19$m=4096,t=3,p=1$ZzBPYjNyQHNQYWNl$c8fgRgbzIcDBPaWCrIakt5txZzDQWmRhQb9I1BBRvw8
0.007 seconds
Verification ok

$ echo "SuperSafePasswrdLmao" | argon2 "g0Ob3r@sPace" -m 12 -t 5 -p 1
Type:           Argon2i
Iterations:     5
Memory:         4096 KiB
Parallelism:    1
Hash:           fb6868809b9c2186b3c82ea3299b0e39a337a71dd44ca9d6a0748383410e79d2 <------- hash here
Encoded:        $argon2i$v=19$m=4096,t=5,p=1$ZzBPYjNyQHNQYWNl$+2hogJucIYazyC6jKZsOOaM3px3UTKnWoHSDg0EOedI
0.009 seconds
Verification ok

$ echo "SuperSafePasswrdLmao" | argon2 "g0Ob3r@sPace" -m 12 -t 10 -p 1
Type:           Argon2i
Iterations:     10
Memory:         4096 KiB
Parallelism:    1
Hash:           5fb2e0d98cfde07420c1a39ae1e44eda9b85b6035c28a17b41ef991a5618388a <------- hash here
Encoded:        $argon2i$v=19$m=4096,t=10,p=1$ZzBPYjNyQHNQYWNl$X7Lg2Yz94HQgwaOa4eRO2puFtgNcKKF7Qe+ZGlYYOIo
0.016 seconds
Verification ok
```

Of course, brute forcing will still happen offline, but if we use our 42 trillion example from earlier we can do some math.
If we take a speed of 2.0 MH/s, which is 2 megahashes or 2,000,000 hashes in a second, 42 trillion is completed in 21 million seconds or about 8 months.
Now if we use a speed of 500 H/s 42 trillion is completed in 84 billion seconds or 2,661 years.
It's quite the stark difference, and we can only get up to numbers this high because we are using a slower algorithm with salted hashes.
If your database does get leaked, then you shouldn't depend on security through obscurity for the hashes.
You would most likely be tempted to do this if you have rolled your own crypto **which you should NEVER do**.
Any modern password hashing algorithm using proper parameters with a sufficiently long user password is impractical to crack.
Well done security is knowing what is used, yet still unable to do anything because the implementation is known to be well vetted.
If knowing your hashing algorithm was a problem, then that means the implementation is bad and to use something different.
You can actually see what password hashing algorithms companies have disclosed through this website [https://pulse.michalspacek.cz/passwords/storages](https://pulse.michalspacek.cz/passwords/storages).
Now we can get to the part that really helps up make a decision.

So far it seems like super-slow-hasher-27 is a good option, but there is a way to make hash cracking even slower.
It's easy to think the CPU is going to do everything, but the GPU exists.
CPUs are pretty fast, but GPUs are even faster due to their excellent parallelisation.
This is because GPUs simply have more processesing cores to handle large batches of data.
Tools like Hashcat and John the Ripper use the GPU for hash cracking.
Although, we have already covered slowing down the algorithm with a work factor.
In order to make it so less hashes can be parralelized at once the algorithm needs to purposely take up more space.
These are memory-hard algorithms.
They are algorithms that require large amounts of memory to run which is what argon2 and scrypt do.
GPUs have their own RAM called VRAM which is what the hashes abuse.
Dedicated graphics cards have their own VRAM, have more VRAM, and are much more expensive.
Integrated graphics have less VRAM, are less powerful, and share RAM.
The dedicated GPUs are far more beefy and are much more capable of cracking hashes.
They don't share RAM, so you won't have a 32GB VRAM graphics using your 16GB main RAM.
It might be possible for a dedicated graphics card to share RAM, but I don't know how well that would go.
The only way to upgrade would be to buy another more capable graphics card as you can't just slap some more RAM into it.
Which means these algorithms place a financial burden to those wanting to get more speed.

More than likely you must accept passwords from all over the world which means dealing with UTF-8.
A library for hashing passwords must be able to accept this, so users can type passwords in their language and use all the entropy they want.
Who knows, a user might want to use an emoji because they only ever login through their mobile device.


### What Algorithms to Use

If you are looking for an algorithm to use, you want an algorithm that covers all the critera from the last step.
In case you forgot, these are algorithms that
- Are purposely slower
- Has a tunable work factor
- Does not need to hide the fact it is used
- Resistant to GPU brute force

Luckily you don't have to look far as OWASP plainly stats what they recommend.
According to OWASP the highest suggested one is argon2id, with scrypt next, then bcrypt.
Argon2 won the 2015 password competition, and since then it has been the new standard.
Argon2 has 3 different implementation with argon2id combining the benefits of argon2d's GPU cracking resistance and argon2i's side channel resistance.
Since argon2id is a balance of the other two versions it's generally the better choice.
It has the parameters to configure minimum memory (-m), minimum iterations (-t), and degree of parallelism (-p).
OWASP recommends these configurations
```
https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#argon2id

m=47104 (46 MiB), t=1, p=1 (Do not use with Argon2i)

m=19456 (19 MiB), t=2, p=1 (Do not use with Argon2i)

m=12288 (12 MiB), t=3, p=1

m=9216 (9 MiB), t=4, p=1

m=7168 (7 MiB), t=5, p=1
```

The next recommended is scrypt when argon2 is not available for similar reasons.
It is also memory-hard providing similar parameters of minimum memory cost parameter (N), blocksize (r), and degree of parallelism (p)

```
https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#scrypt

N=2^17 (128 MiB), r=8 (1024 bytes), p=1

N=2^16 (64 MiB), r=8 (1024 bytes), p=2

N=2^15 (32 MiB), r=8 (1024 bytes), p=3

N=2^14 (16 MiB), r=8 (1024 bytes), p=5

N=2^13 (8 MiB), r=8 (1024 bytes), p=10
```

Lastly, OWASP only recommends bcrypt for legacy systems.
This might be surprising as bcrypt has been the standard for a long while, and even still recommended at the time of writing.
In fact, AI will probably recommend bcrypt first then argon2 since there is more data saying to use bcrypt.
The reason OWASP says to strictly use bcrypt when neither argon2 or scrypt is available is because of its limitiations.
Bcrypt can only accept a maximum of 72 bytes, and has issues stopping at null bytes.
The internet uses UTF-8 which has multi-byte characters up to 4 bytes.
Bcrypt would then have a maximum of 18 4 byte characters, but the string must end in a null byte making the length 17 in reality.
You could restrict down to ASCII, but you don't want to limit the entropy of passwords users can make via UTF-8.
You may not care because people don't create 72 byte passwords, but the risk of truncation is a vulnerability.
You add extra stuff to the password like salting or peppering, so someone could add extra characters that removes the password.
This is what happened with Otka with a link here [Otka Nov 1, 2024 Security Advisory](https://trust.okta.com/security-advisories/okta-ad-ldap-delegated-authentication-username/)
They had their hash as userid + username + password, so a username that was long enough could truncate off the password.
Additionally, since bcrypt expects an ending null byte the algorithm won't handle multiple null bytes since it'll stop at the first null byte.
Of course the world exists, so you might have to use it.

### How Passwords are Cracked

A majority of the time passwords are cracked offline on the evil person's hardware.
It is certainly possible to crack online through the server, but there are defenses such as rate limits, soft locks, CAPTCHAs, or IP blocks.
Then there are limits due to the nature of the internet, your ISP, your network hardware, or even the country you reside in.
A person may try to use a bot net and distribute their guesses to avoid having their only machine blocked, but why go through the effort if you can just do it offline.
Offline is your machine under your rules without needing any internet trying to crack hashes.
The only requirement is that the person has a leaked database with them.

#### Simple Brute Force

Brute force is basically guessing every single combination of letters you can think of.
It is far less sophisticated than the other methods, but it is very simple.
You guess a password of `aaaaaaaaa` if it's wrong guess `aaaaaaaab`.
You might start off with more common passwords first then go to brute force.
It works well for very short passwords or pins as the guess surface is smaller.
The easiest way to beat this is to have long passwords with sufficient variation.

#### Dictionary Attacks

A dictionary attack is a more sophisticated brute force attack.
Instead of guessing every single possible variation, a list of some sort is used to guess.
It's possible to have these lists because previous data breaches have revealed common passwords people use.
They are also shared around through open source projects or the web.
Rockyou being a famous example of a dictionary list to use for password cracking.
The dictionary list can really be anything including all the words of the English language.
This is why it's suggested to avoid consisting your password of words.
These attack differ from a rainbow table in that it tests each entry of the list.
The results are not precomputed and therefore needs to go through the hashing process.
There is a higher performance cost, but a far less space cost than a rainbow table.
A dictionary attack is also much more dynamic and adaptable.

#### Rainbow Tables

A rainbow table is precomputed table that contains a pair of the plain text and its associated hash.
This way if a hash is found you look it up on the table to find the plain text.
You can turn a dictionary attack into a rainbow table if you were to take everything in the list and precompute the hashes.
It's a trade off between performance and space as these tables have quick look up, but absolutely massive space requirements.
You can think of it as premptively expecting an entry to be in the table.
These tables can be shared around like with dictionary lists, and with each hash the gets cracked another entry can be added to the table.
It keeps a record of what has been broken, what hashes are insecure, and different variations of passwords with salts.
With salting being the number one standard in hashing though there is no use in rainbow tables anymore.
If you wanted to make a rainbow table anyway, first of all a dictionary attack would basically be the same thing, and second of all it'll only work for that one user.
Dictionary attacks are just more dynamic and don't care about the salt because it'll just add the salt on the fly.

#### OSINT

OSINT information is any information open to the public about you.
Your social media, people search sites, background, and that one random photo of you on the school website 8 years ago is OSINT.
This information pertains to you, so the kind of person who would be conducting this is targeting you.
The hopes are that your password pertains to information you have given out like your birthday, a child's birthday, a pet name, or previous address zipcodes.
They can use this information to make their own kind of dictionary attack creating permutations like `sloppydog1997`, `dingo4428`, or `School2026`.
For a broad range Google dorking could be a way to find unintended public documents.
It's also reasonable to think that someone might look into previous databreaches to see what previous information there is about you which leads to the next sections.

#### Offline Credential Stuffing

Credential stuffing can be an extenstion off of OSINT information.
Instead of just using any open information though, a bad actor uses previous databreach information.
Someone malicious can place your email into a site like [HaveIBeenPwned](https://haveibeenpwned.com/) or [IntelBase.is](https://intelbase.is/) to see if you were in a databreach.
IntelBase is a lot more spooky, and is very scary what information it reveals if you were part of a breach.
If open sources like these don't reveal anything, they could buy leaks.
It's not uncommon to have an abandoned account last used 6 years ago get into a data breach.
You may not use the account anymore, but it still can contain information used against you.
Sam Croley in his *What the Shuck* talk at DEFCON mentions in his presentation that from various databreaches about 70% of people have already been in previous databreaches sourcing his information from @haveibeenpwned.
The reason this is dangerous is because people reuse passwords frequently.
Those same 70% of people now have a decent record of previous passwords they use.
This greatly reduces the need for brute force methods if there is a clear pattern in your passwords.
The best way to mitigate this is to obviously not reuse passwords by having randomly generated passwords, and enable multi-factor authentication.

#### Hash Shucking

Hash shucking is a unique type of vulnerability that abuses double hashed (prehashed) passwords.
You normally don't want to double hash passwords, but it is a recommended temporary fix for legacy systems wanting to use better hashes.
As an example, you might have a system that previously used SHA1 or MD5 hashes.
This is incredibly insecure, but you obviously don't know the password because you just have the hash.
To at least make it more secure you would hash the insecure hash with a better algorithm more resistant to brute force.
This is where some guides or blogs will stop making it seem like the problem has been solved, but this is just a temporary patch.
You want to eventually migrate into hashing with the better algorithm for maximum security.
This is because you still have that fast hashing algorithm to deal with.
What password shucking does it peel off that outer layer algorithm so that cracking the hash effectively becomes the inner algorithm.
I'll use bcrypt as an example, as it seems prehashing is more commonly done with bcrypt, but keep in mind the problem is combining a secure hash with an insecure hash.
Taking a hashing strategy of `bcrypt(MD5( [password] ))`, hash shucking makes this equiavalent to `MD5( [password] )`
Now you actually wouldn't want to bcrypt like this because of the null byte issues of bcrypt, so you would encode the MD5 hash before bcrypt hashing with something like base64.
So it should be `bcrypt(base64(MD5( [password] )))` instead.
Now a normal strategy would be to brute force going from `guess->MD5->bcrypt`, but we can use credential stuffing to instead go `MD5->bcrypt`.
We take the MD5 hash from a previous database, which we have not cracked, and hash it with bcrypt.
Since this is bcrypt, we would have to use the same work factor and salt, but this is known inside the bcrypt hash and database.
Now that we have the resulting hash we check if that hash exists anywhere in the database we want to crack.
If there is a match, then only the MD5 hash needs to be cracked skipping needing to brute force bcrypt.
With MD5, an attacker can guess billions of hashes a second compared to bcrypt few hundred a second.
If the MD5 hash is known it's even better as there is no cracking to be done.
What might seem confusing though is how is this kind of attack is practical.
MD5 is very fast, so the only limiting factor is bcrypt which we still have to hash by.
It's another attack based on the reuse of passwords.
What makes this more dangerous is the fact the system was using previously insecure hashing.
Bcrypt does make the process a slower, but the attacker is using known hashes.
They are being more selective about the input rather than just dictionary attacking bcrypt to speed up the process.
However, the attack does not work if there is not a known hash to use.
Otherwise, the attacker is just brute forcing bcrypt.
In order to mitigate known hashes, a pepper is a viable defense to make the hash different and secret.
This makes the new strategy `bcrypt(Base64(MD5([password]) + pepper))`.
If the passwords were unsalted you would want to salt the hashes which bcrypt does already.
However, bcrypt is legacy, so don't think bcrypt is the only option.

### Storing Password Like Keys

As a programmer or sysadmin you might have some password-like keys.
SSH and API keys are things that you want to keep secret like a password, but aren't hashed like keys.
For Linux systems, SSH keys are stored in the .ssh folder in the user's home directory.
The security here is to simply never share the private key **EVER**, and the only time the keys would be compromised is if your system is compromised.
At which point you have larger things to worry about since you can always rotate ssh keys.
API keys you do not want to store hard coded into the source code.
A fun task you can do is search up on Github open API keys that people have left in their code.
This basically leaves your only option to leave the key outside the code residing on the system, or secret management containers.
How you should store API keys depends on your environment and language, but some options are environment variables, a specified file, or something like AWS secrets manager.
Don't forget that your .gitignore file exists!
The git ignore file a very helpful tool, and you can reverse the ignore scheme by blocking everything and allowing only certain files.
You can negate an ignore by starting the line off with an '!' like so
```
#Ignore everything
*

#negate readme ignore
!README.md

#have to negatate parent directory if wanting to negate child directories
!src/
!src/bin
```

Reversing the rule is useful if you only want to allow specific files in a sea of ignoring everything.
It also reduces the risk of accidentially forgetting to ignore the .env file since by default you ignore everything.


## How can YOU Remember Passwords

You don't!

### Password Managers

**PLEASE!!! PLEASE!!!! USE A PASSWORD MANAGER!!!**

The best passwords are they ones you don't remember.
**EVERYONE** should use a password manager.
I'm tired of people not using one because they feel too good for it.
I don't know why you are lazy to use a tool that was designed for you to be lazy with password!
Humans can't remember 100s of passwords let alone remember a password they used for a throw-away account.
There is no shame in admitting this.
If you do remember 5 passwords I bet you it's just a base password with slight variations.
Passwords like `ILikeCats43`, `1L!k3C@t2000`, `ILoveC@tz#@!`?
Oh, this is your Meta/Facebook password?
Is it `ILikeFaceb00kCats!99`?
You may think you are clever in using the domain name of the site in your password, but guess what!
Other people have thought the same!

#### Offline Managers

KeePassXC

#### Online Managers

BitWarden, LastPass, 

## Multi-Factor Authentication

When you hear about 2FA you probably think about your phone or email as that extra step in logging in.
There are actually much more factors of authentication available than just those two.

- Something you know | Knowledge factors
- Something you have | Posession factors
- Something you are  | Inherence factors
- Something you do   | Behavior  factors
- Somewhere you are  | Location  factors


### Knowledge

Knowledge is what you have memorized.
The kind of knowledge people would torture you for because they can't probe your mind waves.
In terms of authentication these are your passwords, pins, secret phrases, and secret handshakes.
It is almost always the first factor in identifying you and the easiest to verify.

### Making Good Passwords

Don't trust those basic password strength indicators.
They really just go off length or arbritary complexity.
You enter a 11 length password like "1l!k3ch33sE" and it says it's super strong, but in reality this is an incredibly weak password.
The true measure of password strength is how many bits of entropy a password contains.
This password only has about 20 bits of entropy, but what exactly does this mean?
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

Ideally you want at least 120 bits of entropy

You can take the number and put it to the power of 2 (2^(bits of entropy)) and it'll give you how many guesses it would take to reach half way to an answer.

To get this number higher you need to add more bits; thus making your passwords longer generally increases bits of entropy.
Of course you need a mixture of complexity in there as well.

### Posession

#### Yubikeys

#### Emails

#### Phones

### Inherence

### Behavior

### Location

## Sources

[DEF CON Safe Mode: Password Village - Sam Croley: What the Shuck? Layered Hash Shucking](https://www.youtube.com/watch?v=OQD3qDYMyYQ)

[OWASP Secret Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

[OWASP Storing Passwords Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)

[OWASP Credential Stuffing Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Credential_Stuffing_Prevention_Cheat_Sheet.html)

[Nordpass Most Common Passwords](https://nordpass.com/most-common-passwords-list/)

[NordPass Stop Reusing Passwords](https://nordpass.com/blog/stop-reusing-passwords/)
