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
nodeIPcsv = ""
for i in (0..cluster_nodes.count-1)
  if nodeIPcsv != ""
    nodeIPcsv << ","
  end
  nodeIPcsv << cluster_nodes[i][:cloud][:private_ips].first
end
Chef::Log.info "Currently seen nodes: #{nodeIPcsv}"


###################################################
# 
# Setup Repositories
# 
###################################################

case node[:platform]
  when "ubuntu", "debian"
    # Ensure all native components are up to date
    execute 'sudo apt-get -y upgrade'

    # Adds the Sun Java repo:
    # deb http://archive.canonical.com lucid partner
    apt_repository "sun-java6-jdk" do
      uri "http://archive.canonical.com"
      distribution "lucid"
      components ["partner"]
      action :add
    end

    # Allow for non-interactive Sun Java setup
    execute 'echo "sun-java6-bin shared/accepted-sun-dlj-v1-1 boolean true" | sudo debconf-set-selections'
    package "sun-java6-jdk"

    # Uninstall other Java Versions
    execute 'sudo update-alternatives --set java /usr/lib/jvm/java-6-sun/jre/bin/java'
    package "openjdk-6-jre-headless" do
      action :remove
    end
    package "openjdk-6-jre-lib" do
      action :remove
    end
    
  when "centos", "redhat", "fedora"
    # Ensure all native components are up to date
    execute 'sudo yum -y update'
    execute 'sudo yum -y upgrade'
end

package "git"
package "ant"
execute "git clone git://github.com/joaquincasares/YCSB.git"

###################################################
# 
# Install YCSB
# 
###################################################

execute "cd YCSB"
execute "ant"

###################################################
# 
# Copy Cassandra Jars
# 
###################################################

execute "git clone git://github.com/apache/cassandra.git"
execute "cd cassandra"
execute "git checkout tags/#{node[:cassandra][:tag]}"
execute "ant jar"
execute "cd lib"
execute "cp *.jar ~/YCSB/db/#{node[:cassandra][:ycsb_tag]}/lib/"

###################################################
# 
# Prepare tests
# 
###################################################

execute "cd ~/YCSB"
execute "ant dbcompile-#{node[:cassandra][:ycsb_tag]}"

cliCommand = "create column family ycsb with replication_factor=3;"
execute "cassandra-cli -h localhost | {#cliCommand}"

ruby_block "schemaPropagation" do
  block do
    Chef::Log.info "Waiting 10 seconds for Schema propagation..."
    sleep 10
  end
  action :create
end

workloads = ["DataStaxInsertWorkload", "DataStaxReadWorkload", "DataStaxScanWorkload"]
workloads.each do |workload|
  cookbook_file "~/YCSB/workloads/{#workload}" do
    source workload
    mode "0644"
  end
end

ruby_block "modifyWorkloadWithHosts" do
  block do
    filename = "~/YCSB/workloads/#{node[:ycsb][:workload]}"
    workload = File.read(filename)
    workload << "\nhosts=#{nodeIPcsv}"
    File.open(filename, 'w') {|f| f.write(workload) }
  end
  action :create
end

###################################################
# 
# Run tests
# 
###################################################

execute "cat workloads/#{node[:ycsb][:workload]} > #{node[:ycsb][:workload]}-load.stats"
execute "cat workloads/#{node[:ycsb][:workload]} > #{node[:ycsb][:workload]}-test.stats"
execute "java -cp build/ycsb.jar:db/#{node[:cassandra][:ycsb_tag]}/lib/* com.yahoo.ycsb.Client -db com.yahoo.ycsb.db.#{node[:cassandra][:ycsb_package]} -P workloads/#{node[:ycsb][:workload]} -s -load >> #{node[:ycsb][:workload]}-load.stats 2>&1"
execute "java -cp build/ycsb.jar:db/#{node[:cassandra][:ycsb_tag]}/lib/* com.yahoo.ycsb.Client -db com.yahoo.ycsb.db.#{node[:cassandra][:ycsb_package]} -P workloads/#{node[:ycsb][:workload]} -s -t    >> #{node[:ycsb][:workload]}-test.stats 2>&1"

###################################################
# 
# Print results
# 
###################################################

Chef::Log.info "RESULTS FOR: #{node[:ycsb][:workload]}-load.stats"
execute "grep RunTime #{node[:ycsb][:workload]}-load.stats"
execute "grep Throughput #{node[:ycsb][:workload]}-load.stats"
execute "grep AverageLatency #{node[:ycsb][:workload]}-load.stats"

Chef::Log.info "RESULTS FOR: #{node[:ycsb][:workload]}-test.stats"
execute "grep RunTime #{node[:ycsb][:workload]}-test.stats"
execute "grep Throughput #{node[:ycsb][:workload]}-test.stats"
execute "grep AverageLatency #{node[:ycsb][:workload]}-test.stats"

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
