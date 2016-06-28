module CapistranoGitFlow
  module Helper

    module ClassMethods
      class << self
        def gitflow_using_cap3?
          defined?(Capistrano::VERSION) && Capistrano::VERSION.to_s.split('.').first.to_i >= 3
        end
      end
    end

    module InstanceMethods


      def gitflow_stage
        original_stage = fetch(:stage)
        original_stage.to_s.include?(":") ? original_stage.split(':').reverse[0] : original_stage
      end

      def gitflow_using_cap3?
        CapistranoGitFlow::Helper::ClassMethods.gitflow_using_cap3?
      end

      def gitflow_callbacks
        if gitflow_using_cap3?
          before "deploy", "gitflow:verify_up_to_date"
        else
          before "deploy:update_code", "gitflow:verify_up_to_date"
        end
        after "gitflow:verify_up_to_date", "gitflow:calculate_tag"
      end

      def gitflow_find_task(name)
        defined?(::Rake) ? ::Rake::Task[name] : exists?(name)
      rescue
        nil
      end

      def gitflow_execute_task(name)
        defined?(::Rake) ?  gitflow_find_task(name).invoke : find_and_execute_task(name)
      end

      def gitflow_capistrano_tag
        defined?(capistrano_configuration) ?  capistrano_configuration[:tag] : ENV['TAG']
      end

      def gitflow_last_tag_matching(pattern)
        # search for most recent (chronologically) tag matching the passed pattern, then get the name of that tag.
        last_tag = `git describe --exact-match  --tags --match='#{pattern}' $(git log --tags='#{pattern}*' -n1 --pretty='%h')`.chomp
        last_tag == '' ? nil : last_tag
      end

      def gitflow_last_staging_tag
        gitflow_last_tag_matching('staging-*')
      end

      def gitflow_ask_confirm(message)
        if gitflow_using_cap3?
          $stdout.print "#{message}"
          $stdin.gets.to_s.chomp
        else
          Capistrano::CLI.ui.ask("#{message}")
        end
      end

      def gitflow_next_staging_tag
        hwhen  = Date.today.to_s
        who = `whoami`.chomp.to_url
        what = ENV['TAG_NAME'] ? ENV['TAG_NAME'] : gitflow_ask_confirm("What does this release introduce? (this will be normalized and used in the tag for this release) ")

        abort "No tag has been provided: #{what.inspect}" if what == ''

        last_staging_tag = gitflow_last_tag_matching("staging-#{hwhen}-*")
        new_tag_serial = if last_staging_tag && last_staging_tag =~ /staging-[0-9]{4}-[0-9]{2}-[0-9]{2}\-([0-9]*)/
          $1.to_i + 1
        else
          1
        end

        "#{gitflow_stage}-#{hwhen}-#{new_tag_serial}-#{who}-#{what.to_url}"
      end

      def gitflow_last_production_tag()
        gitflow_last_tag_matching('production-*')
      end

      def gitflow_using_git?
        fetch(:scm, :git).to_sym == :git
      end


      def gitflow_verify_up_to_date
        if gitflow_using_git?
          set :local_branch, `git branch --no-color 2> /dev/null | sed -e '/^[^*]/d'`.gsub(/\* /, '').chomp
          set :local_sha, `git log --pretty=format:%H HEAD -1`.chomp
          set :origin_sha, `git log --pretty=format:%H #{fetch(:local_branch)} -1`
          unless fetch(:local_sha) == fetch(:origin_sha)
            abort """
            Your #{fetch(:local_branch)} branch is not up to date with origin/#{fetch(:local_branch)}.
            Please make sure you have pulled and pushed all code before deploying:

            git pull origin #{fetch(:local_branch)}
            # run tests, etc
            git push origin #{fetch(:local_branch)}

            """
          end
        end
      end



      def gitflow_calculate_tag
        if gitflow_using_git?
          # make sure we have any other deployment tags that have been pushed by others so our auto-increment code doesn't create conflicting tags
          `git fetch`
          rake_task_name = "gitflow:tag_#{gitflow_stage}"
          task_exists = gitflow_find_task(rake_task_name)
          if !task_exists.nil? && task_exists!= false

            gitflow_execute_task(rake_task_name)

            system "git push --tags origin #{fetch(:local_branch)}"
            if $? != 0
              abort "git push failed"
            end
          else
            puts "Will deploy tag: #{fetch(:local_branch)}"
            set :branch, fetch(:local_branch)
          end
        end
      end

      def gitflow_commit_log
        from_tag = if gitflow_stage.to_s == 'production'
          gitflow_last_production_tag
        elsif gitflow_stage.to_s == 'staging'
          gitflow_last_staging_tag
        else
          abort "Unsupported stage #{gitflow_stage}"
        end

        # no idea how to properly test for an optional cap argument a la '-s tag=x'
        to_tag = gitflow_capistrano_tag
        to_tag ||= begin
          puts "Calculating 'end' tag for :commit_log for '#{gitflow_stage}'"
          to_tag = if  gitflow_stage.to_s == 'production'
            gitflow_last_staging_tag
          elsif gitflow_stage.to_s == 'staging'
            'master'
          else
            abort "Unsupported stage #{gitflow_stage}"
          end
        end



        # use custom compare command if set
        if ENV['git_log_command'] && ENV['git_log_command'].strip != ''
          command = "git #{ENV['git_log_command']} #{from_tag}..#{to_tag}"
        else
          # default compare command
          # be awesome for github
          if `git config remote.origin.url` =~ /git@github.com:(.*)\/(.*).git/
            command = "open https://github.com/#{$1}/#{$2}/compare/#{from_tag}...#{to_tag}"
          else
            command = "git log #{from_tag}..#{to_tag}"
          end
        end
        puts "Displaying commits from #{from_tag} to #{to_tag} via:\n#{command}"
        system command

        puts ""
      end


      def gitflow_tag_staging
        current_sha = `git log --pretty=format:%H HEAD -1`
        last_staging_tag_sha = if gitflow_last_staging_tag
          `git log --pretty=format:%H #{gitflow_last_staging_tag} -1`
        end

        if last_staging_tag_sha == current_sha
          puts "Not re-tagging staging because latest tag (#{gitflow_last_staging_tag}) already points to HEAD"
          new_staging_tag = gitflow_last_staging_tag
        else
          new_staging_tag = gitflow_next_staging_tag
          puts "Tagging current branch for deployment to staging as '#{new_staging_tag}'"
          system "git tag -a -m 'tagging current code for deployment to staging' #{new_staging_tag}"
        end

        set :branch, new_staging_tag
      end


      def gitflow_tag_production
        promote_to_production_tag = gitflow_capistrano_tag || gitflow_last_staging_tag

        unless promote_to_production_tag && promote_to_production_tag =~ /staging-.*/
          abort "Couldn't find a staging tag to deploy; use '-s tag=staging-YYYY-MM-DD.X'"
        end
        unless gitflow_last_tag_matching(promote_to_production_tag)
          abort "Staging tag #{promote_to_production_tag} does not exist."
        end

        promote_to_production_tag =~ /^staging-(.*)$/
        new_production_tag = "production-#{$1}"

        if new_production_tag == gitflow_last_production_tag
          puts "Not re-tagging #{gitflow_last_production_tag} because it already exists"
          really_deploy = gitflow_ask_confirm("Do you really want to deploy #{gitflow_last_production_tag}? [y/N]")

          exit(1) unless really_deploy.to_url =~ /^[Yy]$/
        else
          puts "Preparing to promote staging tag '#{promote_to_production_tag}' to '#{new_production_tag}'"
          gitflow_commit_log
          unless gitflow_capistrano_tag
            really_deploy = gitflow_ask_confirm("Do you really want to deploy #{new_production_tag}? [y/N]")

            exit(1) unless really_deploy.to_url =~ /^[Yy]$/
          end
          puts "Promoting staging tag #{promote_to_production_tag} to production as '#{new_production_tag}'"
          system "git tag -a -m 'tagging current code for deployment to production' #{new_production_tag} #{promote_to_production_tag}"
        end

        set :branch, new_production_tag
      end

      def gitflow_cleanup_tags
        return if fetch(:gitflow_keep_tags).nil?
        tags = `git log --tags  --pretty="format:%at %D" | grep 'tag:' |sort -n | awk '{$1=""; print $0}' | tr "," "\n"| sed 's/tag:*//' | sed -e 's/^[ \t]*//'`
        tags = tags.split.reject{|tag| tag.nil? || tag.empty?  }
        tags = tags.select { |tag| tag =~ /^(staging|production){1}-[0-9]{4}-[0-9]{2}-[0-9]{2}\-([0-9]*)/ }
        if tags.count >= fetch(:gitflow_keep_tags)
          puts "Keeping #{fetch(:gitflow_keep_tags)} Tags from total #{tags.count}"
          tags_to_delete = (tags - tags.last(fetch(:gitflow_keep_tags)))
          if tags_to_delete.any?
            system "git tag -d #{tags_to_delete.join(' ')}"
            tags_with_dots = tags_to_delete.map{ |tag| tag.prepend(':refs/tags/') }.join(' ')
            system "git push origin #{tags_with_dots}"
          else
            puts "No tags to delete"
          end
        else
          puts "No tags to delete"
        end

      end
    end

    def self.included(base)
      base.send(:include, CapistranoGitFlow::Helper::InstanceMethods)
    end

  end
end
