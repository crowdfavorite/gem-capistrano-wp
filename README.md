# capistrano-wp

Recipes for deploying and maintaining remote WordPress installations with
Capistrano.

This is an alternative version control and deployment strategy from the
one presented in [WP-Stack](https://github.com/markjaquith/WP-Stack).
WP-Stack expects WordPress Core to be included in the project as a git
submodule; these recipes pull WordPress in from SVN (and can therefore
also deploy multisite environments with WP at the root).

## Usage

This is a plugin for the Capistrano deployment tool.  If you are unfamiliar
with Capistrano, we would suggest at least familiarizing yoruself with
the general concepts outlined in the [Capistrano Wiki](https://github.com/capistrano/capistrano/wiki).

### Assuptions (Requirements)

  - Your code repository is your webroot

### Install / Setup

    gem install capistrano-wp
    cd /path/to/repository
    capify-wp .

### Abridged General Capistrano Usage

1. Create a user for deploying your WordPress install
2. Create an SSH key for the deploy user, and make sure you can SSH to it from your local machine
3. [Install RubyGems][rubygems].  Crowd Favorite prefers to use [RVM][rvm] to maintain ruby versions, rubygems, and self-contained sets of gems.
4. Install the capistrano-wp gem (which will install Capistrano and friends): `gem install capistrano-wp`
5. Follow **Install / Setup** steps above
6. Make sure your `:deploy_to` path exists and is owned by the deploy user
7. Run `cap deploy:setup` to set up the initial directories
8. Run `cap deploy` to push out a new version of your code
9. Update your web server configuration to point to the current-release directory (in the `:deply_to` directory, named `httpdocs` by default)
10. Relax and enjoy painless deployment

## Capistrano Multi-stage

This deployment strategy comes with multi-stage support baked in.

For documentation regarding this portion of functionality, see the
[Capistrano Multistage Documentation](https://github.com/capistrano/capistrano/wiki/2.x-Multistage-Extension).

## Capistrano-WP Specific Features

### Handling of WordPress

This gem handles WordPress via SVN directly from WordPress.org.

In your main `config/deploy.rb` file you will see how to decalare what
version of WordPress you wish to use by defining an SVN location
like `branches/3.6`, `tags/3.6.1` or even `trunk`

```ruby
set :wordpress_version, "branches/3.5"
```

It then places WordPress where you declare it to live within the stage
specific configuration files, for example `config/deploy/production.rb`

```ruby
set(:wp_path) { File.join(release_path, "wp") }
```

This places WordPress in a directory called "wp" within your webroot.

It also gracefully handles the situation where both your code repository
and WordPress live at the webroot

This process enables you to not have to track WordPress within your code repository.

### Persistent file/directory symlinks

This gem augments the way capistrano handles directories you need to "persist"
between releases.  Providing a declaritive interface for these items.

There are some common directories that WordPress needs to act this way.  By
default, if the following directories exist in the "shared" directory, they
will be symlinked into every release.

  - `cache` is linked to `wp-content/cache`
  - `uploads` is linked to `wp-content/uploads`
  - `blogs.dir` is linked to `wp-content/blogs.dir`

This is the way these would be declared, either in the main `config/deploy.rb` or
in your stage specific files, if they weren't defaults

```ruby
set :wp_symlinks, [{
  "cache" => "wp-content/cache"
  "uploads" => "wp-content/uploads"
  "blogs.dir" => "wp-content/blogs.dir"
}]
```

These will happen without any further configuration changes.  If you wish
to override any of these defaults, you can set the target of the link to `nil`

```ruby
set :wp_symlinks, [{
  "cache" => nil
}]
```

This would turn off the default `cache` symlink

You can easily add your own project (or even stage) specific links

If you have a `customlink` directory in the shared directory, you can add
a custom link like so.

```ruby
set :wp_symlinks, [{
  "customlink" => "wp-content/themes/mytheme/customlinktarget"
}]
```

### Persistent Configs

These are handled almost identically as above except they are copied
from the shared directory instead of symlinked.

This is primarily for config files that are sometimes written
to by plugins.  In some cases when php tries to write to a symbolic
link, the link is destroyed and becomes a zero byte file.

By default the following copies are attempted

```ruby
set :wp_configs, [{
  "db-config.php" => "/",
  "advanced-cache.php" => "wp-content/",
  "object-cache.php" => "wp-content/",
  "*.html" => "/",
}]
```

You can follow the same steps as the symlinks for modification or addition
to the default config copying rules.

### Stage specfiic overrides

Stage specific overrides allow you to target specific configuration
files to their respective stage.

You need to use a specific set of `.htaccess` rules for production.

If you place a file named `production-htaccess` in your `config/` directory

and add it to your `:stage_specific_overrides` in your `config/deploy/production.rb`

```ruby
set :stage_specific_overrides, {
  ".htaccess" => ".htaccess"
}
```

This will place the proper `production-htaccess` file in the root of
your next release, overriding any existing file of the same name.

By default, it looks for the common `.htaccess` situation
along withh `local-config.php`

```ruby
set :stage_specific_overrides, {
  "local-config.php" => "local-config.php",
  ".htaccess" => ".htaccess"
}
```

Modifications and additions are handled similarly to symlinks and
configs, but note the lack of a wrapping `[]`

### Stripping out unnecessary files and directories

You can remove specific files and directories from your releases
at the time of deploy.

By default the list of things the gem strips out looks like this

```ruby
set :copy_exclude, [
  ".git",
  "Capfile",
  "/config",
  "capinfo.json",
  ".DS_Store",
]
```

This excludes the listed files from making it into a release

**For this you actually need to re-declare the set to add / remove these exclusions.**

For example, to allow the `.git` directory to exist in the releases, you would
re-declare the option completely.  Removing the `.git` entry.

```ruby
set :copy_exclude, [
  "Capfile",
  "/config",
  "capinfo.json",
  ".DS_Store",
]
```

This is usually placed in `config/deploy.rb` but can also be placed at the stage level.

### Detecting Local Changes

This gem by default checks the current release for modifications since
it was deployed.  Either you're dealing with clients that like to make
changes in production, or you have plugins that write configs and other
things to the file system.  This step protects you against moving changes
that have happend in the target stage out of use.

When deploying, if it detects a change it will stop the deploy process, and
provide you with a listing of all the files that have been either added,
changed, or deleted.

At this point you can rectify the changes yourself if you wish, adding them to
your source control, or verifying you don't need them.

Then you call the deploy like this to force it to create the new release.

    cap cf:localchanges:allow_differences deploy

This will tell the deploy to ignore any of these changes and proceed.

If you would like to turn this feature off, you can have it force this by
default with the following option set in either your main `config/deploy.rb`
or your stage specific files.

```ruby
set :snapshot_allow_differences, true
```

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

