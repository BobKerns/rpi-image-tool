# Running Raspberry Pi OS on Any Hardware

You can run Raspberry Pi OS under `docker`, even on an Intel system, via the `quemu` emulation package.

Docker's emulation is enabled via the following command:

```bash
docker run --privileged linuxkit/binfmt:v0.8
```

To create a Raspberry Pi OS `docker` image, we need to convert a Raspberry Pi OS Distro (or a micro-SD card)
to a docker image with the `dockerify` command:

```bash
rpi-image-tool import 2021-10-30-raspios-bullseye-arm64.img;
rpi-image-tool dockerify - \
| docker import - myacct/raspios:bullseye
```

The latter two steps are packaged in the [`dockerify`](dockerify) script:

```bash
./dockerify 2021-10-30-raspios-bullseye-arm64.img myacct/pi:bullseye
```

The resulting image can be conveniently run with the `pi` comamand:

```bash
./pi myacct/pi:bullseye
```

This optionally takes a command and arguments; this defaults `bash`.

The image name defaults to `pi:latest`. Thus,

```bash
pi
```

will drop you into a bash prompt running Raspberry Pi OS.

The current directory is mounted in the image as `/host` and made the current directory,
making it easy to transfer files, etc.

By default, the `--rm` and `-it` options are supplied, making it an interactive, temporary container instance.
This means that on exiting, the container will be deleted. Supplying `--nodefault` will suppress these, while `--default` will reinstate them. The current directory will still be mapped to `/host`.

Other behaviors can be had by invoking `docker run` directly; this command exists for convenience, and the
Raspberry Pi OS image can be run with no special considerations.

## Extracting a Pi Disk Image from Docker

The command `undockerify` is used to extract a filesystem from a Raspberry Pi OS `docker` image. It takes as arguments:

* `--label` *label*
* `--boot-id` *label*
* `--root-uuid` *uuid*
* *imageName*
* *bootsize*
* *rootsize*

The labels/uuid are optional; they will be generated as needed.

The imageName is the docker image name or id.

The *bootsize* and *rootsize* are the size of the respective filesystems, in MiB.
