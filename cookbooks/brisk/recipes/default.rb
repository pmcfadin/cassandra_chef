#
# Cookbook Name:: brisk
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

# Stop Cassandra and OpsCenter if they are running.
# Different for Debian due to service package.
if node[:platform] == "debian"
  service "cassandra" do
    action :stop
    ignore_failure true
  end

  service "brisk" do
    action :stop
    ignore_failure true
  end

  service "opscenterd" do
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

  service "opscenterd" do
    action :stop
  end
end

# Only for debug purposes
REQUIRED_INSTALL = true
OPTIONAL_INSTALL = true

# Find the position of the current node in the ring
cluster_nodes = search(:node, "role:#{node[:setup][:current_role]}")
if node[:cassandra][:token_position] == false
  node[:cassandra][:token_position] = cluster_nodes.count
end

# Find all cluster node IP addresses
cluster_nodes_array = []
for i in (0..cluster_nodes.count-1)
  cluster_nodes_array << [ cluster_nodes[i][:ohai_time], cluster_nodes[i][:cloud][:private_ips].first ]
end
cluster_nodes_array = cluster_nodes_array.sort_by{|node| node[0]}
Chef::Log.info "Currently seen nodes: #{cluster_nodes_array.inspect}"

# Configure the Cassandra conf directory location
confPath = ""
if node[:setup][:deployment] == "08x" or node[:setup][:deployment] == "07x"
  confPath = "/etc/cassandra/"
elsif node[:setup][:deployment] == "brisk"
  confPath = "/etc/brisk/cassandra/"
end

# Find if OpsCenter will be installed in this chef script
installOpscenter = false
if !(node[:platform] == "fedora")
  if node[:opscenter][:install] and node[:opscenter][:user] and node[:opscenter][:pass] and node[:cassandra][:token_position] == 0
    installOpscenter = true
  end
end

###################################################
# 
# Setup Repositories
# 
###################################################

case node[:platform]
  when "ubuntu", "debian"
    include_recipe "apt"

    # Find package codenames
    codename = ""
    if node[:platform] == "debian"
      if node[:platform_version] == "6.0"
        codename = "squeeze"
      elsif node[:platform_version] == "5.0"
        codename = "lenny"
      end
    else
      codename = node['lsb']['codename']
    end

    # Adds the Cassandra repo:
    # deb http://www.apache.org/dist/cassandra/debian <07x|08x> main
    if node[:setup][:deployment] == "08x" or node[:setup][:deployment] == "07x"
      apt_repository "datastax-repo" do
        uri "http://www.apache.org/dist/cassandra/debian"
        components [node[:setup][:deployment], "main"]
        keyserver "pgp.mit.edu"
        key "2B5C1B00"
        action :add
      end
    end

    # Adds the DataStax repo:
    # deb http://debian.riptano.com/<codename> <codename> main
    apt_repository "datastax-repo" do
      uri "http://debian.datastax.com/" << codename
      distribution codename
      components ["main"]
      key "http://debian.datastax.com/debian/repo_key"
      action :add
    end

    # Adds the Riptano repo:
    # deb http://riptano.riptano.com/<codename> <codename> main
    apt_repository "riptano-repo" do
      uri "http://debian.riptano.com/" << codename
      distribution codename
      components ["main"]
      action :add
    end

    # Add the OpsCenter repo, if user:pass provided
    # deb http://<user>:<pass>@deb.opsc.datastax.com/[free] unstable main
    if node[:opscenter][:user] and node[:opscenter][:pass]
      opsCenterURL = "http://" << node[:opscenter][:user] << ":" << node[:opscenter][:pass]
      if node[:opscenter][:free]
        opsCenterURL << "@deb.opsc.datastax.com/free"
      else
        opsCenterURL << "@deb.opsc.datastax.com/"
      end

      apt_repository "opscenter" do
        uri opsCenterURL
        components ["unstable","main"]
        key "http://opscenter.datastax.com/debian/repo_key"
        action :add
      end
    end

    # Adds the Sun Java repo:
    # deb http://archive.canonical.com lucid partner
    apt_repository "sun-java6-jdk" do
      uri "http://archive.canonical.com"
      distribution "lucid"
      components ["partner"]
      action :add
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

    # Add the OpsCenter Repo, if user:pass provided
    if node[:opscenter][:user] and node[:opscenter][:pass]
      opsCenterURL = "http://" << node[:opscenter][:user] << ":" << node[:opscenter][:pass]
      if node[:opscenter][:free]
        opsCenterURL << "@rpm.opsc.datastax.com/free"
      else
        opsCenterURL << "@rpm.opsc.datastax.com/"
      end

      filename = "/etc/yum.repos.d/opscenter.repo"
      repoFile = "[opscenter]" << "\n" <<
                 "name=DataStax OpsCenter" << "\n" <<
                 "baseurl=" << opsCenterURL << "\n" <<
                 "enabled=1" << "\n" <<
                 "gpgcheck=0" << "\n"
      File.open(filename, 'w') {|f| f.write(repoFile) }
    end

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

    execute "yum clean all"
