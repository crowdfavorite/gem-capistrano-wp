# capistrano-wp

Recipes for deploying and maintaining remote WordPress installations with
Capistrano.

This is an alternative version control and deployment strategy from the
one presented in [WP-Stack](https://github.com/markjaquith/WP-Stack).
WP-Stack expects WordPress Core to be included in the project as a git
submodule; these recipes pull WordPress in from SVN (and can therefore
also deploy multisite environments with WP at the root).

## Usage

See `doc/examples` for an example Capfile and capistrano config directory.

General Capistrano usage:

1. Create a user for deploying your WordPress install
2. Create an SSH key for the deploy user, and make sure you can SSH to it from your local machine
3. [Install RubyGems][rubygems].  Crowd Favorite prefers to use [RVM][rvm] to maintain ruby versions, rubygems, and self-contained sets of gems.
4. Install the capistrano-wp gem (which will install Capistrano and friends): `gem install capistrano-wp`
5. Ensure that your project is in a repository starting at the web root
6. Navigate to the root of your and run `capify-wp .`, this will create the neccessary configuration files.
7. Review create config files and adjust to your project specifics
7. Make sure your `:deploy_to` path exists and is owned by the deploy user
8. Run `cap deploy:setup` to set up the initial directories
9. Run `cap deploy` to push out a new version of your code
10. Update your web server configuration to point to the current-release directory (in the `:deply_to` directory, named `httpdocs` by default)
11. Relax and enjoy painless deployment

## Capistrano Multi-stage

This deployment strategy comes with multi-stage support baked in.

For documentation regarding this portion of functionality, see the
[Capistrano Multistage Documentation](https://github.com/capistrano/capistrano/wiki/2.x-Multistage-Extension).

## Capistrano-WP Specific Features

### Persistent file/directory symlinks

### Persistent Configs

### Detecting Local Changes

## Development

[rubygems]: http://rubygems.org/pages/download
[rvm]: https://rvm.io/

	gem install bundle
	bundle install
	rake install

When updating the gem requirements:

	rake gemspec

# Copyright

Copyright (c) 2012-2013 Crowd Favorite, Ltd. Released under the Apache License, version 2.0. See LICENSE.txt for further details.

