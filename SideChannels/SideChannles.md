## Side Channel Attacks

Honestly side channels are really cool.
I mean it is like every side channel attack that is discovered it would be impossible to not call someone crazy to think that was an exploit to begin with.
"Yeah nobody is going to be able to extract data from the frequency of SATA cables" [Air-Gap Exfiltration Attack via Radio Signals From SATA Cables](https://arxiv.org/pdf/2207.07413)
"Nobody can get your password from keyboard sounds" [Acoustic Side Channel Attack on Keyboards Based on Typing Patterns](https://arxiv.org/pdf/2403.08740).
"Nobody can determine what you typed through your typing pattern" [Timing Analysis of Keystrokes and Timing Attacks on SSH](https://people.eecs.berkeley.edu/~daw/papers/ssh-use01.pdf)
"You think someone can use branch prediction to read internal data" [Spectre Attacks: Exploiting Speculative Execution](https://spectreattack.com/spectre.pdf)


Side channel attacks can really be from anything.
Software and hardware is susceptible to these kinds of attacks.
It is any kind of information unintentionally leaked due to any implementation.
Information from
- Sound
- Power consumption
- Timing
- Electromagnetic
- Optical
- Etc

If you are still confused about what this means think about it like this.
When your computer is conducting a heavy work how do you know without looking at Task Manager?
Probably from the noise of fans spinning faster, more felt heat, and/or processes slowing down.
You do not know exactly what is happening in the code, yet these alternative forms of information give a clue on what is happening.
