# Needed for the Chef script to function properly
default[:setup][:cluster_size] = 4
default[:setup][:current_role] = "brisk"

# A unique name is preferred to stop the risk of different clusters joining each other
normal[:cassandra][:cluster_name] = "Brisk Cluster"

# It is best to have the commit log and the data
# directory on two seperate drives
normal[:cassandra][:commitlog_dir] = "/var/lib"
normal[:cassandra][:data_dir] = "/var/lib"

# The number of non-task trackers you wish to run
default[:brisk][:vanilla_nodes] = 2


# Advanced Cassandra settings
normal[:cassandra][:token_position] = false
normal[:cassandra][:initial_token] = false
normal[:cassandra][:seed] = false
normal[:cassandra][:rpc_address] = false
normal[:cassandra][:confPath] = "/etc/brisk/cassandra/"

# Advanced Brisk settings
default[:brisk][:endpoint_snitch] = "org.apache.cassandra.locator.BriskSimpleSnitch"
