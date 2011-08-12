#
# Cookbook Name:: opscenter
# Recipe:: create_seed_list
#
# Copyright 2011, DataStax
#
# Apache License
#

###################################################
# 
# Build the Seed List
# 
###################################################

# Only dynamically create the seed list if the list was not provided
if not node[:opscenter][:seed_list]
  # Find the total number of nodes with this cluster_role
  cluster_nodes = search(:node, "roles:#{node[:setup][:cluster_role]}")

  # Find all cluster node IP addresses
  cluster_nodes_array = []
  for i in (0..cluster_nodes.count-1)
    cluster_nodes_array << [ cluster_nodes[i][:ohai_time], cluster_nodes[i][:cloud][:private_ips].first ]
    break if (i > 3)
  end
  cluster_nodes_array = cluster_nodes_array.sort_by{|node| node[0]}
  Chef::Log.info "Currently seen nodes: #{cluster_nodes_array.inspect}"

  # Separate the seeds into one a list of just seeds
  seeds = []
  cluster_nodes_array.each do |node| 
    seeds << node[1]
  end

  # Join by commas
  node[:opscenter][:seed_list] = seeds.join(",")
end
