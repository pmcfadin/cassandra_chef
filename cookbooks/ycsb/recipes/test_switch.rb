#
# Cookbook Name:: ycsb
# Recipe:: test_switch
#
# Copyright 2011, DataStax
#
# Apache License
#

###################################################
# 
# Variable Declarations for Different Tests
# 
###################################################

if "#{node[:setup][:test]}" == "CassandraClient8"
  node[:setup][:tag] = "cassandra-0.8.2"
  node[:setup][:ycsb_tag] = "cassandra-0.8"
  node[:setup][:ycsb_package] = "CassandraClient8"
  node[:setup][:additional_cp] = ""
  node[:setup][:additional_properties] = ""
  node[:setup][:ycsb_recipe] = "ycsb::cassandra"

  node[:cassandra][:current_role] = "cassandra"
  node[:cassandra][:deployment] = "08x"

elsif "#{node[:setup][:test]}" == "CassandraClient7"
  node[:setup][:tag] = "cassandra-0.7.8"
  node[:setup][:ycsb_tag] = "cassandra-0.7"
  node[:setup][:ycsb_package] = "CassandraClient7"
  node[:setup][:additional_cp] = ""
  node[:setup][:additional_properties] = ""
  node[:setup][:ycsb_recipe] = "ycsb::cassandra"

  node[:cassandra][:current_role] = "cassandra07"
  node[:cassandra][:deployment] = "07x"

end
