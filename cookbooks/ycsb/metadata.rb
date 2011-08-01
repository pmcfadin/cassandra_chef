maintainer       "DataStax"
maintainer_email "joaquin@datastax.com"
license          "Apache License"
description      "Install and configure Brisk in a multi-node environment"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.1.4"
depends          "apt"
recipe           "ycsb::default", "Currently the only script needed."
