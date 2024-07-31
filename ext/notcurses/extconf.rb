#!/usr/bin/env ruby

def swig_version
  out = `swig -version | grep '^SWIG Version'`
  out.split&.last&.split('.').take(2).join('.')
end

abort "compatible with SWIG v4.0 ONLY" if swig_version != "4.0"

require 'mkmf'

c_files_dir = 'src'

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
defines << 'SWIG_RUBY_AUTORENAME'

include_paths = [
  "/usr/include",
  "/usr/include/linux",
  "/usr/include/c++/11",
  "/usr/include/c++/11/tr1",
  "/usr/include/x86_64-linux-gnu",
  "/usr/include/x86_64-linux-gnu/c++/11",
  "#{__dir__}/src",
  notcurses_include_path,
]

append_cflags('-Wno-old-style-definition')

swig_interface_path = [
  File.dirname(__FILE__),
  'swig',
  'notcurses.i'
].join(File::SEPARATOR)

swig_cmd = [
  'swig',
  "-D#{defines.join(' -D')}",
  '-ruby',
  "-I#{include_paths.join(' -I')}",
  '-o',
  [ __dir__, c_files_dir, 'notcurses_wrap.c' ].join(File::SEPARATOR),
  swig_interface_path,
].join(' ')

puts "SWIG COMMAND IS #{swig_cmd}"

`#{swig_cmd}`
unless $?.success?
  abort "swig generate command (#{swig_cmd}) failed"
end

$srcs = Dir.glob [
  File.dirname(__FILE__),
  c_files_dir,
  '*.c',
].join(File::Separator)

$objs = $srcs.map { |src| src.gsub(/\.c$/, '.o') }

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
    abort "#{lib} library is missing. Please install lib#{lib}."
  end
end

# Create Makefile
create_makefile('notcurses', c_files_dir)
