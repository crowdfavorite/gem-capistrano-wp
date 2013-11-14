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

require 'crowdfavorite/tasks'
require 'shellwords'

module CrowdFavorite::Tasks::WordPress
  extend CrowdFavorite::Support::Namespace
  def _combine_filehash base, update
    if update.respond_to? :has_key?
      update = [update]
    end
    new = {}
    new.merge!(base)
    update.each do |update_hash|
      new.merge!(update_hash)
    end
    new
  end
  namespace :cf do
    def _cset(name, *args, &block)
      unless exists?(name)
        set(name, *args, &block)
      end
    end

    _cset :copy_exclude, [
      ".git", ".gitignore", ".gitmodules",
      ".DS_Store", ".svn",
      "Capfile", "/config",
      "capinfo.json",
    ]

    # wp_symlinks are symlinked from the shared directory into the release.
    # Key is the shared file; value is the target location.
    # :wp_symlinks overwrites :base_wp_symlinks; an empty target location
    # means to skip linking the file.
    _cset :base_wp_symlinks, {
      "cache" => "wp-content/cache",
      "uploads" => "wp-content/uploads",
      "blogs.dir" => "wp-content/blogs.dir",
    }

    _cset :wp_symlinks, {}

    # wp_configs are copied from the shared directory into the release.
    # Key is the shared file; value is the target location.
    # :wp_configs overwrites :base_wp_configs; an empty target location
    # means to skip copying the file.
    _cset :base_wp_configs, {
      "db-config.php" => "wp-content/",
      "advanced-cache.php" => "wp-content/",
      "object-cache.php" => "wp-content/",
      "*.html" => "/",
    }

    _cset :wp_configs, {}

    # stage_specific_overrides are uploaded from the repo's config
    # directory, if they exist for that stage.  Files are named
    # 'STAGE-filename.txt' locally and copied to 'filename.txt'
    # on deploy for that stage.
    # Key is the local file; value is the target location.
    # :stage_specific_overrides overwrites :base_stage_specific_overrides;
    # an empty target location means to skip uploading the file.
    _cset :base_stage_specific_overrides, {
      "local-config.php" => "local-config.php",
      ".htaccess" => ".htaccess"
    }

    _cset :stage_specific_overrides, {}

    before   "deploy:finalize_update", "cf:wordpress:generate_config"
    after    "deploy:finalize_update", "cf:wordpress:touch_release"
    after    "cf:wordpress:generate_config", "cf:wordpress:link_symlinks"
    after    "cf:wordpress:link_symlinks", "cf:wordpress:copy_configs"
    after    "cf:wordpress:copy_configs", "cf:wordpress:install"
    after    "cf:wordpress:install", "cf:wordpress:do_stage_specific_overrides"
    namespace :wordpress do

      namespace :install do

        desc <<-DESC
              [internal] Installs WordPress with a remote svn cache
        DESC
        task :with_remote_cache, :except => { :no_release => true } do
          wp = fetch(:wordpress_version, "trunk")
          wp_target = fetch(:wp_path, release_path)
          wp_stage = File.join(shared_path, "wordpress", wp)
          # check out cache of wordpress code
          run Shellwords::shelljoin(["test", "-e", wp_stage]) +
            " || " + Shellwords::shelljoin(["svn", "co", "-q", "http://core.svn.wordpress.org/" + wp, wp_stage])
          # update branches or trunk (no need to update tags)
          run Shellwords::shelljoin(["svn", "up", "--force", "-q", wp_stage]) unless wp.start_with?("tags/")
          # ensure a clean copy
          run Shellwords::shelljoin(["svn", "revert", "-R", "-q", wp_stage])
          # trailingslashit for rsync
          wp_stage << '/' unless wp_stage[-1..-1] == '/'
          # push wordpress into the right place (release_path by default, could be #{release_path}/wp)
          run Shellwords::shelljoin(["rsync", "--exclude=.svn", "--ignore-existing", "-a", wp_stage, wp_target])
        end

        desc <<-DESC
              [internal] Installs WordPress with a local svn cache/copy, compressing and uploading a snapshot
        DESC
        task :with_copy, :except => { :no_release => true } do
          wp = fetch(:wordpress_version, "trunk")
          wp_target = fetch(:wp_path, release_path)
          Dir.mktmpdir do |tmp_dir|
            tmpdir = fetch(:cf_database_store, tmp_dir)
            wp = fetch(:wordpress_version, "trunk")
            Dir.chdir(tmpdir) do
              if !(wp.start_with?("tags/") || wp.start_with?("branches/") || wp == "trunk")
                wp = "branches/#{wp}"
              end
              wp_stage = File.join(tmpdir, "wordpress", wp)
              ["branches", "tags"].each do |wpsvntype|
                system Shellwords::shelljoin(["mkdir", "-p", File.join(tmpdir, "wordpress", wpsvntype)])
              end

              puts "Getting WordPress #{wp} to #{wp_stage}"
              system Shellwords::shelljoin(["test", "-e", wp_stage]) +
                " || " + Shellwords::shelljoin(["svn", "co", "-q", "http://core.svn.wordpress.org/" + wp, wp_stage])
              system Shellwords::shelljoin(["svn", "up", "--force", "-q", wp_stage]) unless wp.start_with?("tags/")
              system Shellwords::shelljoin(["svn", "revert", "-R", "-q", wp_stage])
              wp_stage << '/' unless wp_stage[-1..-1] == '/'
              Dir.mktmpdir do |copy_dir|
                comp = Struct.new(:extension, :compress_command, :decompress_command)
                remote_tar = fetch(:copy_remote_tar, 'tar')
                local_tar = fetch(:copy_local_tar, 'tar')
                type = fetch(:copy_compression, :gzip)
                compress = case type
                           when :gzip, :gz   then comp.new("tar.gz",  [local_tar, '-c -z --exclude .svn -f'], [remote_tar, '-x -k -z -f'])
                           when :bzip2, :bz2 then comp.new("tar.bz2", [local_tar, '-c -j --exclude .svn -f'], [remote_tar, '-x -k -j -f'])
                           when :zip         then comp.new("zip",     %w(zip -qyr), %w(unzip -q))
                           else raise ArgumentError, "invalid compression type #{type.inspect}"
                           end
                compressed_filename = "wp-" + File.basename(fetch(:release_path)) + "." + compress.extension
                local_file = File.join(copy_dir, compressed_filename)
                puts "Compressing #{wp_stage} to #{local_file}"
                Dir.chdir(wp_stage) do
                  system([compress.compress_command, local_file, '.'].join(' '))
                end
                remote_file = File.join(fetch(:copy_remote_dir, '/tmp'), File.basename(local_file))
                puts "Pushing #{local_file} to #{remote_file} to deploy"
                upload(local_file, remote_file)
                wp_target = fetch(:wp_path, fetch(:release_path))
                run("mkdir -p #{wp_target} && cd #{wp_target} && (#{compress.decompress_command.join(' ')} #{remote_file} || echo 'tar errors for normal conditions') && rm #{remote_file}")
              end

            end
          end
        end

        desc <<-DESC
              [internal] Installs WordPress to the application deploy point
        DESC
        task :default, :except => { :no_release => true } do
          wp = fetch(:wordpress_version, false)
          if wp.nil? or wp == false or wp.empty?
            logger.info "Not installing WordPress"
          elsif fetch(:strategy).class <= Capistrano::Deploy::Strategy.new(:remote).class
            with_remote_cache
          else
            with_copy
          end
        end
      end

      desc <<-DESC
              [internal] (currently unused) Generate config files if appropriate
      DESC
      task :generate_config, :except => { :no_release => true } do
        # live config lives in wp-config.php; dev config loaded with local-config.php
        # this method does nothing for now
      end

      desc <<-DESC
              [internal] Symlinks specified files (usually uploads/blogs.dir/cache directories)
      DESC
      task :link_symlinks, :except => { :no_release => true } do
        symlinks = _combine_filehash(fetch(:base_wp_symlinks), fetch(:wp_symlinks))
        symlinks.each do |src, targ|
          next if targ.nil? || targ == false || targ.empty?
          src = File.join(shared_path, src) unless src.include?(shared_path)
          targ = File.join(release_path, targ) unless targ.include?(release_path)
          run [
            Shellwords::shelljoin(["test", "-e", src]),
            Shellwords::shelljoin(["test", "-d", targ]),
            Shellwords::shelljoin(["rm", "-rf", targ])
          ].join(' && ') + " || true"
          run Shellwords::shelljoin(["test", "-e", src]) + " && " + Shellwords::shelljoin(["ln", "-nsf", src, targ]) + " || true"
        end
      end

      desc <<-DESC
              [internal] Copies specified files (usually advanced-cache, object-cache, db-config)
      DESC
      task :copy_configs, :except => { :no_release => true } do
        configs = _combine_filehash(fetch(:base_wp_configs), fetch(:wp_configs))
        configs.each do |src, targ|
          next if targ.nil? || targ == false || targ.empty?
          src = File.join(shared_path, src) unless src.include?(shared_path)
          targ = File.join(release_path, targ) unless targ.include?(release_path)
          run "ls -d #{src} >/dev/null 2>&1 && cp -urp #{src} #{targ} || true"
          #run Shellwords::shelljoin(["test", "-e", src]) + " && " + Shellwords::shelljoin(["cp", "-rp", src, targ]) + " || true"
        end
      end

      desc <<-DESC
              [internal] Pushes up local-config.php, .htaccess, others if they exist for that stage
      DESC
      task :do_stage_specific_overrides, :except => { :no_release => true } do
        next unless fetch(:stage, false)
        overrides = _combine_filehash(fetch(:base_stage_specific_overrides), fetch(:stage_specific_overrides))
        overrides.each do |src, targ|
          next if targ.nil? || targ == false || targ.empty?
          src = File.join("config", "#{stage}-#{src}")
          targ = File.join(release_path, targ) unless targ.include?(release_path)
          if File.exist?(src)
            upload(src, targ)
          end
        end
      end

      desc <<-DESC
              [internal] Ensure the release path has an updated modified time for deploy:cleanup
      DESC
      task :touch_release, :except => { :no_release => true } do
        run "touch '#{release_path}'"
      end
    end

    #===========================================================================
    # util / debugging code

    namespace :debugging do

      namespace :release_info do
        desc <<-DESC
            [internal] Debugging info about releases.
        DESC

        task :default do
          %w{releases_path shared_path current_path release_path releases previous_release current_revision latest_revision previous_revision latest_release}.each do |var|
            puts "#{var}: #{eval(var)}"
          end
        end
      end
    end
  end
end

