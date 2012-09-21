require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'crowdfavorite/tasks/localchanges'

describe CrowdFavorite::LocalChanges, "loaded into capistrano" do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.extend(Capistrano::Spec::ConfigurationExtension)
    CrowdFavorite::LocalChanges.load_into(@configuration)
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

