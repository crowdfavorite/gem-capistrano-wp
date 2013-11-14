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

#=============================================================================
# Additional Project specific directories

# Uncomment these lines to additionally create your upload and cache
# directories in the shared location when running `deploy:setup`.
#
# Modify these commands to make sure these directories are writable by
# your web server.

# after "deploy:setup" do
#   ['uploads', 'cache'].each do |dir|
#     run "cd #{shared_path} && mkdir #{dir} && chgrp www-data #{dir} && chmod 775 #{dir}"
#   end
# end
