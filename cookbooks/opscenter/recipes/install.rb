#
# Cookbook Name:: opscenter
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

# Installs the latest OpsCenter
package "opscenter" do
  notifies :stop, resources(:service => "opscenterd"), :immediately
end
