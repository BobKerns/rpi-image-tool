# `setup-disk` (command)

Usage:

> `setup-disk` [`--type` `ext4` | `fat` | `none` ]
  [ `--label` *label* ] [ `--partlabel` *label* ]
  [ `--uuid` *uuid* ] [ `--partuid` *uuid* ]
  [ `--id` *id* ] *filename* [*size*] [*content*]
>
> `setup-disk` `--register` [`--type` `ext4` | `fat` | `none` ]
  [ `--label` *label* ] [ `--partlabel` *label* ]
  [ `--uuid` *uuid* ] [ `--partuid` *uuid* ]
  [ `--id` *id* ] *filename* [*size*] [*content*]
>
> `setup-disk` `--list`
>
> `setup-disk` `--unregister` *name*
>
> `setup-disk` `--find` ( *name* | *label* | *id* | *uuid* )

Create and manage axilliary disk images to substitute for physical disks on the target
hardware.

## Creating disk images

The first two forms create a file of *size* megabytes initialized with a filesystem that
can be mounted into a container to substitute for a physical drive partition that is
expected to be there. Without `--register`, the file is created in the indicated location.
With `--register`, it is placed in a [registery](#Registry).

For example, if `/etc/fstab` references `LABEL=mydata`, and requires that it has a
directory `log/` you can create a suitable substitute via:

```bash
# Create a minimal skeleton of expected content
mkdir -p mydata-skel/log
setup-disk --label mydata mydata.disk 1 mydata-skel
```

Supply any of the `--label`, `--partlabel`, `--uuid`, `--partuuid`, or `--id` fields
you intend to use, e.g. in an `/etc/fstab` file. Without `--register`, `--partlabel` and
`--partuuid` are not used.

## Using the disk image via the `pi` command

Any of the identifiers may be used in the `--disk` option to the `pi` command.

## Registry

Forms of the `setup-disk` command with the `--register`, `--unregister`, `--list`, or
`--find` options operate on image files stored in a registry, where they are indexed
by *name*, *label*, *uuid*, or *id*.

Use of the registry is recommended, but is not required. Among other things, it tracks
what labels and UUIDs apply.

Note that the only identifier that must be unique is the name. Thus, we can have
different disks with different content for testing, but with the same `UUID=`. Thus,
selecting the image to attach by name is preferred.

## Using the disk image manually

The disk image produced does not include a partition table. This makes it easier to set up
and use, and independent of just how the the physical partition is provided. The downside
is that `PARTUUID=` and `PARTLABEL=` cannot function in an `/etc/fstab` file without
additional setup.

To inject our new filesystem, we need to do three things:

* Invoke `docker` with the `--privileged` argument.
* Bind-mount our image at a suitable location, say `/dev/host/mydata`
* Once the container starts, create a loop device backed by our image via
  `losetup -f /dev/host/mydata`.

(The `--privileged` is unfortunately required for creating loop devices under docker.)

It is then available for mounting, e.g. via:

```bash
mkdir /data
mount LABEL=mydata /data
```

Because loop devices under `docker` are shared between privileged containers,you should be
sure to unmount and remove the loop device. A good way to do this is:

```bash
#!/bin/bash

cleanup() {
    if [ ! -z "${LOOP} ]; then
        umount /data
        losetup -d "${LOOP}"
    fi
}

trap cleanup exit
LOOP="$(losetup -f --show /dev/host/mydata)"
mkdir /data
mount LABEL=mydata /data
if [ -z "${@}" ]; then
    set -- bash
fi
"${@}"
```

If this is placed in `startup.sh` and made executable with `chmod u+x startup.sh`, this can
be automated:

```bash
#!/usr/bin/env bash

DISK=mydata.disk
SCRIPT=startup.sh

# Compute the absolute path for a possibly-relative pathname.
abspath() {
    if [[ -d "$1" ]]; then
        (cd "$1"; pwd)
    else
        (cd "$(dirname "$1")"; echo "${PWD}/$(basename -a "$1")")
    fi
}

declare -a mounts=()
addMount() {
    local src="$(abspath "${1}")"
    local dest="${2}/$(basename -a "${2}")"
    mounts+= (
        -v "${src}:${dest}
    )
}

addMount "${DISK}" /dev/host
addMount "${SCRIPT}" /mnt

docker run \
    --interactive --tty --rm \
    "${mounts[@]}"
    --entrypoint="/mnt/$(basename -a "${SCRIPT}")"
    mypi-image:latest
    "${@}"
```

There is no particular significance to `/dev/host`; it is just a descriptive place
to put fake devices injected by the host and unlikely to conflict with other names.

If, despite these countermeasures, you end up running out of loop devices, you can clear
them with `losetup -D` run in a privileged container.
