#
# Cookbook Name:: ycsb
# Recipe:: default
#
# Copyright 2011, DataStax
#
# Apache License
#

###################################################
# 
# Public Variable Declarations
# 
###################################################

# Find the position of the current node in the ring
cluster_nodes = search(:node, "role:#{node[:cassandra][:current_role]}")

# Find all cluster node IP addresses
cluster_nodes_array = []
for i in (0..cluster_nodes.count-1)
  # cluster_nodes_array << [ cluster_nodes[i][:cloud][:local_hostname], cluster_nodes[i][:cloud][:private_ips].first ]
  cluster_nodes_array << cluster_nodes[i][:cloud][:private_ips].first
end
Chef::Log.info "Currently seen nodes: #{cluster_nodes_array.inspect}"


###################################################
# 
# Setup Repositories
# 
###################################################

package "git"
package "ant"
execute "git clone git://github.com/yourabi/YCSB.git"

###################################################
# 
# Install YCSB
# 
###################################################

execute "cd YCSB"
execute "ant"

###################################################
# 
# Remove the MOTD
# 
###################################################

execute "rm -rf /etc/motd"
execute "touch /etc/motd"


###################################################
# 
# Creating RAID0
# Insert optional personalized RAID code here
# 
###################################################


###################################################
# 
# Additional Code
# 
###################################################

# execute 'echo "export JAVA_HOME=/usr/lib/jvm/java-6-sun" | sudo -E tee -a ~/.bashrc'
# execute 'echo "export JAVA_HOME=/usr/lib/jvm/java-6-sun" | sudo -E tee -a ~/.profile'
# execute 'sudo bash -c "ulimit -n 32768"'
# execute 'echo 1 | sudo tee /proc/sys/vm/overcommit_memory'
# execute 'echo "* soft nofile 32768" | sudo tee -a /etc/security/limits.conf'
# execute 'echo "* hard nofile 32768" | sudo tee -a /etc/security/limits.conf'

###################################################
# 
# Calculate the Token
# 
###################################################


###################################################
# 
# Build the Seed List
# 
###################################################


###################################################
# 
# Write Configs and Start Services
# 
###################################################


DataStaxWorkload = """
#   Default data size: 1 KB records (10 fields, 100 bytes each, plus key)
#   Request distribution: zipfian

recordcount=1000000
operationcount=1000000
workload=com.yahoo.ycsb.workloads.CoreWorkload

readallfields=true

readproportion=0
updateproportion=0
scanproportion=0
insertproportion=1

requestdistribution=zipfian

#This is a consistent target for Cassandra from another machine pointing to a 6-node cluster.
#target=6000

threadcount=30
columnfamily=data
hosts=localhost

#measurementtype=timeseries
#timeseries.granularity=2000

#fieldlength=500
"""

runScript = """
#!/bin/sh

cat workloads/DataStaxWorkload > DataStaxWorkload-FullInserts.stats
java -cp build/ycsb.jar:db/cassandra-0.7/lib/* com.yahoo.ycsb.Client -db com.yahoo.ycsb.db.CassandraClient7 -P workloads/DataStaxWorkload -s -load >> DataStaxWorkload-FullInserts.stats
grep RunTime DataStaxWorkload-FullInserts.stats
grep Throughput DataStaxWorkload-FullInserts.stats
grep AverageLatency DataStaxWorkload-FullInserts.stats

cat workloads/DataStaxWorkload > DataStaxWorkload-FullReads.stats
java -cp build/ycsb.jar:db/cassandra-0.7/lib/* com.yahoo.ycsb.Client -db com.yahoo.ycsb.db.CassandraClient7 -P workloads/DataStaxWorkload -s -t >> DataStaxWorkload-FullReads.stats
grep RunTime DataStaxWorkload-FullReads.stats
grep Throughput DataStaxWorkload-FullReads.stats
grep AverageLatency DataStaxWorkload-FullReads.stats
"""
