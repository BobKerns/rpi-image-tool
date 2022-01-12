# Raspberry Pi Disk Image Tool

While there are many instructions on the net on how to mount Raspberry Pi OS disk image to manipulate it, they are both awkward to use, and limited to Linux.

I have a Mac. The MacOS tools only give access to the boot partition (FAT32), but not the root partition (ext4). My first success came with VirtualBox's CLI interface and Ubuntu, but that was not automatable for multiple reasons.

This solution uses Docker to run an arbitrary Linux (Ubuntu) command in a context with the partitions from a Raspberry Pi image mounted as a filesystem under `/data/root`. The command can be a local script, or it can be `bash` to allow interactive exporation or manual modifications.

Additionally, convenience commands are provided:

* `blkids` — list the UUID's and labels of the partitioms and the partition map.
* `dockerify` — convert an disk image to a `.tar` file for import with `docker import`

If invoked via the provided script ([rpi-image-tool](rpi-image-tool)), images and scripts can be located in the current working directory or a subdirectory. The script mounts this under `/data/local/`, and this becomes the current working directory inside the container, allowing relative paths to work properly.

The `bin/` directory (`/data/local/bin`) under the working directory will be added to `$PATH`, making scripting more convenient.

The supplied image file will be mounted at `/data/img`, and `$IMG` will point to it. If the supplied script is not used, `$IMG` will be the path supplied on the command line. `$USER_IMG` always holds the user-supplied path, useful for error messages.

## Non-Raspberry Pi OS images

In theory there is no reason this could not mount an arbitrary disk image's partitions. However, this has knowledge of the specific partitions, e.g. the first partition is the boot partition and should mount to `/boot`, while the second is the root partition, and no other partitions are examined.

This could be disabled with a `--flat` command-line option.

## Running Raspberry Pi OS

You can run Raspberry Pi OS under `docker`, even on an Intel system, via the `quemu` emulation package.

Docker's emulation is enabled via the following command:

```bash
docker run --privileged linuxkit/binfmt:v0.8
```

To create a Raspberry Pi OS docker image, we need to convert a Raspberry Pi OS Distro (or a micro-SD card) to a docker image with the `dockerify` command:

```bash
rpi-image-tool 2021-10-30-raspios-bullseye-arm64.img dockerify - \
| docker import - myacct/raspios:bullseye
```

This is packaged in the [`dockerify`](dockerify) script:

```bash
./dockerify 2021-10-30-raspios-bullseye-arm64.img myacct/raspios:bullseye
```
