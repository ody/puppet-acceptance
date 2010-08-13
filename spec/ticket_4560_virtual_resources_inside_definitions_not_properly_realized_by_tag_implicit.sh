#!/bin/bash

# Author: Cody Herriges

# Checks on the documented behaviour of all resouces within a colleciton
# are supposed to be implicitly tagged with their collection's title.

set -u
source lib/setup.sh
driver_master_and_agent_locally

PORT=18140

add_cleanup '{ test -n "${master_pid:-}" && kill "${master_pid}" ; }'

# Setting up production and dev environments
mkdir -p /tmp/puppet-$$-master/manifests \
  /tmp/puppet-$$-master/modules \

# Need a puppet.conf in place for modulepath and manifest
PCONF="[master]
  modulepath=/tmp/puppet-$$-master/modules
  manifest=/tmp/puppet-$$-master/manifests/site.pp"

puppet_conf<<PCONF
${PCONF}
PCONF

SITE="node default {
  define mydef { @file { \"/tmp/puppet-$$-agent/foo-\$name\": ensure => directory } }
    mydef { 'foo': }
    File<| tag == 'mydef' |>
}"

cat <<SITE_EOF > "/tmp/puppet-$$-master/manifests/site.pp"
${SITE}
SITE_EOF

# Starting the puppet master
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

puppet agent -t \
  --server localhost --masterport ${PORT} \
  --vardir /tmp/puppet-$$-agent-var \
  --confdir /tmp/puppet-$$-agent \
  --rundir /tmp/puppet-$$-agent

if [ -d /tmp/puppet-$$-agent/foo-foo ]
  then
    exit $EXIT_OK
  else
    exit $EXIT_FAILURE
fi
