default[:setup][:home] = "/home/ubuntu"
default[:cassandra][:current_role] = "brisk"

default[:cassandra][:deployment] = "08x"    # Choices are "07x", "08x", or "brisk"
default[:cassandra][:tag] = "cassandra-0.8.2"
default[:cassandra][:ycsb_tag] = "cassandra-0.8"
default[:cassandra][:ycsb_package] = "CassandraClient8"

# default[:cassandra][:deployment] = "07x"    # Choices are "07x", "08x", or "brisk"
# default[:cassandra][:tag] = "cassandra-0.7.8"
# default[:cassandra][:ycsb_tag] = "cassandra-0.7"
# default[:cassandra][:ycsb_package] = "CassandraClient7"

default[:ycsb][:workload] = "DataStaxInsertWorkload"
# default[:ycsb][:workload] = "DataStaxReadWorkload"
# default[:ycsb][:workload] = "DataStaxScanWorkload"
