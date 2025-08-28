## UTF-8

### History

Before the web really took off each country had their own standard on how computers interpreted their alphabet.
America created the ASCII standard, but countries like Japan had 4 different standards.
Due to the different standards in Japan the word mojibake was used to describe the jumbled up mess created from incompatible encoding.
If you have ever opened up a binary file and read it as a text document it looks something like that.

### How It Works

//eh you know just copy and pasted what I had over for now

99% of the web currently uses the UTF-8 standard to support international languages.
UTF-8 was designed to encompass as many languages as possible while keeping backwards compatibility with the prevalent ASCII standard.
The problem was that ASCII uses only one byte which is not enough space for a standard to encompass every language.
Additionally, programs that read in ASCII only expect to see each character represented in one byte.
This is what lead to UTF-8 having variable length characters.
The ASCII and first 127 code points of UTF-8 are exactly the same, so programs expecting ASCII can still read as normal.
Extended ASCII which uses the signed bit on the single byte would be represented as two bytes in UTF-8 though.
There are standards that enforce a fixed-length size such as UTF-16 and UTF-32.
UTF-16 uses two byte blocks up to 4 bytes while UTF-32 uses 4 bytes.
UTF-8 is used the most though because of it's backwards compatibility with ASCII and space efficiency, but UTF-16 is used here and there.
They function differently though, so don't expect to encode in UTF-16 and obtain correct results decoding in UTF-8.
I'll only be focusing on UTF-8 since it's the most common.
UTF-8 can support up to 5 or 6 byte sequences, which was shown in RFC 2279, but UTF-8 will only use 4 bytes as specified in [RFC 3629](https://www.rfc-editor.org/rfc/rfc3629) which supersedes RFC 2279.
This is because the other UTF standards can't easily use 5 or 6 bytes, and it was determined 4 bytes supplying 1.1 million characters would be enough.
As of Unicode version 16.0.0 a total of 154,998 characters have been defined.
So how does UTF-8 distinguish between its many characters?
This is done by analyzing how many 1s before encountering a zero is found in the first byte.
ASCII characters will always have the 8th bit in the first byte as zero.
A character that is two bytes long would begin with 110 for the first byte.
The following byte would then contain 10 for the first two most significant bits to show it's a continuation.
As an example the UTF-8 binary for U+00A7 is **110**00010 **10**100111 or 0xC2 0xA7 in hex.
Basically however many 1's there are tells how many bytes to expect which includes the current one being read as that also holds some data.
The table below shows the range of each sequence.
The code point format shows just the bits that are used excluding the header bits used.
This means a code point of U+C704 is only considering the `1100 0111 0000 0100` binary despite the sequence looking like `1110 1100 1001 1100 1000 0100`.
The Hex range section shows the minimum and maximum hex value you would see that includes the header bits.
This is useful to know as these header bits make it impossible for certain hex values to appear in UTF-8, and therefore is an indication of invalid UTF-8.

| Code Point Range    | Hex Range               | Bits Used |UTF-8 Binary                                          |
|:------------------: | :---------------------: |:--------: |:---------------------------------------------------: |
| U+0000 - U+007F     | 0x00000000 - 0x0000007F | 7         |0yyyxxxx                                              |
| U+0080 - U+07FF     | 0x0000C280 - 0x0000DFBF | 11        |110zzzyy 10yyxxxx                                     |
| U+0800 - U+FFFF     | 0x00E0A080 - 0x00EFBFBF | 16        |1110wwww 10zzzzyy 10yyxxxx                            |
| U+010000 - U+10FFFF | 0xF0908080 - 0xF48FBFBF | 21        |11110vuu 10uuwwww 10zzzzyy 10yyxxxx                   |

Here you can see UTF-8 splits the bits across the sequence due to the bits used as metadata.
A 2 byte sequence uses 11 bits for the actual code point which is split with 5 bits in the 1st byte and 6 bits in the second byte.
Because of this behavior, the hex range indicates some ways of finding invalid sequences.
The tail end of a UTF-8 sequence, which are the bytes after the control byte, will only have values between 0x80 and 0xBF.
It also shows that the hex values of 0xC0, 0xC1, and 0xF5–0xFF will not appear in valid UTF-8.
The reason this is important to know is because of overlong sequences.
It is possible to use more bytes than necessary to encode a lesser value code point.
The only legal way to create a UTF-8 character is with its shortest valid sequence.
If we take a 1 byte ASCII value 'w' which is 01110111 (0x77 or U+0077) and transform it into a 2 byte UTF-8 we get a sequence of `11000001 10110111 (0xC1 0xB7)`.
Here we see 0xC1 which is not a valid byte to find for a two byte sequence.
Using longer sequences would just add more zeros, so 4 bytes is `11110000 10000000 10000001 10110111 (0xF0 0x80 0x81 0xB7)`.
Here it is detected as an overlong sequence because values less than 0x90 after a 0xF0 are invalid.
If we do a three byte overlong sequence it is `11100000 10000001 10110111 (0xE0 0x81 0xB7)`.
Once again this is invalid since the hex range shows values under 0xA0 after a 0xE0 can't occur.
The code point range is still U+0077 for these cases.
Effectively by extending out it's just showing the zero portion of the name.

### Overlong Sequences

### Normalization

### Sanitization

was something about replacing character with U+

## Sources

[Computerphile Tom Scott UTF-8](https://www.youtube.com/watch?v=MijmeoH9LT4)

[Wikipedia UTF-8](https://en.wikipedia.org/wiki/UTF-8)

[RFC 3629](https://www.rfc-editor.org/rfc/rfc3629)
