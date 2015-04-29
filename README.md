# irochan
A [Nim](http://nim-lang.org/) clone of the popular colour picker [Pixie](http://www.nattyware.com/pixie.php).

### FAQ

###### Why?
I wanted to learn Nim, and to see how easy/hard it was to create a WinApi app.  At the time it was written, there were no tutorials from writing Windows GUI Applications.

###### And?  How easy/hard was it?
Super easy if you're already familiar with WinApi programming and C-style languages.

###### How long did it take you?
About two hours a night over maybe 5 days.  Most of the time was spent researching the language, tools, and looking up WinApi functions.  Nim itself is very easy to use and understand, at least the subset of the language that was used to create this app.

###### Why should I use this?
You probably shouldn't :)

###### What does irochan mean?
"Colour child" in Japanese

###### Why isn't X/Y/Z implemented?  Why does X/Y/Z work differently?
I basically only implemented the features I use.  I'll add more features when I have time or the need arises.  I probably will not be supporting conversion CMYK values.

###### Why does the code suck so much?
This was not meant to demonstrate idiomatic Nim or WinApi programming, although I will be updating the code over time as I become more familiar with the language and best practices.  I'm not really happy with it right now but I'd rather have it in github than in some random folder on my drive.

###### How do I build it?
    nim --app:gui -d:release c irochan.nim

###### Where is the irochan.res file?
You will need to create one on your machine using [WindRes](http://www.mingw.org/).  Its usage details are beyond the scope of this readme.
