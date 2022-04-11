#!/bin/bash

# Various utility routines. This is intended to be included in other scripts.

export PI_CMD="$0"
export PI_INCLUDES="${PI_INCLUDES:-"$(cd "$(dirname "$0")"; pwd)"}"
export PI_CMDS="${PI_CMDS:-"$(dirname "${PI_INCLUDES}")/cmds"}"
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

export PI_INVOKER_BASE="${PI_INVOKER_BASE:-"$0"}"

# Our own process ID, to enable aborting on error or c-C.
SELF=$$

export PI_INVOKER_BASE="${PI_INVOKER}"

. "${PI_INCLUDES}/msgs.sh"

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
        --term)
            shift
            export PI_TERM="${1:?}"
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
