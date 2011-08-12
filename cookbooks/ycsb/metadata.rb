maintainer       "DataStax"
maintainer_email "joaquin@datastax.com"
license          "Apache License"
description      "Install and configure YCSB for running Cassandra tests. It has been modularized for additional tests."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.1.4"
depends          "apt"
recipe           "ycsb::default", "Currently the only recipe able to run tests. All other recipes work in conjuntion with default."


attribute "setup",
  :display_name => "Setup Configurations",
  :description => "Hash of Setup Configurations",
  :type => "hash"

attribute "setup/home",
  :display_name => "The YCSB home directory",
  :description => "The YCSB home directory where everything will install to",
  :default => "/home/ubuntu"

attribute "setup/test",
  :display_name => "The YCSB test ID",
  :description => "Choices of CassandraClient8, CassandraClient7. Additional settings can be found in $CHEF_HOME/cookbooks/ycsb/recipes/cassandra.rb",
  :default => "CassandraClient8"




attribute "ycsb",
  :display_name => "YCSB Configurations",
  :description => "Hash of YCSB Configurations",
  :type => "hash"

attribute "ycsb/workloads",
  :display_name => "Workloads",
  :description => "The array of workloads to be run. The first workload is run with a preload followed by the test. All others follow only with their test switch.",
  :default => '["DataStaxInsertWorkload", "DataStaxReadWorkload", "DataStaxScanWorkload"]'




attribute "cassandra",
  :display_name => "Cassandra Configurations",
  :description => "Hash of Cassandra Configurations",
  :type => "hash"

attribute "cassandra/replication_factor",
  :display_name => "Cassandra's Replication Factor",
  :description => "Set the replication factor you wish to test Cassandra with",
  :default => "1"

