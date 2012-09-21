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

    namespace :localchanges do
      task :snapshot_deploy, :except => { :no_release => true } do
        set(:snapshot_target, latest_release)
        snapshot
        unset(:snapshot_target)
      end

      task :snapshot, :except => { :no_release => true } do
        target_release = File.basename(fetch(:snapshot_target, comparison_target))

        target_path = File.join(releases_path, target_release)
        default_hash_path = File.join(shared_path, target_release + "_hash")
        hash_path = fetch(:snapshot_hash_path, default_hash_path)

        snapshot_exists = !(capture("test -f " + Shellwords::escape(hash_path) + "; echo $?").to_s.strip)
        
        if snapshot_exists and fetch(:snapshot_force, false)
          puts "A snapshot for release #{target_release} already exists."
          return
        end

        run("find " + Shellwords::escape(target_path) + " -type f -print0 | xargs -0 #{hash_creation} > " + Shellwords::escape(hash_path))

      end

      task :allow_differences do
        set(:snapshot_allow_differences, true)
      end

      task :forbid_differences do
        set(:snapshot_allow_differences, false)
      end

      task :compare, :except => { :no_release => true } do
        release_name = File.basename(latest_release)
        set(:snapshot_target, latest_release)
        default_hash_path = File.join(shared_path, release_name + "_hash")
        set(:snapshot_hash_path, File.join(shared_path, release_name + "_hash_compare"))
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

          puts "deleted: " + left.inspect
          puts "created: " + right.inspect
          puts "changed: " + changed.inspect

          abort("Aborting: changes detected") unless fetch(:snapshot_allow_differences, false)
        end

        unset(:snapshot_target)
        unset(:snapshot_hash_path)
        unset(:snapshot_force)
      end

    end
  end
end

