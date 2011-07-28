default[:setup][:home] = "/home/ubuntu"
default[:setup][:deployment] = "08x"	# Choices are "07x", "08x", or "brisk"

default[:cassandra][:current_role] = "brisk"
default[:cassandra][:tag] = "cassandra-0.8.2"
default[:cassandra][:ycsb_tag] = "cassandra-0.8"
default[:cassandra][:ycsb_package] = "CassandraClient8"

default[:ycsb][:workload] = "DataStaxInsertWorkload"
