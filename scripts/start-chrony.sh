#!/usr/bin/env bash
set -E -e -o pipefail

chrony_config="/data/chrony/chrony.conf"
chrony_pid_file="/var/run/chrony/chronyd.pid"

set_umask() {
    # Configure umask to allow write permissions for the group by default
    # in addition to the owner.
    umask 0002
}

start_chrony() {
    echo "Starting Chrony ..."
    echo

    rm -f ${chrony_pid_file:?}
    exec /usr/sbin/chronyd \
        -d \
        -f /data/chrony/chrony.conf \
        -u chrony \
        -U \
        -x \
        -4 \
        -L 0
}

set_umask
start_chrony
