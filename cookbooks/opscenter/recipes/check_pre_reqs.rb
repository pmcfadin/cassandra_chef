#
# Cookbook Name:: brisk
# Recipe:: check_pre_reqs
#
# Copyright 2011, DataStax
#
# Apache License
#

###################################################
# 
# Check Prerequisites for the OpsCenter Chef Script
# 
###################################################

# Find if OpsCenter will be installed in this chef script
if (node[:platform] == "fedora")
    Chef::Application.fatal!("Sorry, OpsCenter does not support Fedora.")
end

if not node[:opscenter][:user] or not node[:opscenter][:pass]
    Chef::Application.fatal!("Sorry, your [:opscenter] attributes are not set correctly and will now exit.")
end
