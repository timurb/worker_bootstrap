# Worker Bootstrap

This is a set of scripts to fire up an AWS instance with some kind of worker in it.

## Create the AMI

Create instance from ami-c1aaabb5 in the EU-WEST-1 region:
(To get the current uptodate AMI id browse http://cloud-images.ubuntu.com/releases/precise/release/)

    ec2-run-instances ami-c1aaabb5 -t m1.medium --region eu-west-1 --key timur 
You'd better don't use t1.micro as it takes ages (~50min) to build ruby on that size of the box.
When you finish building the AMI you'll be able to reuse the AMI for any size of the box including t1.micro

Login into the instance

    sudo apt-get update && sudo apt-get dist-upgrade -y 
    sudo apt-get install git-core
    sudo apt-get install openjdk-7-jdk
    sudo apt-get install build-essential libyaml-dev libffi-dev libxml2-dev libxslt-dev libz-dev libreadline-dev libssl-dev  # this will be needed for building ruby and some gems

    # become root
    sudo -i

    # install ruby using ruby-build. See https://github.com/sstephenson/ruby-build for reference
    git clone git://github.com/sstephenson/ruby-build.git
    cd ruby-build
    ./install.sh
    ruby-build 1.9.3-p286 /usr/local/ruby-1.9.3-p286  # This takes long. Meanwhile have a cup of tea/coffee.

    # create symlinks to access ruby
    for file in /usr/local/ruby-1.9.3-p286/bin/*; do ln -s $file /usr/local/bin/; done   
    # check that we have correct ruby installed
    ruby -v
    # install gems we need
    gem install --no-rdoc --no-ri bundler chef
    # do symlinks once again to access chef
    for file in /usr/local/ruby-1.9.3-p286/bin/*; do ln -s $file /usr/local/bin/; done   

    # install scripts to bootstrap worker
    git clone https://github.com/timurbatyrshin/worker_bootstrap.git /opt/worker_setup
    # set the AWS access keys and bucket to retrieve config from (optional)
    vim /opt/worker_setup/node.json  
    cp /opt/worker_setup/worker-chef.conf /etc/init  # if you've used some dir other that /opt/worker_setup you'll need to fix that in the file

    ### Before taking a snapshot you need to do some cleaning

    # Remove cloud-init's instance-related data
    rm -rf /var/lib/cloud/* 

    # Cleanup histories
    rm -f {/root,/home/ubuntu}/{.bash_history,.lesshst} 

    # Cleanup logfiles when you need that. Not sure if it is needed and I didn't do that.
    # find /var/log -type f -delete

    # Cleanup SSH keys. Warning! You'll be unable to relogin to the instance after that!
    # Do this only just prior to taking a snapshot.
    rm -rf /home/ubuntu/.ssh/ /root/.ssh/

By now you should have the instance up which will run the worker bootstrap process just after booting.

Take a snapshot of the instance into AMI

    # Adjust AMI name and instance-id and run the command from your local desktop
    ec2-create-image --region=eu-west-1 -n worker-2012-10-28 --no-reboot i-168d005d

After image creation is finished you can terminate the instance used for creation and use that AMI to run your workers.


## Running the worker

To run the instance with worker use the command like the following:

  ec2run ami-f7787b83 -t t1.micro --region=eu-west-1 --key=timur --user-data='http://www.domain.org/path/to/node.json'

You could set config for chef in node.json during the instance creation or you can override those here in user-data by
specifying HTTP URL holding the updated config. Please note that as it holds sensitive information like AWS keys it
should have restricted access.
Example node.json lays beside in this repository.

Take also a look at `worker_bootstrap/attributes/default.rb` as values for node.json could also be defined there.
It is up to you which way of defining those you use.

## Under the cover

To ease possible troubleshooting here is the description of inner workings:

* When instance boots it launches upstart script of worker-chef
* The upstart script launches `/opt/worker_setup/run_chef.sh`
* It downloads the node.json from the URL specified as an instance user-data param and if it is found and is a valid JSON it
  replaces the default node.json lying beside with this updated one.
* Chef-solo is started then which retrieves YAML config for the worker from S3, does bundle install and starts the number
  of workers matching the number of cores. It *requires* bundler binary to be located at `/usr/local/bin/bundle`.

You can find the logs for the process in /var/log/upstart/worker-chef.log

