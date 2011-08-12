#
# Cookbook Name:: opscenter
# Recipe:: default
#
# Copyright 2011, DataStax
#
# Apache License
#

###################################################
# 
# Public Variable Declarations
# 
###################################################

# Stop Cassandra and OpsCenter if they are running.
# Different for Debian due to service package.
if node[:platform] == "debian"
  service "opscenterd" do
    action :stop
    ignore_failure true
  end
else
  service "opscenterd" do
    action :stop
  end
end

# Only for debug purposes
OPTIONAL_INSTALL = true


include_recipe "opscenter::check_pre_reqs"


include_recipe "cassandra::setup_repos"
include_recipe "opscenter::setup_repos"

include_recipe "cassandra::required_packages"


if OPTIONAL_INSTALL
  include_recipe "opscenter::optional_packages"
end


include_recipe "opscenter::install"





include_recipe "cassandra::additional_settings"





include_recipe "opscenter::create_seed_list"


include_recipe "opscenter::write_configs"


include_recipe "opscenter::restart_service"
