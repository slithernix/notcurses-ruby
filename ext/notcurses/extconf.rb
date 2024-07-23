#!/usr/bin/env ruby

require 'mkmf'

#dir_config('notcurses')

$srcs = Dir.glob('*.c')

# Specify additional include directories
notcurses_include_path = '/usr/include/notcurses'

defines = %w[
  __x86_64__
  __linux__
  _ISbit
]

include_paths = [
  "/usr/include",
  "/usr/include/linux",
  "/usr/include/c++/11",
  "/usr/include/c++/11/tr1",
  "/usr/include/x86_64-linux-gnu",
  "/usr/include/x86_64-linux-gnu/c++/11",
  notcurses_include_path,
]

append_cflags("-I#{notcurses_include_path}")
swig_cmd = "swig -D#{defines.join(' -D')} -ruby -I#{include_paths.join(' -I')} notcurses.i"
puts "SWIG COMMAND IS #{swig_cmd}"

`#{swig_cmd}`
unless $?.success?
  abort "swig generate command (#{swig_cmd}) failed"
end

# You can add multiple directories if needed
# append_cflags("-I/path/to/another/include")

#include_paths.each do |inc|
#  append_cflags("-I #{inc}")
#end
%w[
  direct.h
  nckeys.h
  ncport.h
  ncseqs.h
  notcurses.h
  version.h
].each do |header|
  unless find_header(header, *include_paths)
    abort "#{header} is missing. Please install notcurses or notcurses dev package."
  end
end

%w[ notcurses notcurses-core ].each do |lib|
  unless have_library(lib)
    abort "notcurses library is missing. Please install notcurses."
  end
end

# Create Makefile
create_makefile('notcurses')
