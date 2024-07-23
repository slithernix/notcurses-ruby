# Notcurses-ruby

# WARNING

BEFORE YOU GO ANY FURTHER, this is a WIP!!! This is not to be used for
ANYTHING IMPORTANT WHATSOEVER!!! This is my first time using SWIG and my first
time developing a Ruby extension. It's got very basic functionality working,
but only works on Linux right now. YOU HAVE BEEN WARNED!!!

# Overview

This is a SWIG-generated Ruby extension for Notcurses, a truly 31337 library
for developing TUIs. Notcurses is a modern reimagining of the classic Curses
library known to many. It supports true color, has built-in widgets and many
other nice-to-haves that aren't present in curses, and probably never will be.
Note that while Notcurses will be familiar to anyone who has worked with
curses, it is not a drop-in replacement. The API is definitely different.

https://github.com/dankamongmen/notcurses

## Installation

You should install swig first via your OS package management system. If swig
can't be found, the default generated code will be used which was generated on
a modern Linux system (Ubuntu 22 LTS).

Otherwise it's just your typical gem install notcurses.

## Usage

This is JUST the extension- which puts all the functions and constants under
the Notcurses namespace. I will be developing a more idiomatic object model to
interface with this in a separate project, which gives you the freedom to
choose the raw extension or the full on object-oriented style.

## Developing

Everything is pretty much in ext. The swig interface (notcurses.i) is the main
thing, with a couple of overridden/wrapper functions for things that take
va_list args cause swig doesn't yet have a built-in facility to translating
from ruby's variadics to va_list. The notcurses_wrap.c is what SWIG auto-
generates. It's committed to the repo just as a fallback if SWIG isn't in-
stalled on the local machine but that isn't really a great idea anyways.

If you are new to curses stuff, you will need to be reminded that you will
need to use pry-remote to debug since the terminal will be controlled by
notcurses.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/slithernix/notcurses.
