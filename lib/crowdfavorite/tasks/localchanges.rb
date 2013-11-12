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

module CrowdFavorite::Tasks::LocalChanges
  extend CrowdFavorite::Support::Namespace

  namespace :cf do
    def _cset(name, *args, &block)
      unless exists?(name)
        set(name, *args, &block)
      end
    end

    _cset(:comparison_target) { current_release rescue File.dirname(release_path) }
    _cset(:hash_creation) {
      # Find out what hashing mechanism we can use - shasum, sha1sum, openssl, or just an ls command.
      # Unfortunate double-call of which handles some systems which output an error message on stdout
      # when the program cannot be found.
      creation = capture('((which shasum >/dev/null 2>&1 && which shasum) || (which sha1sum >/dev/null 2>&1 && which sha1sum) || (which openssl >/dev/null 2>&1 && which openssl) || echo "ls -ld")').to_s.strip
      if creation.match(/openssl$/)
        "#{creation} sha1 -r"
      end
      creation
    }

    _cset(:hash_directory) { shared_path }
    _cset(:hash_suffix) { "_hash" }
    _cset(:hash_compare_suffix) { "compare" }
    _cset(:hashes) { capture("ls -xt #{File.join(hash_directory, '*' + hash_suffix)}").split.reverse }
    _cset(:localchanges_excludes) {
      {
        :deleted => [],
        :created => [],
        :changed => [],
        :any => []
      }
    }

    def _snapshot_exists(path)
        retcode = (capture("test -f " + Shellwords::escape(path) + "; echo $?").to_s.strip.to_i)
        return retcode == 0 ? true : false
    end

    def _hash_path(release, extra = "")
      File.join(hash_directory, release + hash_suffix + extra)
    end

    namespace :localchanges do
      task :snapshot_deploy, :except => { :no_release => true } do
        set(:snapshot_target, latest_release)
        snapshot
        unset(:snapshot_target)
      end

      desc "Snapshot the current release for later change detection."
      task :snapshot, :except => { :no_release => true } do
        target_release = File.basename(fetch(:snapshot_target, comparison_target))

        target_path = File.join(releases_path, target_release)
        default_hash_path = _hash_path(target_release) # File.join(shared_path, target_release + "_hash")
        hash_path = fetch(:snapshot_hash_path, default_hash_path)

        snapshot_exists = _snapshot_exists(hash_path)

        if snapshot_exists and !fetch(:snapshot_force, false)
          logger.info "A snapshot for release #{target_release} already exists."
          next
        end

        run("find " + Shellwords::escape(target_path) + " -name .git -prune -o -name .svn -prune -o -type f -print0 | xargs -0 #{hash_creation} > " + Shellwords::escape(hash_path))

      end

      desc "Call this before a deploy to continue despite local changes made on the server."
      task :allow_differences do
        set(:snapshot_allow_differences, true)
      end

      task :forbid_differences do
        set(:snapshot_allow_differences, false)
      end

      def _do_snapshot_compare()
        if releases.length == 0
          logger.info "no current release"
          return false
        end
        release_name = File.basename(current_release)
        set(:snapshot_target, current_release)
        default_hash_path = _hash_path(release_name) # File.join(shared_path, release_name + "_hash")
        snapshot_exists = _snapshot_exists(default_hash_path)
        if !snapshot_exists
          logger.info "no previous snapshot to compare against"
          return false
        end
        set(:snapshot_hash_path, _hash_path(release_name, hash_compare_suffix)) # File.join(shared_path, release_name + "_hash_compare"))
        set(:snapshot_force, true)
        snapshot

        # Hand-tooled diff-parsing - handles either shasum-style or ls -ld output
        # Hashes store filename => [host, host, host]
        left = {}
        right = {}
        changed = {}
        run("diff " + default_hash_path + " " + snapshot_hash_path + " || true") do |channel, stream, data|
          data.each_line do |line|
            line.strip!
            if line.match(/^\s*[<>]/)
              parts = line.split(/\s+/)
              if hash_creation.match(/ls -ld/)
                # > -rw-rw-r-- 1 example example 41 Sep 19 14:58 index.php
                parts.slice!(0, 9)
              else
                # < 198ed94e9f1e5c69e159e8ba6d4420bb9c039715  index.php
                parts.slice!(0,2)
              end

              bucket = line.match(/^\s*</) ? left : right
              filename = parts.join('')

              bucket[filename] ||= []
              bucket[filename].push(channel[:host])
            end
          end
        end
        if !(left.empty? && right.empty?)
          left.each do |filename, servers|
            if right.has_key?(filename)
              servers.each do |host|
                if right[filename].delete(host)
                  changed[filename] ||= []
                  changed[filename].push(host)
                  left[filename].delete(host)
                end
              end

              left.delete(filename) if left[filename].empty?
              right.delete(filename) if right[filename].empty?
            end
          end
        end
        excludes = fetch(:localchanges_excludes)
        excludes[:any] ||= []
        logger.important "Excluding from #{current_release}: #{excludes.inspect}"
        excluded = {:left => {}, :right => {}, :changed => {}}
        found_exclusion = false
        [[left, :deleted], [right, :created], [changed, :changed]].each do |filegroup, excluder|
          excludes[excluder] ||= []
          filegroup.each do |filename, servers|
            if excludes[excluder].detect {|f| f == filename or File.join(current_release, f) == filename} or
              excludes[:any].detect {|f| f == filename or File.join(current_release, f) == filename}
              found_exclusion = true
              excluded[excluder] ||= {}
              excluded[excluder][filename] ||= []
              excluded[excluder][filename].push(*servers)
              excluded[excluder][filename].uniq!
              filegroup.delete(filename)
            end
          end
        end

        unset(:snapshot_target)
        unset(:snapshot_hash_path)
        unset(:snapshot_force)
        return {:left => left, :right => right, :changed => changed, :excluded => excluded}
      end

      def _do_snapshot_diff(results, format = :full)
        if !results
          return false
        end
        if results[:left].empty? && results[:right].empty? && results[:changed].empty?
          if results.has_key?(:excluded)
            logger.important "excluded: " + results[:excluded].inspect
          end
          return false
        end

        if format == :basic || !(fetch(:strategy).class <= Capistrano::Deploy::Strategy.new(:remote).class)
          [[:left, 'deleted'], [:right, 'created'], [:changed, 'changed']].each do |resultgroup, verb|
            if !results[resultgroup].empty?
              logger.important "#{verb}: "
              results[resultgroup].each do |thefile, servers|
                filename = thefile
                if filename.start_with? current_release
                  filename = thefile.slice(current_release.length..-1)
                end
                logger.important "#{File.basename filename} in #{File.dirname filename} (on #{servers.inspect})"
              end
            end
          end

          if results.has_key?(:excluded)
            logger.info "excluded: " + results[:excluded].inspect
          end
          return true
        end

        ## TODO: improve diff handling for remote_cache with .git copy_excluded
        ## TODO: improve diff handling for remote_cache with .git not copy_excluded
        ## TODO: improve diff handling for remote_cache with .svn copy_excluded
        ## TODO: improve diff handling for remote_cache with .svn not copy_excluded
        logger.important "deleted: " + results[:left].inspect
        logger.important "created: " + results[:right].inspect
        logger.important "changed: " + results[:changed].inspect
        if results.has_key?[:excluded]
          logger.important "excluded: " + results[:excluded].inspect
        end
        return true
      end

      desc "Check the current release for changes made on the server; abort if changes are detected."
      task :compare, :except => { :no_release => true } do
        results = _do_snapshot_compare()
        if _do_snapshot_diff(results, :basic)
          abort("Aborting: local changes detected in current release") unless fetch(:snapshot_allow_differences, false)
          logger.important "Continuing deploy despite differences!"
        end
      end

      desc "Check the current release for changes made on the server (and return detailed changes, if using a remote-cached git repo).  Does not abort on changes."
      task :diff, :except => { :no_release => true } do
        results = _do_snapshot_compare()
        _do_snapshot_diff(results, :full)
      end

      task :cleanup, :except => { :no_release => true } do
        count = fetch(:keep_releases, 5).to_i
        if count >= hashes.length
          logger.info "no old hashes to clean up"
        else
          logger.info "keeping #{count} of #{hashes.length} release hashes"
          hashpaths = (hashes - hashes.last(count)).map{ |thehash|
            File.join(thehash) + " " + File.join(thehash + hash_compare_suffix)
          }.join(" ")
          try_sudo "rm -f #{hashpaths}"
        end
      end
    end
  end
end

