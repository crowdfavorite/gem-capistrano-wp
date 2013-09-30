set :stage, "production"

set :user, 'deployuser'
set :use_sudo, false

server '0.0.0.0', :app, :web, :db, :primary => true

## For multiple server setups
#
# server '0.0.0.0', :app, :web, :primary => true
# server '0.0.0.0', :app, :web
# # Don't push code to this server with 'cap deploy'
# server '0.0.0.0', :db, :no_release => true

# Site base directory
set :base_dir, "/var/local/www/example"
set :deploy_to, File.join(fetch(:base_dir))

# Webroot
set :current_dir, "httpdocs"

# Path to WordPress, supports WP at the root (empty string) and WordPress
# in a custom location (webroot/wp in our example).
set(:wp_path) { File.join(release_path, "wp") }

# Deploy strategy - use :remote_cache when possible, but some servers need :copy
#set :deploy_via, :copy
set :deploy_via, :remote_cache

# Specify a git branch to deploy
# 
# Using fetch() here allows you to set your branch from the command line,
# but allows a default, "master" in this case.
#
#    cap deploy -s branch=my-custom-branch
#
set :branch, fetch(:branch, "master")

#=============================================================================
# Files to link or copy into web root from capistrano's shared directory
# Symlinks are symlinked in

# wp_symlinks defaults to:
#  "cache" => "wp-content/cache"
#  "uploads" => "wp-content/uploads"
#  "blogs.dir" => "wp-content/blogs.dir"
#
# To override, set the target to nil:
#
#set :wp_symlinks, [{
#  "cache" => nil
#}]
#
# Or add other files:
#
#set :wp_symlinks, [{
#  "authcache" => "wp-content/authcache"
#}]
#
# Configs are copied in, and default to:
#  "db-config.php" => "/",
#  "advanced-cache.php" => "wp-content/",
#  "object-cache.php" => "wp-content/",
#  "*.html" => "/",
#
# To override (like wp_symlinks):
#set :wp_configs, [{
#}]
#
# Stage-specific overrides are copied from the config directory,
# like production-example.txt or staging-example.txt
# Default list:
#
#       "local-config.php" => "local-config.php",
#       ".htaccess" => ".htaccess"
#
# To override or add other files (as above, but note no []):
#
#set :stage_specific_overrides, {
#}
