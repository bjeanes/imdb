require 'rake'
require 'rubygems'
require 'spec/rake/spectask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
 
$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'
 
require 'spec'
require 'imdb'
 
desc "Default: run specs"
task :default => :spec
 
desc "Run all the specs for the Imdb library."
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--colour']
  t.rcov = true
  t.rcov_opts = ["--exclude \"spec/*,gems/*\""]
end
 
desc "Generate documentation for the Imdb library."
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Imdb'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('imdb.rb', 'lib/**/*.rb')
end