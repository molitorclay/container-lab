#!/bin/bash
TARGET=/home/jerry/lab/Ch/alpine
sudo unshare --mount --pid --fork bash -c "
  mount --make-rprivate /
  mount --bind $TARGET $TARGET
  mount -t proc  proc   $TARGET/proc
  mount -t sysfs sysfs  $TARGET/sys
  mount --bind   /dev   $TARGET/dev
  mkdir -p $TARGET/.old_root
  pivot_root $TARGET $TARGET/.old_root
  exec /bin/ash -c '/bin/umount -l /.old_root; /bin/rmdir /.old_root; exec /bin/ash -l'
"
