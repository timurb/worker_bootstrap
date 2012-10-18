## Credentials to access S3
# default[:worker][:aws_key] = "AWSKEY"
# default[:worker][:aws_secret_key] = "AWSSECRETKEY"

## S3 location of the config file
#default[:worker][:s3path] = "bucket/path/worker.yaml"

## Location to place the downloaded config file
default[:worker][:config_path] = "/root/worker.yaml"
