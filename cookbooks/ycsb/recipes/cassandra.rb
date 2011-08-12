#
# Cookbook Name:: ycsb
# Recipe:: cassandra
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
cluster_nodes = search(:node, "roles:#{node[:cassandra][:current_role]}")

# Find all cluster node IP addresses
nodeIPcsv = ""
for i in (0..cluster_nodes.count-1)
  if nodeIPcsv != ""
    nodeIPcsv << ","
  end
  nodeIPcsv << cluster_nodes[i][:cloud][:private_ips].first
end
Chef::Log.info "Currently seen nodes: #{nodeIPcsv}"

firstNode = cluster_nodes[0][:cloud][:private_ips].first

###################################################
# 
# Install Cassandra
# 
###################################################

if node[:cassandra][:deployment] == "07x"
  package "cassandra" do
    notifies :stop, resources(:service => "cassandra"), :immediately
  end
end

if node[:cassandra][:deployment] == "08x"
  case node[:platform]
    when "ubuntu", "debian"
      package "cassandra" do
        notifies :stop, resources(:service => "cassandra"), :immediately
      end
    when "centos", "redhat", "fedora"
      package "cassandra08" do
        notifies :stop, resources(:service => "cassandra08"), :immediately
      end
  end
end

###################################################
# 
# Copy Cassandra Jars
# 
###################################################

# script "copyCassandraJars" do
#   interpreter "bash"
#   user "root"
#   cwd "#{node[:setup][:home]}"
#   code <<-EOH
#   git clone git://github.com/apache/cassandra.git
#   cd cassandra
#   git checkout tags/#{node[:setup][:tag]}
#   ant jar
#   cp build/*.jar #{node[:setup][:home]}/YCSB/db/#{node[:setup][:ycsb_tag]}/lib/
#   cp lib/*.jar #{node[:setup][:home]}/YCSB/db/#{node[:setup][:ycsb_tag]}/lib/
#   EOH
# end

version = "#{node[:setup][:tag]}"
version = version.split("-")
execute "wget http://archive.apache.org/dist/cassandra/#{version[1]}/apache-cassandra-#{version[1]}-bin.tar.gz"
execute "tar xf apache-cassandra*.tar.gz"
execute "mv apache-cassandra-*/ #{node[:setup][:home]}/cassandra/"
execute "cp -r #{node[:setup][:home]}/cassandra/lib/* #{node[:setup][:home]}/YCSB/db/#{node[:setup][:ycsb_tag]}/lib/"

###################################################
# 
# Prepare Cassandra Tests
# 
###################################################

# Build YSCB testing components
execute "buildYCSBModule" do
  command "ant dbcompile-#{node[:setup][:ycsb_tag]}"
  cwd "#{node[:setup][:home]}/YCSB"
end

if node[:cassandra][:deployment] == "07x"
  # Setup Cassandra testing keyspace
  script "setupCassandraTestingCF" do
    interpreter "bash"
    user "root"
    cwd "#{node[:setup][:home]}"
    code <<-EOH
    cassandra-cli -h #{firstNode} <<EOF
    create keyspace usertable 
      with placement_strategy = 'org.apache.cassandra.locator.SimpleStrategy'
      and replication_factor= #{node[:cassandra][:replication_factor]};
    use usertable;
    create column family data with read_repair_chance = 0.0;
  EOF
    EOH
  end
end

if node[:cassandra][:deployment] == "08x"
  # Setup Cassandra testing keyspace
  script "setupCassandraTestingCF" do
    interpreter "bash"
    user "root"
    cwd "#{node[:setup][:home]}"
    code <<-EOH
    cassandra-cli -h #{firstNode} <<EOF
    create keyspace usertable 
      with placement_strategy = 'org.apache.cassandra.locator.SimpleStrategy'
      and strategy_options = [{replication_factor:#{node[:cassandra][:replication_factor]}}];
    use usertable;
    create column family data with read_repair_chance = 0.0;
  EOF
    EOH
  end
end

# Allow the keyspace to propagate to the rest of the cluster
ruby_block "schemaPropagation" do
  block do
    Chef::Log.info "Waiting 10 seconds for Schema propagation..."
    sleep 10
  end
  action :create
end

# Modify the custom Datastax workloads with the appropriate host names
workloads = node[:ycsb][:workloads]
ruby_block "modifyWorkloadWithHosts" do
  block do
    workloads.each do |workloadName|
      filename = "#{node[:setup][:home]}/YCSB/workloads/#{workloadName}"
      workload = File.read(filename)
      workload << "\nhosts=#{nodeIPcsv}\n"
      File.open(filename, 'w') {|f| f.write(workload) }
    end
  end
end

###################################################
# 
# Prime the Cluster and Run Tests (Cassandra)
# 
###################################################

cookbook_file "#{node[:setup][:home]}/ycsb_kicker.sh" do
  source "ycsb_kicker.sh"
  mode "0755"
end

template "#{node[:setup][:home]}/ycsb_tester.sh" do
  source "ycsb_tester.erb"
  mode "0755"
  variables({
    :workload_list => workloads.join(" "),
    :first_node => firstNode,
    :comment_out_nodetool => ""
  })
end

execute "~/ycsb_kicker.sh"

Chef::Log.info "Tests have started running via 'screen'."
