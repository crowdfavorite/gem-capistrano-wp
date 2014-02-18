require 'capistrano/recipes/deploy/scm/base'
require 'capistrano/recipes/deploy/scm/git'

module Capistrano
  module Deploy
    module SCM
      class Git < Base
        # Merges the changes to 'head' since the last fetch, for remote_cache
        # deployment strategy
        def sync(revision, destination)
          git     = command
          remote  = origin

          execute = []
          execute << "cd #{destination}"

          # Use git-config to setup a remote tracking branches. Could use
          # git-remote but it complains when a remote of the same name already
          # exists, git-config will just silenty overwrite the setting every
          # time. This could cause wierd-ness in the remote cache if the url
          # changes between calls, but as long as the repositories are all
          # based from each other it should still work fine.
          #
          # Since it's even worse to have the URL be out of date
          # than it is to set it too many times, set it every time
          # even for origin.
          execute << "#{git} config remote.#{remote}.url #{variable(:repository)}"
          execute << "#{git} config remote.#{remote}.fetch +refs/heads/*:refs/remotes/#{remote}/*"

          # since we're in a local branch already, just reset to specified revision rather than merge
          execute << "#{git} fetch #{verbose} #{remote} && #{git} fetch --tags #{verbose} #{remote} && #{git} reset #{verbose} --hard #{revision}"

          if variable(:git_enable_submodules)
            execute << "#{git} submodule #{verbose} init"
            execute << "#{git} submodule #{verbose} sync"
            if false == variable(:git_submodules_recursive)
              execute << "#{git} submodule #{verbose} update --init"
            else
              execute << %Q(export GIT_RECURSIVE=$([ ! "`#{git} --version`" \\< "git version 1.6.5" ] && echo --recursive))
              execute << "#{git} submodule #{verbose} update --init $GIT_RECURSIVE"
            end
          end

          # Make sure there's nothing else lying around in the repository (for
          # example, a submodule that has subsequently been removed).
          execute << "#{git} clean #{verbose} -d -x -f -f"

          if variable(:git_enable_submodules)
            execute << "#{git} submodule #{verbose} foreach $GIT_RECURSIVE #{git} clean #{verbose} -d -x -f -f"
          end
          execute.join(" && ")
        end
      end
    end
  end
end

