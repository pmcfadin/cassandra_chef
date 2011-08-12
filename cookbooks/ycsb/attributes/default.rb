default[:setup][:home] = "/home/ubuntu"

# Choices of CassandraClient8, CassandraClient7
default[:setup][:test] = "CassandraClient8"


default[:ycsb][:workloads] = ["DataStaxInsertWorkload", "DataStaxReadWorkload", "DataStaxScanWorkload"]

default[:cassandra][:replication_factor] = 1
