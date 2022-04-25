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

This enables workflows like this to be performed on any platform:

1. Download a stock Raspberry Pi OS image
2. Import the image into the tool
3. Expand the root filesystem to make room
4. Alter configuration files
5. Import the modified image file into docker
6. Do further setup in a running image (such as installing packages).
7. Export a new Raspberry Pi OS image file to copy to an SD card.

## Usage

For ease of use, this is packaged behind three front-end scripts:

* [`rpi-image-tool`](doc/bin/rpi-image-tool.md): The main tool
* [`grow-root-fs`](doc/bin/grow-root-fs.md): Increase the size of the root filesystem
* [`dockerify`](bin/dockerify): Import a Rasperry Pi boot image file as a docker container.
* [`undockerify`](bin/undockerify): Export a Rasperry Pi boot image file from a `pi` docker container
* [`pi`](bin/pi): Invoke a Raspberry Pi container.

## Additional Resources

* [Running Pi OS On Any Hardware](doc/pi-os-anywhere.md)
* [Scripting](doc/scripting.md)
* [Extending the Rasperry Pi OS Image Tool](doc/extending.md)
* [Non-Raspberry Pi OS images](doc/non-raspos.md)
* [FAQ](doc/faq.md)
