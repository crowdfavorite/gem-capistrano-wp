# capistrano-wordpress

Recipes for deploying and maintaining remote WordPress installations with
Capistrano.

This is an alternative version control and deployment strategy from the
one presented in [WP-Stack](https://github.com/markjaquith/WP-Stack).
WP-Stack expects WordPress Core to be included in the project as a git
submodule; these recipes pull WordPress in from SVN (and can therefore
also deploy multisite environments with WP at the root).

## Usage

This is a very early release, and the usage is not extremely well documented.  A minimal Capfile might look like this:

	require 'rubygems'
	require 'railsless-deploy'
	require 'crowdfavorite/wordpress'
	# tags/3.4.1, branches/3.4, trunk
	set :wordpress_version, "branches/3.4"
	set :application, "wp.example.com"
	set :scm, :git
	set :repository, "git@github.com:example/wordpress-site.git"
	set :git_enable_submodules, 1
	set :user, 'wpdeploy'
	server 'web.example.com', :app, :web, :primary => true
	# Deploy to /var/www/domains/wp.example.com/htdocs
	# Link uploads, blogs.dir, cache from /var/www/domains/wp.example.com/shared 
	# to /var/www/domains/wp.example.com/htdocs/wp-content
	# Install WordPress into /var/www/domains/wp.example.com/htdocs/wp
	set :base_dir, '/var/www/domains'
	set :deploy_to, File.join(base_dir, application)
	set :current_dir, 'htdocs'
	set(:wp_path) { File.join(release_path, 'wp') }
	set :deploy_via, :remote_cache

Also see the `:wp_symlinks` and `:wp_configs` settings in the source.

## Development

	gem install bundle
	bundle install
	rake install

When updating the gem requirements:

	rake gemspec

# Copyright

Copyright (c) 2012 Crowd Favorite, Ltd. See LICENSE.txt for further details.

