#!/bin/sh
set -eu

/usr/sbin/sshd
exec apache2-foreground
