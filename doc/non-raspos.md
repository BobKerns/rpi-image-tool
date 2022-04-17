# Non-Raspberry Pi OS images

In theory there is no reason this could not mount an arbitrary disk image's partitions. However,
this has knowledge of the specific partitions, e.g. the first partition is the boot partition
and should mount to `/boot`, while the second is the root partition, and no other partitions
are examined.

This could be disabled with a `--flat` command-line option. This could mount each partition under /data/mnt,
i.e. a Raspberry Pi boot image would look like this:

* `/data/mnt/boot`
* `/data/mnt/rootfs`

(The partitions have the labels "boot" and "rootfs").

The `partition-size` command would need to be modified to specifically look for the
last partition as the one to resize, or be modified to use `dd` to actually move later partitions
to make room before resizing the filesystem.

As there are other partition layouts in use (e.g. NOOBS), this may be worth the effort.
