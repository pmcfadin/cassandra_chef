#
# Cookbook Name:: brisk
# Recipe:: install
#
# Copyright 2011, DataStax
#
# Apache License
#

###################################################
# 
# Install Brisk
# 
###################################################

# Used to clear any system information that may have
# been created when the service autostarts
execute "clear-data" do
  command "rm -rf /var/lib/cassandra/data/system"
  action :nothing
end

# Sets up a user to own the data directories
node[:internal][:package_user] = "brisk"

# Installs the latest DataStax' Brisk
# Install Brisk
package "brisk-full" do
  notifies :stop, resources(:service => "brisk"), :immediately
  notifies :run, resources(:execute => "clear-data"), :immediately
end

# Install Brisk Demos
package "brisk-demos" do
  notifies :stop, resources(:service => "brisk"), :immediately
  notifies :run, resources(:execute => "clear-data"), :immediately
end
