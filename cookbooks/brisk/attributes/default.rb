# Needed for the Chef script to function properly
default[:setup][:cluster_size] = 4
default[:setup][:current_role] = "brisk"

# A unique name is preferred to stop the risk of different clusters joining each other
default[:cassandra][:cluster_name] = "Brisk Cluster"

# It is best to have the commit log and the data
# directory on two seperate drives
default[:cassandra][:commitlog_dir] = "/var/lib"
default[:cassandra][:data_dir] = "/var/lib"

# The number of non-task trackers you wish to run
default[:brisk][:vanilla_nodes] = 2


# Advanced Cassandra settings
default[:cassandra][:token_position] = false
default[:cassandra][:initial_token] = false
default[:cassandra][:seed] = false
default[:cassandra][:rpc_address] = false
default[:cassandra][:confPath] = "/etc/brisk/cassandra/"

# Advanced Brisk settings
default[:brisk][:endpoint_snitch] = "org.apache.cassandra.locator.BriskSimpleSnitch"
