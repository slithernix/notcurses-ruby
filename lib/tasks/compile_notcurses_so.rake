desc "Compile Notcurses Swig SO"
task :compile do
  require 'rake'

  root_dir = File.expand_path('..', __FILE__)
  while root_dir != '/' && !File.exist?("#{root_dir}/Rakefile")
    root_dir = File.expand_path('..', root_dir)
  end

  notcurses_so_dir = "#{root_dir}/ext/notcurses"
  raise StandardError, "no ext dir" unless Dir.exist? notcurses_so_dir
  og_pwd = Dir.pwd

  begin
    Dir.chdir notcurses_so_dir
    `./extconf.rb`
    raise StandardError, "Failed compiling makefile" if !$?.success?
    `make`
    raise StandardError, "Failed compiling shared object" if !$?.success?
  rescue => e
    raise e
  ensure
    Dir.chdir og_pwd
  end
end

