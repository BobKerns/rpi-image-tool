#!/bin/bash

# Various utility routines. This is intended to be included in other scripts.

CMD="$0"
export PI_INCLUDES="${PI_INCLUDES:-"$(cd "$(dirname "$0")"; pwd)"}"
export PI_CMDS="${PI_CMDS:-"$(dirname "${PI_INCLUDES}")"}"
DFLT_WDIR="$(dirname "${PI_CMDS}")"
export PI_WORKDIR="${PI_WORKDIR:-"${DFLT_WDIR}"}"
export PI_BUILD="${PI_BUILD:-"${PI_WORKDIR}/build"}"
export PI_TMP="${PI_TMP:-"${PI_BUILD}/tmp"}"
export PI_DATA="${PI_DATA:-"${PI_WORKDIR}/data"}"
export PI_SAVED="${PI_SAVED:-"${PI_WORKDIR}/saved"}"

export PI_ROOT="${PI_ROOT:-"${PI_BUILD}/root"}"
export PI_BOOT="${PI_BOOT:-"${PI_ROOT}/boot"}"

export PI_IMAGE_FILE=/work/image
# Should be the same as in rpi-image-tool
export PI_IMAGE_SRC_MOUNT="${PI_IMAGE_SRC_MOUNT-/data/image}"

SELF=$$

export PI_VERBOSE="${PI_VERBOSE}"
export PI_VERBOSE="${PI_DEBUG}"

# Show usage for the current or
usage() {
     local cmd="${1:-"${CMD}"}"
     local script="$(grep -E '^#### |^####$' "${cmd}" | sed -E -e 's/^#### ?/echo "/' -e 's/$/";/')"
     if [ -z "${script}" ]; then
        msg "The script ${cmd} lacks documentation."
        msg "  Subcommand documentation is a set of comments beginning with '#### '."
        msg "  These are stripped of the '#### ', and shell substitutions are performed,"
        msg "  so help text can reference environment variables, etc."
        msg "  Particlarly useful is the PI_INVOKER environment variable, which holds"
        msg "  help for the words prior to the subcommand on the command line."
        exit 0
    else
        eval "${script}" 1>&2
        exit 0
    fi
 }

msg() {
    echo "$@" 1>&2
}

verbose() {
    test ! -z "${PI_VERBOSE}${PI_DEBUG}" && msg "$@"
    return 0
}

debug() {
    test ! -z "${PI_DEBUG}" && msg "$@"
    return 0
}


error() {
    msg ERROR: "$@"
    exit 126
}
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

# Delete our temporary files
do_delete_tmp() {
    if [ -d "${PI_TMP:?}" ]; then
        debug "Removing previous temp ${PI_TMP:?}"
        rm -rf "${PI_TMP:?}" 2>/dev/null
    fi
}

# Unmount all our directories, and clean up our temporary directory.
do_unmount_all() {
    do_delete_tmp
    do_unmount "${PI_BOOT:?}"
    do_unmount "${PI_ROOT:?}"
    sleep 1
    do_delete_loop
}

# Verify that the image has been loaded.
check_image() {
    if [ ! -w "${PI_IMAGE_FILE}" ]; then
        error "No image file has been provided. Run the image <imagefile> subcommand."
    fi
}

# Set PI_LOOPDEV, PI_ROOTDEV, and PI_BOOTDEV to the raw devices
# for the whole disk and its root and boot partitions.
find_partitions() {
    check_image
    trap "do_unmount_all" EXIT
    mapfile -t PARTS < <(kpartx -avs "${PI_IMAGE_FILE:?}" | cut -d' ' -f3)
    export PI_BOOTDEV="/dev/mapper/${PARTS[0]}"
    export PI_ROOTDEV="/dev/mapper/${PARTS[1]}"
    export PI_LOOPDEV="/dev/$(echo "${PARTS[0]}" | sed -E 's/p[0-9]+$//')"
    verbose Found PI_LOOPDEV="${PI_LOOPDEV}"
    verbose Found PI_BOOTDEV="${PI_BOOTDEV}" PI_BOOT="${PI_BOOT}"
    verbose Found PI_ROOTDEV="${PI_ROOTDEV}" PI_ROOT="${PI_ROOT}"
}

# Mount the specified directory on the specified location
# Arrange to clean up if the mount fails.
do_mount() {
    local mapped="${1:?}"
    local mountpoint="${2:?}"
    (
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

do_fsck() {
    sync
    msg "Checking root ${PI_ROOTDEV}"
    e2fsck -n -f "${PI_ROOTDEV}"

    msg "Checking /boot ${PI_BOOTDEV}"
    dosfsck -wvyV "${PI_BOOTDEV}"
    sync
}

# mkktmp dir
# make a directory in our temporary workspace.
# Takes the full relative or absolute path
mktmp() {
    rm -rf "${1:?}" 2>/dev/null
    mkdir -p "${1:?}"
}

# copy file
# copies from data to buildtmp
copy() {
    cp "${PI_DATA}/${1:?}" "${PI_TMP}/$1"
}

copyUntilInternal() {
    local terminator="${1:-## Added}"
     while read line; do
        if [ "$line" = "${terminator}" ]; then
            return 0
        else
            echo "$line"
        fi
    done
}

# Copy everything prior to a specified line.
# This is used to allow scripts to append data,
# but if the script is run again, the data is replaced,
# not endlessly added.
copyUntil() {
    copyUntilInternal "${2-## Added}" <"${PI_ROOT:?}/$1" >"${PI_TMP:?}/$1"
}

# append file
# Appends file from data to the destination (result in buildtmp)
append() {
    cp "${BUILDROOT:?}/${1:?}" "${PI_TMP:?}/${1:?}"
    appendLine "$1" '## Added'
    cat "${PI_DATA:?}/${1:?}" >>"${PI_TMP:?}/${1:?}"
}

# appendLine file line
# Result in buildtmp
appendLine() {
    echo "${2:?}" >>"${PI_TMP:?}/${1:?}"
}

# install file [ perms ]
# Install data from buildtmp area to the real filesystem
install() {
    local file="${1:?}"
    local perms="${2:-644}"
    verbose "Installing ${file}"
    cp "${PI_ROOT:?}/${file}" "${PI_SAVED:?}/${file}"
    cp "${PI_TMP:?}/${file}" "${PI_ROOT:?}/${file}"
    chmod "${perms}" "${PI_ROOT:?}/${file}"
}

# Install a user's home directory from pre-supplied data, taking care
# to set the permissions on .ssh/ correctly.
installHome() {
    local user="${1:?}"
    verbose "Installing user files for ${user}"
    cp -a "${PI_DATA:?}/home/${user}" "${PI_ROOT:?}/home/${user}"
    cp -a "${PI_DATA:?}/home/${user}/.ssh" "${PI_ROOT:?}/home/${user}/.ssh"
    find "${PI_ROOT:?}/home/${user}/.ssh" -type d -exec chmod 700 {} \;
    find "${PI_ROOT:?}/home/${user}/.ssh" -type f -exec chmod 600 {} \;
}


unset options_done
while [ ! -z "$*" -a -z "$options_done" ]; do
    case "$1" in
        --help|'-?')
            usage
            exit 0
            ;;
        --debug|-d|-vv)
            export PI_VERBOSE=yes
            export PI_DEBUG=yes
            shift
            ;;
        --verbose|-v)
            export PI_VERBOSE=yes
            shift
            ;;
        *)
            options_done=true
            ;;
    esac
done
