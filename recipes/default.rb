include_recipe "git"

include_recipe "worker_bootstrap::config"   # This recipe sets node[:worker][:config_data]
config = node[:worker][:config_data]

directory config[:data_path] do
  owner "root"
  group "root"
  mode "0755"
  action :create
  recursive true
end

git config[:code_path] do
  repository config[:git_repo]
  reference 'master'
  action :sync
end

template "/etc/profile.d/worker.sh" do
  source "worker.sh.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(config)
end

execute "bundle install --deployment" do
  cwd config[:code_path]
  action :run
end


node[:cpu][:total].times do
  execute "nohup bundle exec #{config[:start_file]} &" do
    cwd config[:code_path]
    environment config
    action :run
  end
end
