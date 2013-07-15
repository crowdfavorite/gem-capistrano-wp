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

set :stage, "production"

set :user, 'deployuser'
set :use_sudo, false

server '172.16.42.42', :app, :web, :primary => true
server '172.16.42.43', :app, :web

# Don't push code to this server with 'cap deploy'
server '172.16.17.17', :db, :no_release => true

set :base_dir, "/var/local/www/example"
set :deploy_to, File.join(fetch(:base_dir))
set :current_dir, "httpdocs"
set(:wp_path) { File.join(release_path, "wp") }
# :version_dir - where versions live, 'versions'
# :shared_dir - where shared files (wordpress cache, et cetera) live, 'shared'

# Deploy strategy - use :remote_cache when possible, but some servers need :copy
#set :deploy_via, :remote_cache
set :deploy_via, :remote_cache

# Specify a git branch to deploy
set :branch, fetch(:branch, "master")

#=============================================================================
# Files to link or copy into web root
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
