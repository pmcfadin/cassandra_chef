maintainer       "DataStax"
maintainer_email "joaquin@datastax.com"
license          "Apache License"
description      "Install and configure OpsCenter in a multi-node environment"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.1.4"
depends          "apt"
depends          "cassandra"
recipe           "opscenter::default", "Runs the full list of scripts needed."
recipe           "opscenter::check_pre_reqs", "Check if the current system is supported."
recipe           "opscenter::setup_repos", "Sets up the additional OpsCenter repos."
recipe           "opscenter::optional_packages", "Installs extra tools for OpsCenter maintenance."
recipe           "opscenter::install", "Installs the actual OpsCenter package."
recipe           "opscenter::create_seed_list", "Creates a list of seeds for OpsCenter to latch onto."
recipe           "opscenter::write_configs", "Writes the OpsCenter configurations."
recipe           "opscenter::restart_service", "Restarts the Opscenter service."


attribute "setup",
  :display_name => "Setup Configurations",
  :description => "Hash of Setup Configurations",
  :type => "hash"

attribute "setup/cluster_role",
  :display_name => "The Cluster's Role",
  :description => "The role of the cluster which OpsCenter will oversee",
  :default => "cassandra"




attribute "opscenter",
  :display_name => "OpsCenter",
  :description => "Hash of OpsCenter attributes",
  :type => "hash"
attribute "opscenter/user",
  :display_name => "OpsCenter username",
  :description => "The username given during OpsCenter registration",
  :default => "false"

attribute "opscenter/pass",
  :display_name => "OpsCenter password",
  :description => "The password given during OpsCenter registration",
  :default => "false"

attribute "opscenter/production_use",
  :display_name => "Switch to install production OpsCenter",
  :description => "Installs the production OpsCenter if set to true, if not it installs from the free repo",
  :default => "false"

attribute "opscenter/seed_list",
  :display_name => "OpsCenter seed list",
  :description => "If provided, OpsCenter doesn't search for it's list dynamically",
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
