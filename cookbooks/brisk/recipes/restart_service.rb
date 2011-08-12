#
# Cookbook Name:: brisk
# Recipe:: restart_service
#
# Copyright 2011, DataStax
#
# Apache License
#

###################################################
# 
# Write Configs and Start Services
# 
###################################################

# Restart the service
service "brisk" do
    action :restart
end
