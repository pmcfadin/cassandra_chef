maintainer       "DataStax"
maintainer_email "joaquin@datastax.com"
license          "Apache License"
description      "Install and configure Brisk in a multi-node environment"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.1.4"
depends          "apt"
recipe           "brisk::default", "Currently the only script needed."

attribute "setup",
  :display_name => "Setup Configurations",
  :description => "Hash of Setup Configurations",
  :type => "hash"

attribute "setup/cluster_size",
  :display_name => "Cluster Size",
  :description => "Total number of nodes in the cluster",
  :default => "4"

attribute "setup/current_role",
  :display_name => "Current Role Being Assigned",
  :description => "The role that the cluster is being assigned",
  :default => "brisk"




attribute "cassandra",
  :display_name => "Cassandra",
  :description => "Hash of Cassandra attributes",
  :type => "hash"

attribute "cassandra/cluster_name",
  :display_name => "Cassandra Cluster Name",
  :description => "Keeps clusters together, not allowing servers from other clusters to talk",
  :default => "Cassandra Cluster"

attribute "cassandra/token_position",
  :display_name => "Cassandra Initial Token Position",
  :description => "For use when adding a node that may have previously failed or been destroyed",
  :default => "false"

attribute "cassandra/initial_token",
  :display_name => "Cassandra Initial Token",
  :description => "The standard initial token",
  :default => "false"

attribute "cassandra/seed",
  :display_name => "Cassandra Seed Server",                                                                                                                                                                        
  :description => "The comma seperated list of seeds (Make sure to include one seed from each datacenter minimum)",
  :default => "false"

attribute "cassandra/commitlog_dir",
  :display_name => "Cassandra Commit Log Directory",                                                                                                                                                                        
  :description => "The location for the commit log (preferably on it's own drive or RAID0 device)",
  :default => "/var/lib"

attribute "cassandra/data_dir",
  :display_name => "Cassandra Data Directory",                                                                                                                                                                        
  :description => "The location for the data directory (preferably on it's own drive or RAID0 device)",
  :default => "/var/lib"

attribute "cassandra/rpc_address",
  :display_name => "Cassandra RPC Address",                                                                                                                                                                        
  :description => "The address to bind the Thrift RPC service to",
  :default => "0.0.0.0"




attribute "brisk",
  :display_name => "Brisk",
  :description => "Hash of Brisk attributes",
  :type => "hash"

attribute "setup/vanilla_nodes",
  :display_name => "Number of Vanilla Nodes",
  :description => "Number of nodes that will start up vanilla Cassandra",
  :default => "2"

attribute "brisk/endpoint_snitch",
  :display_name => "Brisk Endpoint Snitch",                                                                                                                                                                        
  :description => "How Cassandra knows your network topology to route requests efficiently",
  :default => "org.apache.cassandra.locator.BriskSimpleSnitch"




attribute "opscenter",
  :display_name => "OpsCenter",
  :description => "Hash of OpsCenter attributes",
  :type => "hash"

attribute "opscenter/install",
  :display_name => "Switch to install OpsCenter",
  :description => "Installs OpsCenter if set to true",
  :default => "false"

attribute "opscenter/user",
  :display_name => "OpsCenter username",
  :description => "The username given during OpsCenter registration",
  :default => "false"

attribute "opscenter/pass",
  :display_name => "OpsCenter password",
  :description => "The password given during OpsCenter registration",
  :default => "false"

attribute "opscenter/free",
  :display_name => "Switch to install free OpsCenter",
  :description => "Installs free OpsCenter if set to true, if not it installs from the paid repo",
  :default => "false"

attribute "opscenter/portin08",
  :display_name => "OpsCenter Port in Cassandra 0.8",
  :description => "The port that OpsCenter uses to connect to Cassandra",
  :default => "7199"

attribute "opscenter/portin07",
  :display_name => "OpsCenter Port in Cassandra 0.7",
  :description => "The port that OpsCenter uses to connect to Cassandra",
  :default => "8080"

attribute "opscenter/interface",
  :display_name => "OpsCenter Interface",
  :description => "The interface accessible via your browser",
  :default => "0.0.0.0"
