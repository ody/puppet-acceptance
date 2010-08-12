#!/bin/bash

# Author: Cody Herriges

set -e

source lib/setup.sh
driver_standalone

MANIFEST="exec { 'foo':
  logoutput => true,
  command => 'if [ \"abc\" != \"def\" ]; then touch /tmp/puppet-$$-standalone/foo; fi',
  path => '/bin:/sbin:/usr/bin:/usr/sbin'
  }"

execute_manifest<<MANIFEST_EOF
${MANIFEST}
MANIFEST_EOF

if [ -f /tmp/puppet-$$-standalone/foo ]
  then
    exit ${EXIT_OK}
  else
    exit ${EXIT_FAILURE}
fi
