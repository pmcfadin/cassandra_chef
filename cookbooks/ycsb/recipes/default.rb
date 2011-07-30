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

# Declare applications
if node[:platform] == "debian"
  service "cassandra" do
    action :stop
    ignore_failure true
  end
else
  service "cassandra" do
    action :stop
  end
end

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

firstNode = cluster_nodes[0][:cloud][:private_ips].first


###################################################
# 
# Setup Repositories
# 
###################################################

case node[:platform]
  when "ubuntu", "debian"
    # Adds the Sun Java repo:
    # deb http://archive.canonical.com lucid partner
    apt_repository "sun-java6-jdk" do
      uri "http://archive.canonical.com"
      distribution "lucid"
      components ["partner"]
      action :add
    end
    
    # Adds the Cassandra repo:
    # deb http://www.apache.org/dist/cassandra/debian <07x|08x> main
    if node[:cassandra][:deployment] == "08x" or node[:cassandra][:deployment] == "07x"
      apt_repository "datastax-repo" do
        uri "http://www.apache.org/dist/cassandra/debian"
        components [node[:cassandra][:deployment], "main"]
        keyserver "pgp.mit.edu"
        key "2B5C1B00"
        action :add
      end
    end

  when "centos", "redhat", "fedora"
    if node[:platform] == "fedora"
      distribution="Fedora"
    else
      distribution="EL"
    end

    # Add the DataStax Repo
    platformMajor = node[:platform_version].split(".")[0]
    filename = "/etc/yum.repos.d/datastax.repo"
    repoFile = "[datastax]" << "\n" <<
               "name=DataStax Repo for Apache Cassandra" << "\n" <<
               "baseurl=http://rpm.datastax.com/#{distribution}/#{platformMajor}" << "\n" <<
               "enabled=1" << "\n" <<
               "gpgcheck=0" << "\n"
    File.open(filename, 'w') {|f| f.write(repoFile) }

    # Install EPEL (Extra Packages for Enterprise Linux) repository
    platformMajor = node[:platform_version].split(".")[0]
    epelInstalled = File::exists?("/etc/yum.repos.d/epel.repo") or File::exists?("/etc/yum.repos.d/epel-testing.repo")
    if !epelInstalled
      case platformMajor
        when "6"
          execute "sudo rpm -Uvh http://download.fedora.redhat.com/pub/epel/6/#{node[:kernel][:machine]}/epel-release-6-5.noarch.rpm"
        when "5"
          execute "sudo rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/#{node[:kernel][:machine]}/epel-release-5-4.noarch.rpm"
        when "4"
          execute "sudo rpm -Uvh http://download.fedora.redhat.com/pub/epel/4/#{node[:kernel][:machine]}/epel-release-4-10.noarch.rpm"
      end
    end
end

###################################################
# 
# Install System Packages
# 
###################################################

case node[:platform]
  when "ubuntu", "debian"
    # Ensure all native components are up to date
    execute 'sudo apt-get -y upgrade'

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
      execute "yum clean all"
      execute 'sudo yum -y update'
      execute 'sudo yum -y upgrade'
end

package "git"
package "ant"

###################################################
# 
# Install YCSB
# 
###################################################

execute "git clone git://github.com/joaquincasares/YCSB.git ~/YCSB"
execute "ant" do
  command "ant"
  cwd "#{node[:setup][:home]}/YCSB"
end

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

