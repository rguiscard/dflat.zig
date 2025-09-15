# D-Flat.zig: Text User Interface for UNIX in Zig

This is a version of D-Flat for Unix ported in Zig language. Please see original README below.

## Know bugs:

- Text field in search box does not work properly when modifying search text after first one. This is a bug from original dflat.
- Pasting into empty document will crash. (seems fixed).
- The first item in menubar is not disabled when it should be, e.g. Undo in Edit and Search in Search.
- Keep open 'Display' dialog and close it by "ok" several time will result in black in menubar.
- Position of help box from dialogbox seems off.
- 'Window' at menubar crash if there is no open document.

--------

# D-Flat: Text User Interface for UNIX, ELKS and Cosmopolitan

The original D-Flat project was published in the mid-1990's in Dr. Dobbs Journal
and written by Al Stevens. This is a port of that project to UNIX
and ELKS for modern day ANSI terminal programs.

The goal of this project is to produce a small TUI (Text User Interface)
that can run identically on UNIX ANSI terminals, as well as the ELKS 16-bit
Linux operating system.  All input and output uses ANSI v3.64 standard
sequences and should be quite portable. No extra libraries (e.g. ncurses)
are used, and a small set of included routines does all the arrow
key and mouse wheel input parsing.

Since the project originated in 1995, the line draw graphics characters
are all from the IBM PC US character ROM, known as code page CP437. These
characters are translated to unicode and output for display on
modern terminal emulators. Currently, D-Flat doesn't work with input unicode that maps
to larger than 8 bits, but that is being worked on.

## How do I compile/run it?

For UNIX, type `make`.

For Cosmopolitan, edit `make-cosmo` to select the appropriate make command and Cosmopolitan repo path, then edit COSMO= and CC= in `cosmocc`, and type `make-cosmo`.

For ELKS, type `make -f Makefile.elks`.

The resulting output executable is `memopad` (or `memopad.com` for Cosmopolitan).

## What keys are used to operate the program?

When the program is started, it instructs the terminal to send mouse
sequences, which should be easy to operate D-Flat. The standard ANSI, xterm and
VT series arrow and keypad keys are also automatically recognized.

To simulate an ALT-key, type ESC-a for Alt-A, etc. In general, typing
Alt- with the first letter of the menu item will select that item.

## What's next?

This is a work in progress. Better input unicode support and support for the ELKS console
is coming. There are also some MSDOS vestiges being translated to the UNIX environment.

## Screenshots

D-Flat's `memopad` running on macOS
![ss1](https://github.com/ghaerr/dflat/blob/master/Screenshots/D-Flat_Text_User_Interface_on_UNIX.png)
