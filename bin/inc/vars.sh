#!/bin/bash

# Various utility routines. This is intended to be included in other scripts.

CMD="$0"
export PI_INCLUDES="${PI_INCLUDES:-"$(cd "$(dirname "$0")"; pwd)"}"
export PI_CMDS="${PI_CMDS:-"$(dirname "${PI_INCLUDES}")"}"
DFLT_WDIR="/work"
export PI_WORKDIR="${PI_WORKDIR:-"${DFLT_WDIR}"}"
export PI_BUILD="${PI_BUILD:-"${PI_WORKDIR}/build"}"
export PI_TMP="${PI_TMP:-"${PI_WORKDIR}/tmp"}"
export PI_DATA="${PI_DATA:-"/data/local"}"
export PI_SAVED="${PI_SAVED:-"${PI_WORKDIR}/saved"}"
export PI_PENDING="${PI_PENDING:-"${PI_WORKDIR}/pending"}"

export PI_ROOT="${PI_ROOT:-"${PI_BUILD}/root"}"
export PI_BOOT="${PI_BOOT:-"${PI_ROOT}/boot"}"

export PI_IMAGE_FILE=/work/image
# Should be the same as in rpi-image-tool
export PI_IMAGE_SRC_MOUNT="${PI_IMAGE_SRC_MOUNT-/data/image}"

# Our own process ID, to enable aborting on error or c-C.
SELF=$$

export PI_INVOKER_BASE="${PI_INVOKER}"

# Show usage for the current or specified command.
usage() {
     local cmd="$(which -- "${1-"${CMD}"}")"
     local script="$(grep -E '^#### |^####$' "${cmd}" | sed -E -e 's/^#### ?/echo "/' -e 's/$/";/')"
     if [ "${1}" = bash -o "${1}" = "/bin/bash" -o "${1}" = "$(which -- bash)" ]; then
        msg "Usage: ${PI_INVOKER_BASE} [subcmd]"
        msg "  With no arguments, invokes bash with the image filesystems mounted."
        msg "Usage: ${PI_INVOKER_BASE} help [subcmd]"
        msg "  Documents [subcmd] if it is one of our scripts.
        exit 0
     fi
     if [ -z "${script}" ]; then
        msg "The script ${cmd} lacks documentation."
        msg "  Subcommand documentation is a set of comments beginning with '#### '."
        msg "  These are stripped of the '#### ', and shell substitutions are performed,"
        msg "  so help text can reference environment variables, etc."
        msg "  Particlarly useful is the PI_INVOKER environment variable, which holds"
        msg "  help for the words from the start through the subcommand on the command line."
        exit 0
    else
        eval "${script}" 1>&2
        exit 0
    fi
 }

# Print an informational message to stderr
msg() {
    echo "$@" 1>&2
}

# Print a mesage to stderr if --verbose or --debug
verbose() {
    test ! -z "${PI_VERBOSE}${PI_DEBUG}" && msg "$@"
    return 0
}

# Print a message to stderr if --debug.
debug() {
    test ! -z "${PI_DEBUG}" && msg "$@"
    return 0
}

# Print an error message and exit.
error() {
    msg ERROR: "$@"
    # We suppress decoding exit code 126, since we've already logged an error message.
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

# Format disk space numbers in a human-friendly way.
dspace() {
    local val="$1"
    local unit
    local factor=1
    if (( val >= 1024*1024*1024 )); then
        factor=$(( 1024*1024*1024 ))
        unit=G
    elif (( val >= 1024*1024 )); then
        factor=$(( 1024*1024 ))
        unit=M
    elif (( val >= 1024 )); then
        factor=$(( 1024 ))
        unit=K
    else
        factor=$(( 1 ))
        unit=B
    fi
    local fmtv="$( bc <<< "scale=3; ${val}/${factor}" )"
    local fmtv1="${fmtv%0}"
    local fmtv2="${fmtv1%0}"
    local fmtd="${fmtv2%.0}${unit}"
    echo "${fmtd}"
}

# Copy everything prior to a specified line.
# This is used to allow scripts to append data,
# but if the script is run again, the data is replaced,
# not endlessly added.
copyUntil() {
    copyUntilInternal "${2-## Added}" <"${PI_ROOT:?}/$1" >"${PI_TMP:?}/$1"
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

declare -a options=()
while [ "${1:0:2}" = '--' ]; do
    case "$1" in
        --help|'-?')
            export PI_INVOKER="${PI_INVOKER_BASE} $2"
            usage "$2"
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
        --nomount)
            export PI_NO_MOUNT=yes
            shift
            ;;
        *)
            options+=("$1")
            shift
            ;;
    esac
done

# Look ahead for --help and handle it here.
declare -a suboptions=()
subcmd="$1"
shift

while [ "${1:0:2}" = '--' ]; do
    case "$1" in
        --help|'-?')
            export PI_INVOKER="${PI_INVOKER_BASE} ${subcmd}"
            usage "${subcmd}"
            exit 0
            ;;
        *)
            suboptions+=("$1")
            shift
            ;;
    esac
done

set -- "${options[@]}" "${subcmd}" "${suboptions[@]}" "$@"
