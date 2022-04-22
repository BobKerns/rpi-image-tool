#!/bin/bash

# Functions pertaining to disk partitions and filesystems.
# Include this after vars.sh and msgs.sh

# Unmount the specified directory
do_unmount() {
    local dir="${1:?}"
    if [ -e "${dir}" ] &&  grep -q "${dir}" /etc/mtab; then
        sync
	    umount -l -d "${dir}"
	    verbose "${dir} unmounted."
    fi
}

# Delete the loopback devices
do_delete_loop() {
    if [ ! -z "${PI_LOOPDEV}" ]; then
        if [ -e "${PI_LOOPDEV}" ]; then
            kpartx -d "${PI_LOOPDEV}"
        fi
        if [ -e "${PI_LOOPDEV}" ]; then
            # May already have been detached.
            losetup --detach "${PI_LOOPDEV}" 2>/dev/null
        fi
        unset PI_LOOPDEV
        unset PI_BOOTDEV
        unset PI_ROOTDEV
    fi
    losetup -D
    mapfile -t LOOP < <(losetup --list | grep '1  0 /image ' |  cut -d' ' -f1)
    for loop in "${LOOP[@]}"; do
        kpartx -d "${loop}"
    done
}

# Unmount all our directories, and clean up our temporary directory.
do_unmount_all() {
    do_unmount "${PI_BOOT:?}"
    do_unmount "${PI_ROOT:?}"
    sleep 1
    do_delete_loop
}

# Verify that the image has been loaded.
check_image() {
    if [ ! -w "${PI_IMAGE_FILE}" -a -z "${PI_NO_MOUNT}" ]; then
        error "No image file has been provided. Run the image <imagefile> subcommand. $PI_NO_MOUNT"
    fi
}

# Set PI_LOOPDEV, PI_ROOTDEV, and PI_BOOTDEV to the raw devices
# for the whole disk and its root and boot partitions.
find_partitions() {
    check_image
    trap "do_unmount_all" EXIT
    mapfile -t PARTS < <(kpartx -avs "${PI_IMAGE_FILE:?}" | cut -d' ' -f3)
    if [ -z "${PARTS[0]}" ]; then
        error "No partition table in image ${PI_IMAGE_FILE}, perhaps should run ${PI_INVOKER_CMD} image --clear"
    fi
    export PI_BOOTDEV="/dev/mapper/${PARTS[0]}"
    export PI_ROOTDEV="/dev/mapper/${PARTS[1]}"
    export PI_LOOPDEV="/dev/$(echo "${PARTS[0]}" | sed -E 's/p[0-9]+$//')"
    verbose "Found PI_LOOPDEV=${PI_LOOPDEV}"
    verbose "Found PI_ROOTDEV=${PI_ROOTDEV} PI_ROOT=${PI_ROOT}"
    verbose "Found PI_BOOTDEV=${PI_BOOTDEV} PI_BOOT=${PI_BOOT}"
}

# Mount the specified directory on the specified location
# Arrange to clean up if the mount fails.
do_mount() {
    local mapped="${1:?}"
    local mountpoint="${2:?}"
    (
        mkdir -p "${mountpoint}"
        mount -o loop "${mapped}" "${mountpoint}" \
        && verbose "${mapped} mounted on ${mountpoint}"
    ) || (
        msg "${mountpoint} mount failed." 1>&2
        kill -s INT $SELF
    )
}

# Mount our partitions and our temporary work area.
do_mount_all() {
    do_unmount_all
    mkdir -p "${PI_TMP:?}" 2>/dev/null
    verbose "Mounting partitions from ${PI_IMAGE_FILE:?}"
    find_partitions
    do_mount "${PI_ROOTDEV:?}" "${PI_ROOT:?}"
    do_mount "${PI_BOOTDEV:?}" "${PI_BOOT:?}"
}

# Run the appropriae fsck commands on each of the image partitions.
do_fsck() {
    sync
    msg "Checking root ${PI_ROOTDEV}"
    e2fsck -n -f "${PI_ROOTDEV}"

    msg "Checking /boot ${PI_BOOTDEV}"
    dosfsck -wvyV "${PI_BOOTDEV}"
    sync
}
