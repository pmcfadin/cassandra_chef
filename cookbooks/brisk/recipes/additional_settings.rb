#
# Cookbook Name:: brisk
# Recipe:: additional_settings
#
# Copyright 2011, DataStax
#
# Apache License
#

###################################################
# 
# Additional Settings
# 
###################################################

execute 'sudo bash -c "echo 1 > /proc/sys/vm/overcommit_memory"'
