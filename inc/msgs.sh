#!/bin/sh

# Include this after vars.sh to print informational messages.

# Show usage for the current or specified command.
usage() {
     local cmd="$(which -- "${1:-"${PI_CMD}"}")"
     local script="$(grep -E '^#### |^####$' "${cmd:-"${PI_CMD}"}" | sed -E -e 's/^#### ?/echo "/' -e 's/$/";/')"
     if [ "${1}" = bash -o "${1}" = "/bin/bash" -o "${1}" = "$(which -- bash)" ]; then
        msg "Usage: ${PI_INVOKER_BASE} [subcmd]"
        msg "  With no arguments, invokes bash with the image filesystems mounted."
        msg "Usage: ${PI_INVOKER_BASE} help [subcmd]"
        msg "  Documents [subcmd] if it is one of our scripts."
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
# Usage:
#   error This is an error message
#   error 2 -- This is an error message and exits with return code 2.
error() {
    local code=126
    if [ "${2}" = '--' ]; then
        code="${1}"
        shift
        shift
    fi
    msg ERROR: "$@"
    # We suppress decoding exit code 126, since we've already logged an error message.
    exit $(( code ))
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
