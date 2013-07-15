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
require 'crowdfavorite/tasks/localchanges'

describe CrowdFavorite::Tasks::LocalChanges, "loaded into capistrano" do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.extend(Capistrano::Spec::ConfigurationExtension)
    CrowdFavorite::Tasks::LocalChanges.load_into(@configuration)
  end

  it "defines cf:localchanges:snapshot" do
    @configuration.find_task('cf:localchanges:snapshot').should_not == nil
  end
  it "defines cf:localchanges:compare" do
    @configuration.find_task('cf:localchanges:compare').should_not == nil
  end
  it "defines cf:localchanges:allow_differences" do
    @configuration.find_task('cf:localchanges:allow_differences').should_not == nil
  end
  it "defines cf:localchanges:forbid_differences" do
    @configuration.find_task('cf:localchanges:forbid_differences').should_not == nil
  end
  it "sets snapshot_allow_differences to false" do
    @configuration.find_and_execute_task('cf:localchanges:forbid_differences')
    @configuration.fetch(:snapshot_allow_differences, nil).should === false
  end
  it "sets snapshot_allow_differences to true" do
    @configuration.find_and_execute_task('cf:localchanges:allow_differences')
    @configuration.fetch(:snapshot_allow_differences, nil).should === true
  end
end

