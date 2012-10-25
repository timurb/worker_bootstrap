#
# This recipe retrieves the config from S3 and passes its values to node[:worker][:config_data] hash
#
require 'yaml'

config_body = get_from_s3( 
                node[:worker][:bucket],
                node[:worker][:remote_path],
                node[:worker][:aws_key],
                node[:worker][:aws_secret_key]
              )

# Set node variables for the further use in Chef
node.set[:worker][:config_data] = YAML.load( config_body )

# ...and create a config file for possible use within worker
file node[:worker][:config_path] do
  action :create
  content config_body
end
