#!/usr/bin/env bash

# Author: Cody Herriges

# Validates the use of the mount resource.

set -e
set -u

source lib/setup.sh
driver_standalone

# Creating a filesystem in a flat file for mounting.
mkdir -p /tmp/puppet-$$-standalone/mnt/foo_fs

dd if=/dev/zero of=/tmp/puppet-$$-standalone/foo_fs bs=32MB count=1

mkfs.ext2 -F /tmp/puppet-$$-standalone/foo_fs

# Having puppet mount it.
MANIFEST="mount { \"/tmp/puppet-$$-standalone/mnt/foo_fs\":
  remounts => true,
  options => \"loop\",
  fstype => \"ext2\",
  ensure => mounted,
  device => \"/tmp/puppet-$$-standalone/foo_fs\"
}"

execute_manifest<<MANIFEST_EOF
${MANIFEST}
MANIFEST_EOF

if mount | grep /tmp/puppet-$$-standalone/foo_fs
  then
    exit ${EXIT_OK}
  else
    exit ${EXIT_FAILURE}
fi
