# Raspberry Pi Disk Image Tool

While there are many instructions on the net on how to mount Raspberry Pi OS disk image to
manipulate it, they are both awkward to use, and limited to Linux.

I have a Mac. The MacOS tools only give access to the boot partition (FAT32),
but not the root partition (ext4). My first success came with VirtualBox's CLI interface and Ubuntu,
but that was not automatable for multiple reasons.

This solution uses Docker to run arbitrary Linux (Ubuntu) commands in a context with the
partitions from a Raspberry Pi image mounted as a filesystem under `/data/root`.

It also allows importing a Raspberry Pi image and running it in a docker container, even on non-ARM
architectures (e.g. my Intel iMac, but should also work on Windows).

For ease of use, this is packaged behind three front-end scripts:

* `rpi-image-tool`: The main tool
* `dockerify`: Import a Raspery Pi boot image file as a docker container.
* `pi`: Invoke a Raspberry Pi container.

## rpi-image-tool

>    Usage: rpi-image-tool [--verbose|--debug] [--interactive] [--builder imagename] <.img file> <cmd> <args*>

Root and boot filesystems will be mounted under `/data/build/root` and `/data/build/root/boot` and the supplied command will be executed.

The command can be a local script, or it can be `bash`, `emacs`, `nano`, or `vi` to allow interactive
exporation or manual modifications. These four default to `--interactive`; other interactive tools may require
passing the `--interactive` flag explicitly.

Additionally, convenience commands are provided:

* [`blkids`](bin/blkids) — list the UUID's and labels of the partitioms and the partition map.
* [`export`](bin/export) — convert an disk image to a `.tar` file for import with `docker import`
* [`partition-size`](bin/partition-size) - Show the partition sizes, or modify the root partition size.

If invoked via the provided script ([`rpi-image-tool`](rpi-image-tool)), images and scripts can be located in the current working directory or a subdirectory.
The script mounts this under `/data/local/`, and this becomes the current working directory inside the container, allowing relative paths to work properly.

The `bin/` directory (`/data/local/bin`) under the working directory will be added to `$PATH`, making scripting more convenient.

The supplied image file will be mounted at `/data/img`, and `$PI_IMAGE_FILE` will point to it. `$PI_USER_IMAGE_FILE` will hold the user-supplied path, useful for error messages.

## Non-Raspberry Pi OS images

In theory there is no reason this could not mount an arbitrary disk image's partitions. However, this has knowledge of the specific partitions, e.g. the first partition is the boot partition and should mount to `/boot`, while the second is the root partition, and no other partitions are examined.

This could be disabled with a `--flat` command-line option. This could mount each partition under /data/mnt,
i.e. a Raspberry Pi boot image would look like this:

* `/data/mnt/boot`
* `/data/mnt/rootfs`

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
./dockerify 2021-10-30-raspios-bullseye-arm64.img myacct/pi:bullseye
```

The resulting image can be run with the `pi` comamand:

```bash
./pi myacct/pi:bullseye
```

This optionally takes a command and arguments; this defaults `bash`.

The image name defaults to `pi:latest`

The current directory is mounted in the image as `/host` to make it easy to transfer files, etc.

On exiting, the container will be deleted. Other behaviors can be had by invoking `docker run` directly, omitting the `--rm` option.

## Scripting

Random one-off updates and modifications are to be discouraged. To achieve a repeatable process, all
setup should be scripted.

If you supply a script to `rpi-image-tool` all of the subcommands will be regular `bash` commands.

The `--interactive` mode (and the availability of `bash`, `emacs`, `vi`, or `nano`) are useful for working
out just what is required, but the result should be captured in a setup script.

`rpi-image-tool` in non-interactive mode outputs to `stdout` and `stderr` appropriately, making it
friendly for use in scripts itself, perhaps as step near the end of a larger build process.

## Extending the tool

The `rpi-image-tool` can be extended in three ways.

1) scripts in or below the current directory can be referenced by relative pathname and be invoked. They will be run in-context and can access the mounted filesystems, use the
environment variables, and run the other subcommands directly.

2) Scripts placed in a `bin/` subdirectory of the current directory will be on the `$PATH`, and thus can be referenced by name, without the `bin/` prefix.

3) The docker container can be extended by copying additional subcommand scripts to `/data/bin` in your `Dockerfile`

e.g.:

```docker
FROM rpiimagetool:latest
COPY mybin/ /data/bin
```

You can build your new container image via:

```bash
docker build --pull --rm -f Dockerfile -t myrpiimagetool:latest
```

Setting `$PI_BUILDER` to your new image will cause it to be used instead of the default,
or you can supply the `--builder <image:tag>` option to `rpi-image-tool`.

Scripts should be self-documenting by including a documentation comment at the start.
Documentation comments are a block of comments starting with `'#### '`.
Parameter substitution is performed, so you can reference environment variables or
invoke shell commands to generate the documentation output.

The scripts should follow the following format:

```bash
#!/bin/bash

#### This is a documentation comment
#### Usage: ${PI_INVOKER} [--myflag] myarg
####
#### The space after the #### is required, unless the line is blank.

# This sets up variables, and ensures that the --help option is handled uniformly.
. "${PI_CMDS}/inc/vars.sh"

echo <<EOF
Your code here.
You may invoke non-bash tools with 'exec', e.g. 'exec node mysripts/my-node-script'
This would be prefered over forcing my-node-script into the necessary form.
EOF

# exec node myscripts/my-node-script
```

### Environment Variables

The following environment variables are set up prior to invoking the subcommand scripts:

#### From the host environent

* `PI_USER_CWD`
  * The current working directory in the host
* `PI_USER_NAME`
  * The host user invoking the builder
* `PI_USER_IMAGE_FILE`
  * The image file path as supplied by the user, for error reporting
* `PI_INVOKER_BASE`
  * The name of the command used to invoke the builder, for help messages and errors.
* `PI_INVOKER`
  * The help message to use for the builder script and options, up to the subcommand.
* `PI_INTERACTIVE`
  * Non-null iff `--interactive` is specified, or if the command to run is `bash`, `vi`, `nano`, or `emacs`.
* `PI_BUILDER`
  * The name:tag of the docker container that performs the work.

#### In the builder

* `PI_INCLUDES`
  * The directory that holds scripts to be sourced. Currently only `vars.sh`
* `PI_CMDS`
  * The directory that contains the subcommands.
* `PI_WORKDIR`
  * The initial working directory for commands.
* `PI_BUILD`
  * A directory for storing values to be stored into the image
* `PI_TMP`
  * A temporary directory
* `PI_DATA`
  * The `data/` subdirectory on the host, conventional place to load data to install
* `PI_SAVED
  * The `saved/` subdirectory on the host, where unmodified copies of files to be modified are placed.
* `PI_ROOT`
  * The path to the mounted root filesystem from the image
* `PI_BOOT`
  * The path to the mounted boot filesystem from the image
* `PI_VERBOSE`
  * non-empty if the `--verbose` flag was supplied.
* `PI_DEBUG`
  * non-empty if the `--debug` flag was supplied
* `PI_BOOTDEV`
  * The device name from which the image boot filesystem is mounted.
* `PI_ROOTDEV`
  * The device name from which the image root filesystem is mounted.
* `PI_LOOPDEV`
  * The device name for the full image file as a block device.
