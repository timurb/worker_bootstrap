include_recipe "git"

include_recipe "worker_bootstrap::config"   # This recipe sets node[:worker][:config_data]
config = node[:worker][:config_data]

[ config["DATA_PATH"], config["CODE_PATH"] ].each do |dir|
  directory dir do
    owner "root"
    group "root"
    mode "0755"
    action :create
    recursive true
  end
end

git config["CODE_PATH"] do
  repository config["GIT_REPO"]
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
  cwd config["CODE_PATH"]
  action :run
end


node[:cpu][:total].times do
  execute "nohup bundle exec #{config["START_FILE"]} &" do
    cwd config["CODE_PATH"]
    environment config
    action :run
  end
end
