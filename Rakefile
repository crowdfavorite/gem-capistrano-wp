# encoding: utf-8
# Copyright 2012-2013 Crowd Favorite, Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
  gem.license = "Apache License version 2"
  gem.summary = %Q{Crowd Favorite WordPress Capistrano recipes}
  gem.description = <<-EOF.gsub(/^ {4}/, '')
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

