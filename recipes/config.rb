#
# This class retrieves the config from S3 and passes its values to node[:worker][:config_data] hash
#

# Place the AWS Credentials to place
if node[:worker][:aws_key] && node[:worker][:aws_secret_key]
  template "/root/awssecrets" do
    action :create_if_missing
    mode "0600"
    source "awssecrets.erb"
    variables ({
      :aws_key        => node[:worker][:aws_key],
      :aws_secret_key => node[:worker][:aws_secret_key]
    })
  end
else
  Chef::Log.warn("No aws_key or aws_secret_key specified")
end

##### The following could be done by means of ruby but that will require installing additional gems

# A tool to access S3
cookbook_file "/usr/local/bin/aws" do
  action :create_if_missing
  source "aws"
  mode "0755"
end

execute "retrieve config" do
  action :run
  command "/usr/local/bin/aws get --secrets-file=/root/awssecrets #{node[:worker][:s3path]} #{node[:worker][:config_path]}"
  creates node[:worker][:config_path]
end


# Load data from the config to use it in configuration later

require 'yaml'

config = YAML.load( File.open( node[:worker][:config_path] ))
node.set[:worker][:config_data] = config
