# Needed for the Chef script to function properly
default[:setup][:cluster_role] = "cassandra"

# OpsCenter settings
default[:opscenter][:user] = false
default[:opscenter][:pass] = false
default[:opscenter][:production_use] = false


# Advanced OpsCenter settings
default[:opscenter][:seed_list] = false
default[:opscenter][:portin08] = 7199
default[:opscenter][:portin07] = 8080
default[:opscenter][:interface] = "0.0.0.0"
