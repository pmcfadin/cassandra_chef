#
# Cookbook Name:: brisk
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

ruby_block "buildBriskFile" do
  block do
    filename = "/etc/default/brisk"
    briskFile = File.read(filename)
    if node[:cassandra][:token_position] < node[:brisk][:vanilla_nodes]
      briskFile = briskFile.gsub(/HADOOP_ENABLED=1/, "HADOOP_ENABLED=0")
    else
      briskFile = briskFile.gsub(/HADOOP_ENABLED=0/, "HADOOP_ENABLED=1")
    end
    File.open(filename, 'w') {|f| f.write(briskFile) }
  end
  action :create
end

ruby_block "buildCassandraYaml" do
  block do
    filename = node[:cassandra][:confPath] + "cassandra.yaml"
    cassandraYaml = File.read(filename)
    
    # Change the endpoint_snitch for easier Brisk clustering
    cassandraYaml = cassandraYaml.gsub(/endpoint_snitch:.*/,          "endpoint_snitch: #{node[:brisk][:endpoint_snitch]}")
    
    File.open(filename, 'w') {|f| f.write(cassandraYaml) }
  end
  action :create
end
