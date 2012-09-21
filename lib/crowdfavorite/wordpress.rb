# Default set of tasks for wordpress deploys, including all the before/after bindings

require 'crowdfavorite/tasks/wordpress'
require 'crowdfavorite/tasks/localchanges'

module CrowdFavorite::WordPress
  extend CrowdFavorite::Support::Namespace
  namespace :cf do
    after "deploy:finalize_update", "cf:localchanges:snapshot_deploy"
    before "deploy", "cf:localchanges:compare"
  end
end

