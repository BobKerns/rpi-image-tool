#!/bin/bash

# Various utility routines. This is intended to be included in other scripts.

WDIR="${WDIR-"$(cd "$(dirname "$0")"; pwd)"}"

export BUILD="${BUILD-"${WDIR}/build"}"
export BUILDTMP="${BUILD}/tmp"
export DATA="${WDIR}/data"
export SAVED="${WDIR}/saved"

export ROOTDIR="${BUILD}/root"
export BOOTDIR="${ROOTDIR}/boot"

SELF=$$

msg() {
    echo "$@" 1>&2
}

# Unmount the specified directory
do_unmount() {
    local dir="$1"
    if [ -e "${dir}" -a ! -e "${dir}/.gitignore" ]; then
	    umount "${dir}"
	    msg "${dir} unmounted."
    fi
}

# Unmount all our directories,m and clean up our temporary directory.
do_unmount_all() {
    if [ -d "${BUILDTMP}" ]; then
        msg "Removing previous temp ${BUILDTMP}"
        rm -rf "${BUILDTMP}" 2>/dev/null
    fi
    do_unmount "${BOOTDIR}"
    do_unmount "${ROOTDIR}"
    if [ -e "${LOOPDEV}" ]; then
        kpartx -d "${LOOPDEV}"
        losetup --detach "${LOOPDEV}"
    fi
}

# Set LOOPDEV, ROOTDEV, and BOOTDEV to the raw devices
# for the whole disk and its root and boot partitions.
find_partitions() {
    mapfile -t PARTS < <(kpartx -avs "${IMG}" | cut -d' ' -f3)
    export BOOTDEV="/dev/mapper/${PARTS[0]}"
    export ROOTDEV="/dev/mapper/${PARTS[1]}"
    export LOOPDEV="/dev/$(echo "${PARTS[0]}" | sed -E 's/p[0-9]+$//')"
    msg Found LOOPDEV="${LOOPDEV}"
    msg Found BOOTDEV="${BOOTDEV}" BOOTDIR="${BOOTDIR}"
    msg Found ROOTDEV="${ROOTDEV}" ROOTDIR="${ROOTDIR}"
}

# Mount the specified directory on the specified location
# Arrange to clean up if the mount fails.
do_mount() {
    local mapped="$1"
    local mountpoint="$2"
    (
        mount -o loop "${mapped}" "${mountpoint}" \
        && msg "${mapped} mounted on ${mountpoint}"
    ) || (
        msg "${mountpoint} mount failed." 1>&2
        kill -s INT $SELF
    )
}

# Mount our partitions and our temporary work area.
do_mount_all() {
    do_unmount_all 2>/dev/null
    mkdir -p "${BUILDTMP}" 2>/dev/null
    msg "Mounting partitions from ${IMG}"
    find_partitions
    trap "do_unmount_all" INT
    trap "do_unmount_all" EXIT
    do_mount "${ROOTDEV}" "${ROOTDIR}"
    do_mount "${BOOTDEV}" "${BOOTDIR}"
}

# mkktmp dir
# make a directory in our temporary workspace.
# Takes the full relative or absolute path
mktmp() {
    rm -rf "$1" 2>/dev/null
    mkdir -p "${1}"
}

# copy file
# copies from data to buildtmp
copy() {
    cp "${DATA}/$1" "${BUILDTMP}/$1"
}

copyUntilInternal() {
    local terminator="${1-## Added}"
     while read line; do
        if [ "$line" = "${terminator}" ]; then
            return 0
        else
            msg "$line"
        fi
    done
}

# Copy everything prior to a specified line.
# This is used to allow scripts to append data,
# but if the script is run again, the data is replaced,
# not endlessly added.
copyUntil() {
    copyUntilInternal "${2-## Added}" <"${ROOTDIR}/$1" >"${BUILDTMP}/$1"
}

# append file
# Appends file from data to the destination (result in buildtmp)
append() {
    cp "${BUILDROOT}/$1" "${BUILDTMP}/$1"
    appendLine "$1" '## Added'
    cat "${DATA}/$1" >>"${BUILDTMP}/$1"
}

# appendLine file line
# Result in buildtmp
appendLine() {
    echo "$2" >>"${BUILDTMP}/$1"
}

# install file [ perms ]
# Install data from buildtmp area to the real filesystem
install() {
    local file="$1"
    local perms="${2-644}"
    msg "Installing ${file}"
    cp "${ROOTDIR}/${file}" "${SAVED}/${file}"
    cp "${BUILDTMP}/${file}" "${ROOTDIR}/${file}"
    chmod "${perms}" "${ROOTDIR}/${file}"
}

# Install a user's home directory from pre-supplied data, taking care
# to set the permissions on .ssh/ correctly.
installHome() {
    local user="$1"
    msg "Installing user files for ${user}"
    cp -a "${DATA}/home/${user}" "${ROOTDIR}/home/${user}"
    cp -a "${DATA}/home/${user}/.ssh" "${ROOTDIR}/home/${user}/.ssh"
    find "${ROOTDIR}/home/${user}/.ssh" -type d -exec chmod 700 {} \;
    find "${ROOTDIR}/home/${user}/.ssh" -type f -exec chmod 600 {} \;
}
