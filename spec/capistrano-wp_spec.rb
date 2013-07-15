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

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'crowdfavorite/tasks/wordpress'

describe CrowdFavorite::Tasks::WordPress, "loaded into capistrano" do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.extend(Capistrano::Spec::ConfigurationExtension)
    CrowdFavorite::Tasks::WordPress.load_into(@configuration)
  end

  it "defines cf:wordpress:install" do
    @configuration.find_task('cf:wordpress:install').should_not == nil
  end

  it "defines cf:wordpress:install:with_remote_cache" do
    @configuration.find_task('cf:wordpress:install:with_remote_cache').should_not == nil
  end

  it "defines cf:wordpress:install:with_copy" do
    @configuration.find_task('cf:wordpress:install:with_copy').should_not == nil
  end

  it "defines cf:wordpress:generate_config" do
    @configuration.find_task('cf:wordpress:generate_config').should_not == nil
  end

  it "defines cf:wordpress:link_symlinks" do
    @configuration.find_task('cf:wordpress:link_symlinks').should_not == nil
  end

  it "defines cf:wordpress:copy_configs" do
    @configuration.find_task('cf:wordpress:copy_configs').should_not == nil
  end

  it "defines cf:wordpress:touch_release" do
    @configuration.find_task('cf:wordpress:touch_release').should_not == nil
  end

  it "does cf:wordpress:touch_release before deploy:cleanup" do
    @configuration.should callback('cf:wordpress:touch_release').after('deploy:finalize_update')
  end

  it "does cf:wordpress:generate_config before deploy:finalize_update" do
    @configuration.should callback('cf:wordpress:generate_config').before('deploy:finalize_update')
  end

  it "does cf:wordpress:link_symlinks after cf:wordpress:generate_config" do
    @configuration.should callback('cf:wordpress:link_symlinks').after('cf:wordpress:generate_config')
  end

  it "does cf:wordpress:copy_configs after cf:wordpress:link_symlinks" do
    @configuration.should callback('cf:wordpress:copy_configs').after('cf:wordpress:link_symlinks')
  end

  it "does cf:wordpress:install after cf:wordpress:copy_configs" do
    @configuration.should callback('cf:wordpress:install').after('cf:wordpress:copy_configs')
  end
end
