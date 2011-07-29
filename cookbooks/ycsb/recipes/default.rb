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

  service "brisk" do
    action :stop
    ignore_failure true
  end

else
  service "cassandra" do
    action :stop
  end

  service "brisk" do
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
    
    # Adds the Cassandra repo:
    # deb http://www.apache.org/dist/cassandra/debian <07x|08x> main
    if node[:cassandra][:deployment] == "08x" or node[:cassandra][:deployment] == "07x":
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

    # Ensure all native components are up to date
    execute "yum clean all"
    execute 'sudo yum -y update'
    execute 'sudo yum -y upgrade'

end

package "git"
package "ant"

# For Thrift building for Cassandra Testings
package "ant"
# package "make"
# package "automake"
# package "libtool"
# package "libboost-dev"
# package "libglib2.0-dev"
# package "libgtk2.0-dev"
# package "libevent-dev"
# package "python-dev"
# package "pkg-config"
# package "libtool"
# package "flex"
# package "bison"
# package "g++"
# package "php5"


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


if node[:cassandra][:deployment] == "07x":
  package "cassandra" do
    notifies :stop, resources(:service => "cassandra"), :immediately
  end
end

if node[:cassandra][:deployment] == "08x":
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

# script "copyThriftJars" do
#   interpreter "bash"
#   user "root"
#   cwd "#{node[:setup][:home]}"
#   code <<-EOH
#   wget -q http://www.apache.org/dist/thrift/0.6.1/thrift-0.6.1.tar.gz
#   tar zxf thrift-*.tar.gz
#   cd thrift*
#   ./configure
#   make
#   sudo make install
#   cd lib/java
#   ant
#   cp build/*.jar #{node[:setup][:home]}/YCSB/db/#{node[:cassandra][:ycsb_tag]}/lib/
#   EOH
# end

###################################################
# 
# Prepare tests
# 
###################################################

execute "buildYCSBModule" do
  command "ant dbcompile-#{node[:cassandra][:ycsb_tag]}"
  cwd "#{node[:setup][:home]}/YCSB"
end

# Setup Cassandra testing keyspace
script "setupCassandraTestingCF" do
  interpreter "bash"
  user "root"
  cwd "#{node[:setup][:home]}"
  code <<-EOH
  cassandra-cli -h #{cluster_nodes[0][:cloud][:private_ips].first} <<EOF
  create keyspace usertable 
    with placement_strategy = 'org.apache.cassandra.locator.SimpleStrategy'
    and strategy_options = [{replication_factor:3}];
  use usertable;
  create column family data;
EOF
  EOH
end

ruby_block "schemaPropagation" do
  block do
    Chef::Log.info "Waiting 10 seconds for Schema propagation..."
    sleep 10
  end
  action :create
end

workloads = ["DataStaxInsertWorkload", "DataStaxReadWorkload", "DataStaxScanWorkload"]
workloads.each do |workload|
  cookbook_file "#{node[:setup][:home]}/YCSB/workloads/" + workload do
    source workload
    mode "0644"
  end
end

ruby_block "modifyWorkloadWithHosts" do
  block do
    filename = "#{node[:setup][:home]}/YCSB/workloads/#{node[:ycsb][:workload]}"
    workload = File.read(filename)
    workload << "\nhosts=#{nodeIPcsv}\n"
    File.open(filename, 'w') {|f| f.write(workload) }
  end
end

###################################################
# 
# Run tests
# 
###################################################

execute "cat ~/YCSB/workloads/#{node[:ycsb][:workload]} > ~/#{node[:ycsb][:workload]}-load.stats"
execute "echo '====================================\n' >> ~/#{node[:ycsb][:workload]}-load.stats"
execute "cat ~/YCSB/workloads/#{node[:ycsb][:workload]} > ~/#{node[:ycsb][:workload]}-test.stats"
execute "echo '====================================\n' >> ~/#{node[:ycsb][:workload]}-test.stats"

execute "runYCSBLoader" do
  command "java -cp build/ycsb.jar:db/#{node[:cassandra][:ycsb_tag]}/lib/* com.yahoo.ycsb.Client -db com.yahoo.ycsb.db.#{node[:cassandra][:ycsb_package]} -P workloads/#{node[:ycsb][:workload]} -s -load >> ~/#{node[:ycsb][:workload]}-load.stats 2>&1"
  cwd "#{node[:setup][:home]}/YCSB"
end

execute "runYCSBTest" do
  command "java -cp build/ycsb.jar:db/#{node[:cassandra][:ycsb_tag]}/lib/* com.yahoo.ycsb.Client -db com.yahoo.ycsb.db.#{node[:cassandra][:ycsb_package]} -P workloads/#{node[:ycsb][:workload]} -s -t    >> ~/#{node[:ycsb][:workload]}-test.stats 2>&1"
  cwd "#{node[:setup][:home]}/YCSB"
end

###################################################
# 
# Print results
# 
###################################################

script "printResults" do
  interpreter "bash"
  user "root"
  cwd "#{node[:setup][:home]}"
  code <<-EOH
  echo "RESULTS FOR: #{node[:ycsb][:workload]}-load.stats"
  grep RunTime #{node[:setup][:home]}/#{node[:ycsb][:workload]}-load.stats
  grep Throughput #{node[:setup][:home]}/#{node[:ycsb][:workload]}-load.stats
  grep AverageLatency #{node[:setup][:home]}/#{node[:ycsb][:workload]}-load.stats
  echo
  echo "RESULTS FOR: #{node[:ycsb][:workload]}-test.stats"
  grep RunTime #{node[:setup][:home]}/#{node[:ycsb][:workload]}-test.stats
  grep Throughput #{node[:setup][:home]}/#{node[:ycsb][:workload]}-test.stats
  grep AverageLatency #{node[:setup][:home]}/#{node[:ycsb][:workload]}-test.stats
  EOH
end

###################################################
# 
# Additional Code
# 
###################################################

execute "chown -R ubuntu:ubuntu ~/"
