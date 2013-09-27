set :stages, %w(production)
set :default_stage, "production"

require 'capistrano/ext/multistage'

#=============================================================================
# app details and WordPress requirements

# tags/3.5.1, branches/3.5, trunk
set :wordpress_version, "trunk"
set :application, "my-wordpress-site.com"

#=============================================================================
# app source repository configuration

set :scm, :git
set :repository, ""
set :git_enable_submodules, 1
#set :git_shallow_clone, 1

#=============================================================================
# Housekeeping
# clean up old releases on each deploy
set :keep_releases, 5
after "deploy:create_symlink", "deploy:cleanup"

