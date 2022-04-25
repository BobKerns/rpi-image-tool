# `rpi-image-tool` (command)

Usage:

> `rpi-image-too`l \[ `--verbose` | `--debug` ] [ `--interactive` ] [ `--volume` *volname*] *.img_file* *cmd* *args*\*

[*Source*](../../bin/rpi-image-tool)

Root and boot filesystems will be normally mounted under `/data/build/root` and `/data/build/root/boot`
and the supplied command will be executed.

The command can be a local script, or it can be `bash`, `emacs`, `nano`, or `vi` to allow interactive
exporation or manual modifications. These four default to `--interactive`; other interactive tools may require
passing the `--interactive` flag explicitly.

Additionally, convenience subcommands are provided:

## Data modifiers

These commands queue up changed versions of files, while preserving the original for comparison or reversion.
The image is not directly modified; the changes are not applied until the `commit` subcommand is issued.

* [`add-cgroups`](cmds/add-cgroups): Add cgroups to boot/cmdline.txt
* [`append`](cmds/append): Append data to an file in the image
* [`appendLine`](cmds/appendLine): Append a line of text to a file in the image.
* [`copy`](cmds/copy): Copy a file be added to the image (or to replace an existing file).
* [`hostname`](cmds/hostname): Make the necessary changes to pre-set the hostname.
* [`installHome`](cmds/installHome): Install a user home directory's files & set permissions.

## Partition and filesystem utilities

* [`blkids`](cmds/blkids): list the UUID's and labels of the partitioms and the partition map.
* [`fsck`](cmds/fsck): perform `fsck` on the image filesystems.
* [`partition-size`](cmds/partition-size): Show the partition sizes, or modify the root partition size.

## Lifecycle subcommands

Thse commands operate on working copy of the image stored in a docker volume

* [`commit`](cmds/commit): Write pending changes to the image
* [`create-image`](cmds/create-image): Create and populate a disk image from a tar file
* [`export-docker`](cmds/export): convert an disk image to a `.tar` file for import with `docker import`
* [`export-image`](cmds/export-image): Export the working image to an external `.img` or `.zip` file that
  can be loaded to an SD card.
* [`image`](cmds/image): Load, delete, or reset the image to be configured. This can be a `.img` file or a
  `.zip` file containing the image.

## Utility subcommands

* [`help`](cmds/help): Display a command's help documentation.
* [`diff`](cmds/diff): Compare pending changes to the original
* [`msg`](cmds/msg): Display a message on stderer (used by other commands).

## User-supplied subcommands

If invoked via the provided script ([`rpi-image-tool`](rpi-image-tool)), images and scripts can be
located in the current working directory or a subdirectory.
The script mounts this under `/mnt/host/`, and this becomes the current working directory inside the container,
allowing relative paths to work properly. (Obviously, relative paths involvig '../' are not supported.)

The `cmds/` directory (`/mnt/host/cmds`) under the working directory will be added to `$PATH`,
making scripting more convenient.

If an image file has been loaded, it will be mounted at `/work/image`, and `$PI_IMAGE_FILE` will point to it.
`$PI_USER_IMAGE_FILE` will hold the user-supplied path, useful for error messages.

The docker container which performs the work must be run as a privileged container, to be able to mount
the image file's partitions.
