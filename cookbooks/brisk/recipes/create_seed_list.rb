#
# Cookbook Name:: brisk
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

# Calculate the seed list if not currently set
if not node[:cassandra][:seed]
  
  # Find the position of the current node in the ring
  cluster_nodes = search(:node, "roles:#{node[:setup][:current_role]}")
  if node[:cassandra][:token_position] == false
    node[:cassandra][:token_position] = cluster_nodes.count
  end

  # Find all cluster node IP addresses
  cluster_nodes_array = []
  for i in (0..cluster_nodes.count-1)
    cluster_nodes_array << [ cluster_nodes[i][:ohai_time], cluster_nodes[i][:cloud][:private_ips].first ]
  end
  cluster_nodes_array = cluster_nodes_array.sort_by{|node| node[0]}
  Chef::Log.info "Currently seen nodes: #{cluster_nodes_array.inspect}"

  seeds = []

  # Pull the seeds from the chef db
  if cluster_nodes.count == 0

    # Add this node as a seed since this is the first node
    Chef::Log.info "[SEEDS] First node chooses itself."
    seeds << node[:cloud][:private_ips].first
  else
    
    # Add the first node as a seed
    Chef::Log.info "[SEEDS] Add the first node."
    seeds << cluster_nodes_array[0][1]

    # Add this node as a seed since this is the first tasktracker node
    if cluster_nodes.count == node[:brisk][:vanilla_nodes]
      Chef::Log.info "[SEEDS] Add this node since it's the first TaskTracker node."
      seeds << node[:cloud][:private_ips].first
    end

    # Add the first node in the second DC
    if (cluster_nodes.count > node[:brisk][:vanilla_nodes]) and !(node[:brisk][:vanilla_nodes] == 0)
      Chef::Log.info "[SEEDS] Add the first node of DC2."
      seeds << cluster_nodes_array[Integer(node[:brisk][:vanilla_nodes])][1]
    end
  end
  node[:cassandra][:seed] = seeds.join(",")
end

Chef::Log.info "[SEEDS] Chosen seeds: " << seeds.inspect

