#!/bin/bash

# Author: Cody Herriges

# Checks to see if Puppet's sshkey type modified
# a key into ssh_known_hosts.

set -u

source lib/setup.sh
driver_standalone

# Lets just use this machine's pub key.
HOSTKEY=`cat /etc/ssh/ssh_host_rsa_key.pub | sed s/ssh-rsa\ // | tr -d ' '`

MANIFEST="sshkey { \"test\":
  host_aliases => \"foo\",
  key => \"${HOSTKEY}\",
  type => rsa,
  target => \"/tmp/puppet-$$-standalone/ssh_known_hosts2\",
  ensure => present
}"

execute_manifest<<MANIFEST_EOF
${MANIFEST}
MANIFEST_EOF


if grep ${HOSTKEY} /tmp/puppet-$$-standalone/ssh_known_hosts2
  then
    
    # A different pub key.
    HOSTKEY2=`cat /etc/ssh/ssh_host_dsa_key.pub | sed s/ssh-dsa\ // | tr -d ' '`

    MANIFEST2="sshkey { \"test\":
      host_aliases => \"foo\",
      key => \"${HOSTKEY2}\",
      type => dsa,
      target => \"/tmp/puppet-$$-standalone/ssh_known_hosts2\",
      ensure => present
    }"

execute_manifest<<MANIFEST2_EOF
${MANIFEST2}
MANIFEST2_EOF

    if grep ${HOSTKEY2} /tmp/puppet-$$-standalone/ssh_known_hosts2
      then
        exit ${EXIT_OK}
      else
        exit ${EXIT_FAILURE}
    fi

  else
    exit ${EXIT_FAILURE}
fi
