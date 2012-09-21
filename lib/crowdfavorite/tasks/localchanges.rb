require 'crowdfavorite/tasks'

module CrowdFavorite::Tasks::LocalChanges
  extend CrowdFavorite::Support::Namespace

  namespace :cf do
    def _cset(name, *args, &block)
      unless exists?(name)
        set(name, *args, &block)
      end
    end

    _cset(:comparison_target) { current_release }
    _cset(:hash_creation) { 
      creation = capture('(which shasum || which openssl || which sha1sum || echo "ls -ld")').to_s.strip
      if creation.match(/openssl$/)
        "#{creation} sha1 -r"
      end
      creation
    }

    _cset(:hash_directory) { shared_path }
    _cset(:hash_suffix) { "_hash" }
    _cset(:hash_compare_suffix) { "compare" }
    _cset(:hashes) { capture("ls -xt #{File.join(hash_directory, '*' + hash_suffix)}").split.reverse }


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

        run("find " + Shellwords::escape(target_path) + " -type f -print0 | xargs -0 #{hash_creation} > " + Shellwords::escape(hash_path))

      end

      desc "Call this before a deploy to continue despite local changes made on the server."
      task :allow_differences do
        set(:snapshot_allow_differences, true)
      end

      task :forbid_differences do
        set(:snapshot_allow_differences, false)
      end

      desc "Check the current release for changes made on the server."
      task :compare, :except => { :no_release => true } do
        release_name = File.basename(current_release)
        set(:snapshot_target, current_release)
        default_hash_path = _hash_path(release_name) # File.join(shared_path, release_name + "_hash")
        snapshot_exists = _snapshot_exists(default_hash_path)
        if !snapshot_exists
          logger.info "no previous snapshot to compare against"
          next
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

          logger.important "deleted: " + left.inspect
          logger.important "created: " + right.inspect
          logger.important "changed: " + changed.inspect

          abort("Aborting: local changes detected in current release") unless fetch(:snapshot_allow_differences, false)
          logger.important "Continuing deploy despite differences!"
        end

        unset(:snapshot_target)
        unset(:snapshot_hash_path)
        unset(:snapshot_force)
      end

      task :cleanup, :except => { :no_release => true } do
        count = fetch(:keep_releases, 5).to_i
        if count >= hashes.length
          logger.info "no old hashes to clean up"
        else
          logger.info "keeping #{count} of #{hashes.length} release hashes"
          hashpaths = (hashes - hashes.last(count)).map{ |thehash|
            File.join(hash_directory, thehash) + " " + File.join(hash_directory, thehash + hash_compare_suffix)
          }.join(" ")
          try_sudo "rm -f #{hashpaths}"
        end
      end
    end
  end
end

