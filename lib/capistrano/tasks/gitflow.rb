
namespace :gitflow do
  include CapistranoGitFlow::Helper
  
  task :verify_up_to_date do
    gitflow_verify_up_to_date
  end

  desc "Calculate the tag to deploy"
  task :calculate_tag do
    gitflow_calculate_tag
  end

  desc "Show log between most recent staging tag (or given tag=XXX) and last production release."
  task :commit_log do
    gitflow_commit_log
  end

  desc "Mark the current code as a staging/qa release"
  task :tag_staging do
    gitflow_tag_staging
  end

  desc "Push the approved tag to production. Pass in tag to deploy with '-s tag=staging-YYYY-MM-DD-X-feature'."
  task :tag_production do
    gitflow_tag_production
  end

  gitflow_callbacks
end

namespace :deploy do
  namespace :pending do
    task :compare do
      gitflow_execute_task("gitflow:commit_log")
    end
  end
end
