#!/bin/sh

# Author: Cody Herriges

# Tests the functionality of the network_interface resource

source lib/setup.sh
driver_master_and_agent_locally

set -u

PORT=18140

add_cleanup '{ test -n "${master_pid:-}" && kill "${master_pid}" ; }'

mkdir -p /tmp/puppet-$$-master/manifests
mkdir -p /tmp/puppet-$$-master/modules
ln -s ${PWD}/../puppet-network /tmp/puppet-$$-master/modules/puppet-network

pconf="[master]
  modulepath=/tmp/puppet-$$-master/modules
  manifest=/tmp/puppet-$$-master/manifests/site.pp
  pluginsync=true
[agent]
  pluginsync=true"

puppet_conf<<PCONF
${pconf}
PCONF

SITEPP='node default {
  include puppet-network
}'

manifest_file site.pp <<SITE_EOF
${SITEPP}
SITE_EOF

#Starting the puppet master
puppet master \
  --vardir /tmp/puppet-$$-master-var \
  --confdir /tmp/puppet-$$-master \
  --rundir /tmp/puppet-$$-master \
  --no-daemonize --autosign=true \
  --verbose --debug --color false \
  --certname=localhost --masterport ${PORT:-18140} &
master_pid=$!
# Wait on master port to be available.
wait_until_master_is_listening $master_pid

puppet agent -t --debug --verbose \
  --server localhost --masterport ${PORT} \
  --vardir /tmp/puppet-$$-agent-var \
  --confdir /tmp/puppet-$$-agent \
  --rundir /tmp/puppet-$$-agent
