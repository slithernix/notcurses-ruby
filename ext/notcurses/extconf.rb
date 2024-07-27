#!/usr/bin/env ruby

require 'mkmf'

$srcs = Dir.glob [
  File.dirname(__FILE__),
  '*.c',
].join(File::Separator)

# Specify additional include directories
notcurses_include_path = '/usr/include/notcurses'
defines = Array.new

case RUBY_PLATFORM
when /darwin/ then defines << "__APPLE__"
when /linux/ then defines << "__linux__"
when /mingw|mswin/ then defines << "_WIN32"
else
  abort "unsupported platform #{RUBY_PLATFORM}"
end

case RUBY_PLATFORM
when /x86_64/ then defines << "__x86_64__"
when /i386|i686/ then defines << "__i386__"
when /aarch64|arm64/ then defines << "__ARM64__"
when /arm/ then defines << "__ARM__"
else
  warn "might have issues with this architecture"
end

defines << '_ISbit'

include_paths = [
  "/usr/include",
  "/usr/include/linux",
  "/usr/include/c++/11",
  "/usr/include/c++/11/tr1",
  "/usr/include/x86_64-linux-gnu",
  "/usr/include/x86_64-linux-gnu/c++/11",
  notcurses_include_path,
]

#append_cflags("-I#{notcurses_include_path}")
#append_cflags('-Wno-old-style-definition')

swig_interface_path = [
  File.dirname(__FILE__),
  'notcurses.i'
].join(File::SEPARATOR)

swig_cmd = [
  'swig',
  "-D#{defines.join(' -D')}",
  '-ruby',
  "-I#{include_paths.join(' -I')}",
  swig_interface_path,
].join(' ')

puts "SWIG COMMAND IS #{swig_cmd}"

`#{swig_cmd}`
unless $?.success?
  abort "swig generate command (#{swig_cmd}) failed"
end

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