end


###################################################
# 
# Install the Required Packages
# 
###################################################

if REQUIRED_INSTALL
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
      
      # Install JNA and the LZO compressor for Cassandra and Brisk
      package "libjna-java"
      package "liblzo2-dev"
      
    when "centos", "redhat", "fedora"
      # Ensure all native components are up to date
      execute 'sudo yum -y update'
      execute 'sudo yum -y upgrade'
  end
end

###################################################
# 
# Install Optional Packages
# 
###################################################

if OPTIONAL_INSTALL
  # Addtional optional programs/utilities
  case node[:platform]
    when "ubuntu", "debian"
      package "pssh"
      package "xfsprogs"
      package "maven2"
      package "git-core"

      # Addtional optional program for RAID management
      package "mdadm" do
        options "--no-install-recommends"
        action :install
      end
    when "centos", "redhat", "fedora"
      # Addtional optional program for RAID management
      package "mdadm"
      package "git"
  end

  package "python"
  package "htop"
  package "iftop"
  package "pbzip2"
  package "ant"
  package "emacs"
  package "sysstat"
  package "zip"
  package "unzip"
  package "binutils"
  package "ruby"
  package "openssl"
  package "ant"
  package "curl"
end

###################################################
# 
# Install Cassandra or Brisk [and OpsCenter]
# 
###################################################

# Used to clear any system information that may have
# been created when the service autostarts
execute "clear-data" do
  command "rm -rf /var/lib/cassandra/data/system"
  action :nothing
end

# Installs the latest Cassandra 0.7.x
if node[:setup][:deployment] == "07x"
  package "cassandra" do
    notifies :stop, resources(:service => "cassandra"), :immediately
    notifies :run, resources(:execute => "clear-data"), :immediately
  end
end

# Installs the latest Cassandra 0.8.x
if node[:setup][:deployment] == "08x"
  case node[:platform]
    when "ubuntu", "debian"
      package "cassandra" do
        notifies :stop, resources(:service => "cassandra"), :immediately
        notifies :run, resources(:execute => "clear-data"), :immediately
      end
    when "centos", "redhat", "fedora"
      package "cassandra08" do
        notifies :stop, resources(:service => "cassandra08"), :immediately
        notifies :run, resources(:execute => "clear-data"), :immediately
      end
  end
end

# Installs the latest DataStax' Brisk
if node[:setup][:deployment] == "brisk"
  # Install Brisk
  package "brisk-full" do
    notifies :stop, resources(:service => "brisk"), :immediately
    notifies :run, resources(:execute => "clear-data"), :immediately
  end

  # Install Brisk Demos
  package "brisk-demos" do
    notifies :stop, resources(:service => "brisk"), :immediately
    notifies :run, resources(:execute => "clear-data"), :immediately
  end
end

# Installs the latest OpsCenter
if installOpscenter
  package "opscenter" do
    notifies :stop, resources(:service => "opscenterd"), :immediately
  end
end

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

# A typical setup will want the commit log and data to be on two seperate drives.
# Although for EC2, tests have shown that having the commit log and data on 
# the same RAID0 show better performance.

# mdadm "/dev/md0" do
#   devices [ "/dev/sdb", "/dev/sdc" ]
#   level 0
#   chunk 64
#   action [ :create, :assemble ]
# end

# mount "/raid0/" do
#   device "/dev/md0"
#   fstype "ext3"
# end

###################################################
# 
# Additional Code
# 
###################################################

execute 'echo "export JAVA_HOME=/usr/lib/jvm/java-6-sun" | sudo -E tee -a ~/.bashrc'
execute 'echo "export JAVA_HOME=/usr/lib/jvm/java-6-sun" | sudo -E tee -a ~/.profile'
execute 'echo 1 | sudo tee /proc/sys/vm/overcommit_memory'
execute 'sudo bash -c "ulimit -n 32768"'
execute 'echo "* soft nofile 32768" | sudo tee -a /etc/security/limits.conf'
execute 'echo "* hard nofile 32768" | sudo tee -a /etc/security/limits.conf'
execute 'sync'
execute 'echo 3 > /proc/sys/vm/drop_caches'

