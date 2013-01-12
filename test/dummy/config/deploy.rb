$:.unshift(File.expand_path('./lib', ENV['rvm_path']))

require 'rvm/capistrano'
require 'bundler/capistrano'

set :rvm_ruby_string, 'ruby-1.9.2-p180'
set :rvm_type, :system
set :bundle_flags, "--deployment"


set :application, "kit"
set :repository,  "git:runmycar"

set :scm, :git

role :web, "kit"                          # Your HTTP server, Apache/etc
role :app, "kit"                          # This may be the same as your `Web` server
role :db,  "kit", :primary => true # This is where Rails migrations will run

task :to_uat do
    set :deploy_to, "/var/webs/kit.dsc.net/testing"
end

task :to_prod do
    set :deploy_to, "/var/webs/kit.dsc.net/production"
end

set :use_sudo, false
set :user, "admin"

task :set_current_release, :roles => :app do
        set :current_release, latest_release
end

namespace(:customs) do
  task :symlink, :roles => :app do
    run <<-CMD
      ln -s #{shared_path}/media #{release_path}/public/images && ln -s #{shared_path}/content #{release_path}/public/images 
    CMD
    end
end


before 'deploy:finalize_update', 'set_current_release'
after "deploy:symlink","customs:symlink"
