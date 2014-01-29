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

# Default set of tasks for wordpress deploys, including all the before/after bindings

require 'crowdfavorite/tasks/wordpress'
require 'crowdfavorite/tasks/localchanges'
require 'capistrano/recipes/deploy/scm/git-enhanced'

module CrowdFavorite::WordPress
  extend CrowdFavorite::Support::Namespace
  namespace :cf do
    after "deploy:finalize_update", "cf:localchanges:snapshot_deploy"
    after "deploy:cleanup", "cf:localchanges:cleanup"
    before "deploy", "cf:localchanges:compare"
  end
end

