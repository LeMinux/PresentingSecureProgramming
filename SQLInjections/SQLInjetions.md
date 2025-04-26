Honestly SQL injections have been explained to death
The basic idea is that data is interpreted as code due to SQL parsing the statement.
Data remains as just data until something gives it meaning.

There are many ways to perform a SQL injection depending on what a malicious person wants.
An attacker could provide a statement like 1; UPDATE users set username = pwned.
This statement would execute the intended statement then after the "1;" it would execute
that update statement and set every user's username to "pwned"

More popular injections would be terminating a string and forcing a true statemetn like " OR 1=1

You could try to spend your entire time escaping user input, but just use prepare/parameterized statements.
Not only are prepared/parameterized statements more efficient, but they eliminate SQL injections due to
these statements passing in the data later after the database has obtained its plan. Since the data
can't be used to alter the intended plan like with concatonating strings, the input is now stuck with
what ever plan the database made.
