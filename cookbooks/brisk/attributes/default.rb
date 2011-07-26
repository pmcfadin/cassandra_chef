# Needed for the Chef script to function properly
default[:setup][:cluster_size] = 4
default[:setup][:current_role] = "brisk"

# A unique name is perferred to stop the risk of 
default[:cassandra][:cluster_name] = "Brisk Cluster"

# Brisk settings
default[:brisk][:vanilla_nodes] = 2

# OpsCenter settings
default[:opscenter][:install] = false
default[:opscenter][:user] = false
default[:opscenter][:pass] = false
default[:opscenter][:free] = false


# Advanced Cassandra settings
default[:cassandra][:token_position] = false
default[:cassandra][:initial_token] = false
default[:cassandra][:seed] = false
default[:cassandra][:commitlog_dir] = "/var/lib"
default[:cassandra][:data_dir] = "/var/lib"
default[:cassandra][:rpc_address] = "0.0.0.0"

# Advanced Brisk settings
default[:brisk][:endpoint_snitch] = "org.apache.cassandra.locator.BriskSimpleSnitch"

# Advanced OpsCenter settings
default[:opscenter][:port] = 7199
default[:opscenter][:interface] = "0.0.0.0"
