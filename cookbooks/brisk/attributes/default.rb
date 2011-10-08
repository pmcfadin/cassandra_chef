# Needed for the Chef script to function properly
set[:setup][:cluster_size] = 4
set[:setup][:current_role] = "brisk"

# A unique name is preferred to stop the risk of different clusters joining each other
set[:cassandra][:cluster_name] = "Brisk Cluster"

# It is best to have the commit log and the data
# directory on two seperate drives
set[:cassandra][:commitlog_dir] = "/var/lib"
set[:cassandra][:data_dir] = "/var/lib"

# The number of non-task trackers you wish to run
default[:brisk][:vanilla_nodes] = 2


# Advanced Cassandra settings
set[:cassandra][:token_position] = false
set[:cassandra][:initial_token] = false
set[:cassandra][:seed] = false
set[:cassandra][:rpc_address] = false
set[:cassandra][:confPath] = "/etc/brisk/cassandra/"

# Advanced Brisk settings
set[:brisk][:endpoint_snitch] = "org.apache.cassandra.locator.BriskSimpleSnitch"
