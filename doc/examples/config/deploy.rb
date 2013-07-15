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

set :stages, %w(production staging)
set :default_stage, "production"

require "capistrano/ext/multistage"

#=============================================================================
# app details and WordPress requirements

# tags/3.5.2, branches/3.5, trunk
set :wordpress_version, "branches/3.5"
set :application, "my_application"

#=============================================================================
# app source repository configuration

set :scm, :git
set :repository, "https://github.com/example/example-wp.git"
set :git_enable_submodules, 1

#=============================================================================
# Housekeeping
# clean up old releases on each deploy
set :keep_releases, 5
after "deploy:create_symlink", "deploy:cleanup"
