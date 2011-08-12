#
# Cookbook Name:: opscenter
# Recipe:: write_configs
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

ruby_block "buildOpscenterdConf" do
  block do
    filename = "/etc/opscenter/opscenterd.conf"
    if File::exists?(filename)
      opscenterdConf = File.read(filename)
      opscenterdConf = opscenterdConf.gsub(/interface =.*/,   "interface = #{node[:opscenter][:interface]}")
      opscenterdConf = opscenterdConf.gsub(/seed_hosts =.*/,  "seed_hosts = #{node[:opscenter][:seed_list]}")
      
      # Cassandra 0.7.x connects under a different port
      if node[:setup][:deployment] == "07x"
        opscenterdConf = opscenterdConf.gsub(/port = 7199/,   "port = #{node[:opscenter][:portin07]}")
      else
        opscenterdConf = opscenterdConf.gsub(/port = 7199/,   "port = #{node[:opscenter][:portin08]}")
      end

      File.open(filename, 'w') {|f| f.write(opscenterdConf) }
    end
  end
  action :create
end
