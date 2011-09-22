maintainer       "DataStax"
maintainer_email "joaquin@datastax.com"
license          "Apache License"
description      "Install and configure Brisk in a multi-node environment"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.1.4"
depends          "apt"
depends          "cassandra"
recipe           "brisk::default", "Runs the full list of scripts needed."
recipe           "brisk::install", "Installs the actual DataStax' Brisk package."
recipe           "brisk::additional_settings", "Additional settings for optimal performance for the cluster."
recipe           "brisk::token_generation", "Generates the token positions for the cluster."
recipe           "brisk::create_seed_list", "Generates the seed lists for the cluster."
recipe           "brisk::write_configs", "Writes the configurations for Brisk."
recipe           "brisk::restart_service", "Restarts the Brisk service."

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

attribute "cassandra/commitlog_dir",
  :display_name => "Cassandra Commit Log Directory",                                                                                                                                                                        
  :description => "The location for the commit log (preferably on it's own drive or RAID0 device)",
  :default => "/var/lib"

attribute "cassandra/data_dir",
  :display_name => "Cassandra Data Directory",                                                                                                                                                                        
  :description => "The location for the data directory (preferably on it's own drive or RAID0 device)",
  :default => "/var/lib"

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

attribute "cassandra/rpc_address",
  :display_name => "Cassandra RPC Address",                                                                                                                                                                        
  :description => "The address to bind the Thrift RPC service to (False sets RPC Address to the private IP)",
  :default => "false"
  
attribute "cassandra/confPath",
  :display_name => "Cassandra Settings Path",                                                                                                                                                                        
  :description => "The path for cassandra.yaml and cassandra-env.sh",
  :default => "/etc/brisk/cassandra/"




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
