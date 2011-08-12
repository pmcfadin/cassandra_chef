#
# Cookbook Name:: opscenter
# Recipe:: setup_repos
#
# Copyright 2011, DataStax
#
# Apache License
#

###################################################
# 
# Setup Repositories
# 
###################################################

case node[:platform]
  when "ubuntu", "debian"

    # Add the OpsCenter repo, if user:pass provided
    # deb http://<user>:<pass>@deb.opsc.datastax.com/[free] unstable main
    if node[:opscenter][:user] and node[:opscenter][:pass]
      opsCenterURL = "http://" << node[:opscenter][:user] << ":" << node[:opscenter][:pass]
      if not node[:opscenter][:production_use]
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
  when "centos", "redhat", "fedora"

    # Add the OpsCenter Repo, if user:pass provided
    if node[:opscenter][:user] and node[:opscenter][:pass]
      opsCenterURL = "http://" << node[:opscenter][:user] << ":" << node[:opscenter][:pass]
      if not node[:opscenter][:production_use]
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

    execute "yum clean all"
end
