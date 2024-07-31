# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require 'rake/extensiontask'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end

require "rubocop/rake_task"

RuboCop::RakeTask.new

Dir.glob('lib/tasks/**/*.rake').each { |r| import r }

task default: %i[test rubocop]

Rake::ExtensionTask.new('notcurses') do |ext|
  ext.ext_dir = 'ext/notcurses'
  ext.lib_dir = 'lib/notcurses'
  ext.lib_dir = 'lib/notcurses'
  ext.name = 'notcurses'
  ext.source_pattern = "*.{c,cpp}"
  ext.tmp_dir = 'tmp'
end
