# Running Raspberry Pi OS on Any Hardware

You can run Raspberry Pi OS under [`docker`](https://docs.docker.com/reference/), even on an Intel system,
via the [`quemu` emulation package](https://www.qemu.org/). It ... just works, by magic. So, while running
on an Intel iMac:

```bash
$ arch
i386
```

But running ARM64 code:

```bash
$ pi pi:latest ps -aux
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.2 150900 11976 pts/0    Ssl+ 21:01   0:00 /usr/bin/qemu-aarch64 /bin/bash /bin/bash /sbin/startup-script ps -aux
root           9  0.0  0.2 153424 11004 ?        Rl+  Apr25   0:00 ps -aux
$ pi pi:latest file /bin/bash
/bin/bash: ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, BuildID[sha1]=641209ff5307ca8eb85bd6368cb5f7f2e694897e, for GNU/Linux 3.7.0, stripped
```

Here we see that [`qemu`](https://www.qemu.org/) is interpreting our Arm64 bash command that runs our
startup script.

Docker's emulation is enabled via the following command:

```bash
docker run --privileged linuxkit/binfmt:v0.8
```

It is claimed that Docker Desktop comes with it already enabled, but having enabled it manually, I cannot
confirm this.
## Creating a pi docker image with [`dockerify` (script)](bin/dockerify.md)

To create a Raspberry Pi OS `docker` image, we need to convert a Raspberry Pi OS Distro
(or a micro-SD card) to a docker image with the
[`export-docker` (subcommand)](cmds/export-docker.md) command:

```bash
rpi-image-tool import 2021-10-30-raspios-bullseye-arm64.img;
rpi-image-tool dockerify - \
| docker import --platform linux/arm64 - myacct/raspios:bullseye
```

The latter two steps are packaged in the [`dockerify`](bin/dockerify) script:

```bash
./dockerify 2021-10-30-raspios-bullseye-arm64.img myacct/pi:bullseye
```

The resulting image can be conveniently run with the `pi` comamand:

```bash
./pi myacct/pi:bullseye
```

This optionally takes a command and arguments; this defaults to `bash`.

The image name defaults to `pi:latest`. Thus,

```bash
pi
```

will drop you into a bash prompt running Raspberry Pi OS.

The current directory is mounted in the image as `/mnt/host` and made the current
directory, making it easy to transfer files, etc.

By default, the `--rm` and `-it` (`--interactive` `--tty`) options are supplied, making it
an interactive,temporary container instance. This means that on exiting, the container
will be deleted. Supplying `--no-rm`, `no-interactive`  will suppress these. The current
directory will still be mapped to `/mnt/host`.

Other behaviors can be had by invoking `docker run` directly; this command exists for
convenience, and the Raspberry Pi OS image can be run with no special considerations.

> Note: The`--platform` `linux/arm64` argument may be required if the image was not properly
  labeled.

## Configuring a Pi system via a `docker build` and a [`Dockerfile`](https://docs.docker.com/engine/reference/builder/)

Note: <span style='color:red;'>*Experimental*</span>

Once you have a `docker` image, it is straightforward to build an image with the desired components.
The result will still be a `docker` image, but it brings us a big step closer to our goal.

The only [`Dockerfile`](https://docs.docker.com/engine/reference/builder/) caveat I've
noticed so far is that without using
[`buildx`](https://docs.docker.com/engine/reference/commandline/buildx/) and
its`docker-container` driver, the platform in the docker image is set incorrectly
to that of the build host.

`buildx` is overall the more capable and superior build system, compared to the original
`docker build` command. However, it integrates awkwardly, requiring use of a separate
repository. You can run your own, but that can be difficult to set up. Notably, the default
port of 5000 is in use by components of MacOS ("AirTunes").

But it looks like specifying the platform correctly during
[`docker import`](https://docs.docker.com/engine/reference/commandline/import/) will avoid the
problem at further stages.

One reason to consider using `buildx` is to be able to run on a native `arm64` node (not neessarily a Raspberry Pi), for improved performance.

> Be aware that the [`pi` command](bin/pi.md) overrides the `ENTRYPOINT` at runtime
to handle the mounting of disks and other early tasks. A possible future workaround
would be to set an environment variable to the same value, and have the startup script
check and run it if provided.

## Extracting a Pi Disk Image from Docker

The command [`undockerify`](bin/undockerify.md) is used to extract a filesystem from a
Raspberry Pi OS [`docker`](https://docs.docker.com/reference/) image.

It takes as arguments:

* `--label` *label*
* `--boot-id` *label*
* `--root-uuid` *uuid*
* *imageName*
* *bootsize*
* *rootsize*

The labels/uuid are optional; they will be generated as needed.

The *imageName* is the `docker` image name or id.

The *bootsize* and *rootsize* are the size of the respective filesystems, in MiB.

You can use the `du` command to estimate the required sizes:

**Root:**

```bash
 du --summarize --block-size=1M --count-links --apparent-size --one-file-system\
   --exclude /boot\
   --exclude /dev\
   --exclude /media\
   --exclude /mnt\
   --exclude /proc\
   --exclude /run\
   --exclude /tmp\
   /
```

**Boot:**

```bash
 du --summarize --block-size=1M --count-links --apparent-size --one-file-system /boot
```

This will be a lower bound. I suggest adding at least 1 MiB to the root filesystem's current size.

You do want to keep the filesystem small to keep the image size down; the filesystem
can be expanded once it's installed on the media and booted.
