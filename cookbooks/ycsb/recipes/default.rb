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

###################################################
# 
# Call the test switch
# 
###################################################

include_recipe "ycsb::test_switch"

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
    if node[:setup][:test] == "CassandraClient8" or node[:setup][:test] == "CassandraClient7"
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

# Clone and build YCSB
execute "git clone git://github.com/brianfrankcooper/YCSB.git ~/YCSB"
cookbook_file "#{node[:setup][:home]}/YCSB/db/jdbc/src/com/yahoo/ycsb/db/JdbcDBClient.java" do
  source "JdbcDBClient.java"
  mode "0644"
end

execute "ant" do
  command "ant"
  cwd "#{node[:setup][:home]}/YCSB"
end

# Write the Google Charts-YCSB script
cookbook_file "#{node[:setup][:home]}/generateChart.py" do
  source "generateChart.py"
  mode "0755"
end

# Write the custom DataStax workloads out
workloads = node[:ycsb][:workloads]
workloads.each do |workload|
  cookbook_file "#{node[:setup][:home]}/YCSB/workloads/" + workload do
    source workload
    mode "0644"
  end
end

###################################################
# 
# Install and Run Database YCSB Tests
# 
###################################################

include_recipe node[:setup][:ycsb_recipe]

###################################################
# 
# Additional Code
# 
###################################################

execute "rm -rf /etc/motd"
execute "touch /etc/motd"
execute "chown -R ubuntu:ubuntu ~/"
