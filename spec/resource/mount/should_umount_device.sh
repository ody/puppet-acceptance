#!/bin/bash

# Author: Cody Herriges

# Validates the use of the mount resource.

set -e
set -u

source lib/setup.sh
driver_standalone

# Creating a filesystem in a flat file for mounting.
mkdir -p /tmp/puppet-$$-standalone/mnt/foo_fs

dd if=/dev/zero of=/tmp/puppet-$$-standalone/foo_fs bs=64MB count=1

mkfs.ext2 -F /tmp/puppet-$$-standalone/foo_fs

if ! mount -o loop -t ext2 /tmp/puppet-$$-standalone/foo_fs /tmp/puppet-$$-standalone/mnt/foo_fs
  then
    ${EXIT_NOT_APPLICABLE}
fi

# Having puppet umount it.
MANIFEST="mount { \"/tmp/puppet-$$-standalone/mnt/foo_fs\":
  ensure => unmounted,
}"

execute_manifest<<MANIFEST_EOF
${MANIFEST}
MANIFEST_EOF

if ! mount | grep /tmp/puppet-$$-standalone/mnt/foo_fs
  then
    exit ${EXIT_OK}
  else
    exit ${EXIT_FAILURE}
fi
