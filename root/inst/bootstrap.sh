#!/bin/sh

# To bootstrap:
# - Copy everything that is required into ramdisk
# - Relink everything that is required into ramdisk
# - Re-exec script, to get rid of links to /read-only or even /read-write
# - kill all other processes to free access to /read-write
# - umount /read-write
# - exec script

if [ "x$1" != x- ] ; then

    echo "Bootstrapping Phase 1"
    echo "$*"

    mkdir -p /t
    mount -osize=256M,nr_inodes=20000 -t tmpfs /dev/shm /t/
    mkdir /t/lib /t/bin /t/inst
    cp -L /lib/* /t/lib/                                 2>/dev/null
    cp -L /bin/* /sbin/* /usr/bin/* /usr/sbin/* /t/bin/  2>/dev/null
    cp -L /inst/* /t/inst/
    # Not recreating all links in /inst to NOT restart services while in bootstrap mode
    rm -f /inst/*
    for f in /lib/* /inst/dcounter /inst/dia_gauge ; do ln -snf /t/$f /$f 2>/dev/null ; done
    for f in /bin/* /sbin/* /usr/bin/* /usr/sbin/* ; do ln -snf /t/bin/${f##*/} /$f; done

    echo "Re-execing..."
    sleep 1
    exec /t/$0 - "$@"

else

    echo "Bootstrapping Phase 2"
    echo "$*"
    sleep 2

    shift
    script="$1"
    shift

    kill -QUIT -1
    sleep 2
    umount /read-write || mount -oremount,ro /read-write || umount -f /read-write || umount -l /read-write

    echo "Execing $script $*"
    exec /t/$script "$@"

fi