# Open ports for communications in Rackspace.
# This is HORRIBLE security. 
# Make sure to properly configure your cluster here.
if node[:cloud][:provider] == "rackspace" and node[:platform] == "centos"
  execute 'sudo service iptables stop' do
    ignore_failure true
  end
end

###################################################
# 
# Calculate the Token
# 
###################################################

if node[:cassandra][:initial_token] == false

  # Write tokentool to a an executable file
  cookbook_file "/tmp/tokentool.py" do
    source "tokentool.py"
    mode "0755"
  end

  # Run tokentool accordingly
  if node[:setup][:deployment] == "08x" or node[:setup][:deployment] == "07x"
    execute "/tmp/tokentool.py #{node[:setup][:cluster_size]} > /tmp/tokens" do
      creates "/tmp/tokens"
    end
  end
  if node[:setup][:deployment] == "brisk"
    execute "/tmp/tokentool.py #{node[:brisk][:vanilla_nodes]} #{node[:setup][:cluster_size] - node[:brisk][:vanilla_nodes]} > /tmp/tokens" do
      creates "/tmp/tokens"
    end
  end

  # Parse tokentool's output
  ruby_block "ReadTokens" do
    block do
      results = []
      open("/tmp/tokens").each do |line|
        results << line.split(':')[1].strip if line.include? 'Node'
      end

      Chef::Log.info "Setting token to be: #{results[node[:cassandra][:token_position]]}"
      node[:cassandra][:initial_token] = results[node[:cassandra][:token_position]]
    end
  end
end

###################################################
# 
# Build the Seed List
# 
###################################################

# Calculate the seed list if not currently set
if node[:cassandra][:seed] == false
  seeds = []

  # Pull the seeds from the chef db
  if cluster_nodes.count == 0

    # Add this node as a seed since this is the first node
    Chef::Log.info "[SEEDS] First node chooses itself."
    seeds << node[:cloud][:private_ips].first
  else
    
    # Add the first node as a seed
    Chef::Log.info "[SEEDS] Add the first node."
    seeds << cluster_nodes_array[0][1]

    if node[:setup][:deployment] == "brisk"
      
      # Add this node as a seed since this is the first tasktracker node
      if cluster_nodes.count == node[:brisk][:vanilla_nodes]
        Chef::Log.info "[SEEDS] Add this node since it's the first TaskTracker node."
        seeds << node[:cloud][:private_ips].first
      end

      # Add the first node in the second DC
      if (cluster_nodes.count > node[:brisk][:vanilla_nodes]) and !(node[:brisk][:vanilla_nodes] == 0)
        Chef::Log.info "[SEEDS] Add the first node of DC2."
        seeds << cluster_nodes_array[Integer(node[:brisk][:vanilla_nodes])][1]
      end
    end

  end
else

  # Parse the seedlist into an array, if provided
  seeds = node[:cassandra][:seed].gsub(/ /,'').split(",")
end

Chef::Log.info "[SEEDS] Chosen seeds: " << seeds.inspect

###################################################
# 
# Write Configs and Start Services
# 
###################################################

execute "sudo mkdir -p #{node[:cassandra][:data_dir]}"
execute "sudo mkdir -p #{node[:cassandra][:commitlog_dir]}"
execute "sudo chown -R cassandra:cassandra #{node[:cassandra][:data_dir]}"
execute "sudo chown -R cassandra:cassandra #{node[:cassandra][:commitlog_dir]}"

if node[:setup][:deployment] == "brisk"
  ruby_block "buildBriskFile" do
    block do
      filename = "/etc/default/brisk"
      briskFile = File.read(filename)
      if node[:cassandra][:token_position] < node[:brisk][:vanilla_nodes]
        briskFile = briskFile.gsub(/HADOOP_ENABLED=1/, "HADOOP_ENABLED=0")
      else
        briskFile = briskFile.gsub(/HADOOP_ENABLED=0/, "HADOOP_ENABLED=1")
      end
      File.open(filename, 'w') {|f| f.write(briskFile) }
    end
    action :create
  end
end