script "copyCassandraJars" do
  interpreter "bash"
  user "root"
  cwd "#{node[:setup][:home]}"
  code <<-EOH
  git clone git://github.com/apache/cassandra.git
  cd cassandra
  git checkout tags/#{node[:cassandra][:tag]}
  ant jar
  cp build/*.jar #{node[:setup][:home]}/YCSB/db/#{node[:cassandra][:ycsb_tag]}/lib/
  cp lib/*.jar #{node[:setup][:home]}/YCSB/db/#{node[:cassandra][:ycsb_tag]}/lib/
  EOH
end

###################################################
# 
# Prepare tests
# 
###################################################

# Build YSCB testing components
execute "buildYCSBModule" do
  command "ant dbcompile-#{node[:cassandra][:ycsb_tag]}"
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
      and replication_factor= 3; 
    use usertable;
    create column family data;
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
      and strategy_options = [{replication_factor:3}];
    use usertable;
    create column family data;
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

# Write the custom DataStax workloads out
workloads = node[:ycsb][:workloads]
workloads.each do |workload|
  cookbook_file "#{node[:setup][:home]}/YCSB/workloads/" + workload do
    source workload
    mode "0644"
  end
end

# Modify the custom Datastax workloads with the appropriate host names
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
# Prime the cluster
# 
###################################################

# Output the workload and starting ring information to a stats file
execute "echo 'Testing #{node[:cassandra][:tag]} with YCSB:#{node[:cassandra][:ycsb_tag]}' > ~/DataStaxWorkload-load.stats"
execute "cat ~/YCSB/workloads/DataStaxInsertWorkload >> ~/DataStaxWorkload-load.stats"
execute "echo '====================================\n' >> ~/DataStaxWorkload-load.stats"
execute "nodetool -h #{firstNode} ring >> ~/DataStaxWorkload-load.stats"
execute "echo '====================================\n' >> ~/DataStaxWorkload-load.stats"

# Run the preload
execute "runYCSBLoader" do
  command "java -cp build/ycsb.jar:db/#{node[:cassandra][:ycsb_tag]}/lib/* com.yahoo.ycsb.Client -db com.yahoo.ycsb.db.#{node[:cassandra][:ycsb_package]} -P workloads/DataStaxInsertWorkload -s -load >> ~/DataStaxWorkload-load.stats 2>&1"
  cwd "#{node[:setup][:home]}/YCSB"
end

# Output the ring information to a stats file
execute "echo '====================================\n' >> ~/DataStaxWorkload-load.stats"
execute "nodetool -h #{firstNode} ring >> ~/DataStaxWorkload-load.stats"

# Print results
execute "echo 'RESULTS FOR: DataStaxWorkload-load.stats' | tee ~/DataStaxWorkload-load-results.stats"
execute "grep RunTime #{node[:setup][:home]}/DataStaxWorkload-load.stats | tee -a ~/DataStaxWorkload-load-results.stats"
execute "grep Throughput #{node[:setup][:home]}/DataStaxWorkload-load.stats | tee -a ~/DataStaxWorkload-load-results.stats"
execute "grep AverageLatency #{node[:setup][:home]}/DataStaxWorkload-load.stats | tee -a ~/DataStaxWorkload-load-results.stats"

###################################################
# 
# Run tests
# 
###################################################

workloads.each do |workload|
  # Output the workload and starting ring information to a stats file
  execute "echo 'Testing #{node[:cassandra][:tag]} with YCSB:#{node[:cassandra][:ycsb_tag]}:#{workload}' > ~/#{workload}-test.stats"
  execute "cat ~/YCSB/workloads/#{workload} >> ~/#{workload}-test.stats"
  execute "echo '====================================\n' >> ~/#{workload}-test.stats"
  execute "nodetool -h #{firstNode} ring >> ~/#{workload}-test.stats"
  execute "echo '====================================\n' >> ~/#{workload}-test.stats"

  # Run the preload
  execute "runYCSBTest" do
    command "java -cp build/ycsb.jar:db/#{node[:cassandra][:ycsb_tag]}/lib/* com.yahoo.ycsb.Client -db com.yahoo.ycsb.db.#{node[:cassandra][:ycsb_package]} -P workloads/#{workload} -s -t    >> ~/#{workload}-test.stats 2>&1"
    cwd "#{node[:setup][:home]}/YCSB"
  end

  # Output the ring information to a stats file
  execute "echo '====================================\n' >> ~/#{workload}-test.stats"
  execute "nodetool -h #{firstNode} ring >> ~/#{workload}-test.stats"

  # Print results
  execute "echo 'RESULTS FOR: #{workload}-test.stats' | tee -a ~/DataStaxWorkload-test-results-full.stats | tee -a ~/DataStaxWorkload-test-results.stats"
  execute "grep RunTime #{node[:setup][:home]}/#{workload}-test.stats | tee -a ~/DataStaxWorkload-test-results-full.stats | tee -a ~/DataStaxWorkload-test-results.stats"
  execute "grep Throughput #{node[:setup][:home]}/#{workload}-test.stats | tee -a ~/DataStaxWorkload-test-results-full.stats | tee -a ~/DataStaxWorkload-test-results.stats"
  execute "grep AverageLatency #{node[:setup][:home]}/#{workload}-test.stats | tee -a ~/DataStaxWorkload-test-results-full.stats"
end

###################################################
# 
# Print results
# 
###################################################

execute "cat ~/DataStaxWorkload-test-results.stats"

###################################################
# 
# Additional Code
# 
###################################################

execute "chown -R ubuntu:ubuntu ~/"
