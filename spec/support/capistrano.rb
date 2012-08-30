require 'capistrano/spec'

RSpec.configure do |config|
  config.include Capistrano::Spec::Helpers
  config.include Capistrano::Spec::Matchers
end
