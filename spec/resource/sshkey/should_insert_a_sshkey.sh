#!/usr/bin/env bash

# Author: Cody Herriges

# Checks to see if Puppet's sshkey type inserted
# a key into ssh_known_hosts.

source lib/setup.sh
driver_standalone

# Lets just use this machine's pub key.
HOSTKEY=`cat /etc/ssh/ssh_host_rsa_key.pub | sed s/ssh-rsa\ // | tr -d ' '`

MANIFEST="sshkey { \"test\":
  host_aliases => \"foo\",
  key => \"${HOSTKEY}\",
  type => rsa,
  target => \"/etc/ssh/ssh_known_hosts2\",
  ensure => present
}"

execute_manifest<<MANIFEST_EOF
${MANIFEST}
MANIFEST_EOF

if grep ${HOSTKEY} /etc/ssh/ssh_known_hosts2
  then
    exit ${EXIT_OK}
  else
    exit ${EXIT_FAILURE}
fi
