# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "capistrano-wp"
  gem.homepage = "http://github.com/crowdfavorite/gem-capistrano-wp"
  gem.license = "GPL"
  gem.summary = %Q{Crowd Favorite WordPress Capistrano recipes}
  gem.description = <<-EOF
    Recipes for deploying and maintaining remote WordPress installations with
    Capistrano.  Pulls in WordPress from SVN, optionally using a local or 
    remote cache, and supports a number of common operations and tasks towards
    the care and feeding of sites that may not be 100% maintained through 
    version control.
  EOF
  gem.authors = ["Crowd Favorite"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  ENV["COVERAGE"] = 'yes'
  Rake::Task['spec'].execute
end

task :default => :spec

