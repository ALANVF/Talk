# How to run a Talk file

### Option 1:
1: Enter into the command line: `perl6 <path-to-Talk.pl6> <path-to-file.sm>`

2: Watch the magic happen.

### Option 2:
#### On Windows
Create a file called `Talk.bat` in your account folder (`C:\Users\MyName\`), and put the following in it:
```batch
@echo off
perl6 <path-to-Talk.pl6> %1
@echo on
```

#### On Mac and Linux
Idk how bash works. Just make the equivilent of what you do for windows I guess.

#### After that
1: Type `<Talk> <path-to-file.sm>` into the command line.

2: Watch the magic happen.

# Other stuff
`<Talk> <path-to-file.sm> [-d | --debug]` prints out the transpiled code.
