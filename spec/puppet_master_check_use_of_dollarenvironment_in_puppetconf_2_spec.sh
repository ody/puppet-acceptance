#!/usr/bin/env bash

# Validates the use of $environment varaible used to replace the
# need to declare environements in config files.

set -u
source lib/setup.sh
driver_master_and_agent_locally

PORT=18140

add_cleanup '{ test -n "${master_pid:-}" && kill "${master_pid}" ; }'

# Setting up production and dev environments
mkdir -p /tmp/puppet-$$-master/manifests \
  /tmp/puppet-$$-master/modules/envs/manifests \
  /tmp/puppet-$$-master/modules/envs/lib \
  /tmp/puppet-$$-master/dev/manifests \
  /tmp/puppet-$$-master/dev/modules/envs/manifests \
  /tmp/puppet-$$-master/dev/modules/envs/lib

# Need a puppet.conf in place for modulepath and manifest
pconf="[master]
  modulepath=/tmp/puppet-$$-master/\$environment/modules
  manifest=/tmp/puppet-$$-master/\$environment/manifests/site.pp"

puppet_conf<<PCONF
${pconf}
PCONF

ENVPRO="class envs {
  file { \"/tmp/puppet-$$-agent/env_note_pro\": 
    content => 'A message from production environment' 
  }
}"

ENVDEV="class envs {
  file { \"/tmp/puppet-$$-agent/env_note_dev\":
    content => 'A message from dev environment' 
  }
}"

ENVSITE='node default {
  include envs
}'

cat <<ENVSITE1 > "/tmp/puppet-$$-master/manifests/site.pp"
${ENVSITE}
ENVSITE1

cat <<ENVPRO > "/tmp/puppet-$$-master/modules/envs/manifests/init.pp"
${ENVPRO}
ENVPRO

cat <<ENVSITE2 > "/tmp/puppet-$$-master/dev/manifests/site.pp"
${ENVSITE}
ENVSITE2

cat <<ENVDEV > "/tmp/puppet-$$-master/dev/modules/envs/manifests/init.pp"
${ENVDEV}
ENVDEV

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

puppet agent -t --environment dev \
  --server localhost --masterport ${PORT} \
  --vardir /tmp/puppet-$$-agent-var \
  --confdir /tmp/puppet-$$-agent \
  --rundir /tmp/puppet-$$-agent

puppet agent -t \
  --server localhost --masterport ${PORT} \
  --vardir /tmp/puppet-$$-agent-var \
  --confdir /tmp/puppet-$$-agent \
  --rundir /tmp/puppet-$$-agent

if [ -f /tmp/puppet-$$-agent/env_note_pro -a -f /tmp/puppet-$$-agent/env_note_dev ]
then
  exit $EXIT_OK
else
  exit $EXIT_FAILURE
fi