ruby_block "buildCassandraEnv" do
  block do
    filename = confPath + "cassandra-env.sh"
    cassandraEnv = File.read(filename)
    cassandraEnv = cassandraEnv.gsub(/# JVM_OPTS="\$JVM_OPTS -Djava.rmi.server.hostname=<public name>"/, "JVM_OPTS=\"\$JVM_OPTS -Djava.rmi.server.hostname=#{node[:cloud][:private_ips].first}\"")
    File.open(filename, 'w') {|f| f.write(cassandraEnv) }
  end
  action :create
  notifies :run, resources(:execute => "clear-data"), :immediately
end

ruby_block "buildCassandraYaml" do
  block do
    filename = confPath + "cassandra.yaml"
    cassandraYaml = File.read(filename)
    cassandraYaml = cassandraYaml.gsub(/cluster_name:.*/,               "cluster_name: '#{node[:cassandra][:cluster_name]}'")
    cassandraYaml = cassandraYaml.gsub(/initial_token:.*/,              "initial_token: #{node[:cassandra][:initial_token]}")
    cassandraYaml = cassandraYaml.gsub(/\/.*\/cassandra\/data/,         "#{node[:cassandra][:data_dir]}/cassandra/data")
    cassandraYaml = cassandraYaml.gsub(/\/.*\/cassandra\/commitlog/,    "#{node[:cassandra][:commitlog_dir]}/cassandra/commitlog")
    cassandraYaml = cassandraYaml.gsub(/\/.*\/cassandra\/saved_caches/, "#{node[:cassandra][:data_dir]}/cassandra/saved_caches")
    cassandraYaml = cassandraYaml.gsub(/listen_address:.*/,             "listen_address: #{node[:cloud][:private_ips].first}")
    cassandraYaml = cassandraYaml.gsub(/rpc_address:.*/,                "rpc_address: #{node[:cassandra][:rpc_address]}")

    # Cassandra 0.7.x has a slightly different Yaml
    if node[:setup][:deployment] == "07x"
      cassandraYaml = cassandraYaml.gsub(/- 127.0.0.1/,                 "- #{seeds[0]}")
    else
      cassandraYaml = cassandraYaml.gsub(/seeds:.*/,                    "seeds: \"#{seeds.join(",")}\"")
    end
    
    # Change the endpoint_snitch for easier Brisk clustering
    if node[:setup][:deployment] == "brisk"
      cassandraYaml = cassandraYaml.gsub(/endpoint_snitch:.*/,          "endpoint_snitch: #{node[:brisk][:endpoint_snitch]}")
    end
    
    File.open(filename, 'w') {|f| f.write(cassandraYaml) }
  end
  action :create

  # Restart the service
  if node[:setup][:deployment] == "08x" or node[:setup][:deployment] == "07x"
    notifies :restart, resources(:service => "cassandra"), :immediately
  end
  if node[:setup][:deployment] == "brisk"
    notifies :restart, resources(:service => "brisk"), :immediately
  end
end

ruby_block "buildOpscenterdConf" do
  block do
    filename = "/etc/opscenter/opscenterd.conf"
    if File::exists?(filename)
      opscenterdConf = File.read(filename)
      opscenterdConf = opscenterdConf.gsub(/interface =.*/,   "interface = #{node[:opscenter][:interface]}")
      opscenterdConf = opscenterdConf.gsub(/seed_hosts =.*/,  "seed_hosts = #{node[:cloud][:private_ips].first}")
      
      # Cassandra 0.7.x connects under a different port
      if node[:setup][:deployment] == "07x"
        opscenterdConf = opscenterdConf.gsub(/port = 7199/,   "port = #{node[:opscenter][:portin07]}")
      else
        opscenterdConf = opscenterdConf.gsub(/port = 7199/,   "port = #{node[:opscenter][:portin08]}")
      end

      File.open(filename, 'w') {|f| f.write(opscenterdConf) }
    end
  end
  action :create

  # Wait for the cluster to initialize, then start OpsCenter
  if installOpscenter
    Chef::Log.info "Waiting 60 seconds for the cluster to initialize, then start OpsCenter..."
    sleep 60
    notifies :restart, resources(:service => "opscenterd"), :immediately
  end
end

# Print a fedora specific response
ruby_block "OpsCenterResponse" do
  block do
    if node[:opscenter][:user] and node[:opscenter][:pass] and node[:cassandra][:token_position] == 0 and node[:platform] == "fedora"
      Chef::Log.info "Sorry, OpsCenter does not support Fedora."
    end
  end
  action :create
end
