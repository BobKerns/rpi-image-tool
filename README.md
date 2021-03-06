# Raspberry Pi Disk Image Tool

While there are many instructions on the net on how to mount Raspberry Pi OS disk image to
manipulate it, they are both awkward to use, and limited to Linux.

I have a Mac. The MacOS tools only give access to the boot partition (FAT32),
but not the root partition (ext4). My first success came with VirtualBox's CLI interface and Ubuntu,
but that was not automatable for multiple reasons.

This solution uses Docker to run arbitrary Linux (Ubuntu) commands in a context with the
partitions from a Raspberry Pi image mounted as a filesystem under `/data/root`.

It also allows importing a Raspberry Pi image and running it in a docker container, even on
non-ARM architectures (e.g. my Intel iMac, but should also work on Windows).

This enables workflows like this to be performed on any platform:

1. Download a stock Raspberry Pi OS image
2. Import the image into the tool
3. Expand the root filesystem to make room (if needed)
4. Alter configuration files
5. Import the modified image file into docker
6. Do further setup in a running image (such as installing packages).
   > This can be done via `docker build` and a `Dockerfile`, avoiding
   > rebuilding layers that are less-frequently modified.
7. Create a new Raspberry Pi OS image file.
8. Make final adjustments to the image, specific to the target hardware.
9. Export and copy to an SD card.

## Getting Started

To get started, you need the `rpiimagetool` `docker` image. Currently, you will need to
build this yourself.

From the root of this project, execute:

```bash
git clone https://github.com/BobKerns/rpi-image-tool
cd rpi-image-tool
docker build --pull --rm -f "Dockerfile" -t rpiimagetool:latest "."
. setup.sh
```

The script [`setup.sh`](setup.sh) adds the directory with our top-level commands to your
`PATH` environment variable.

## Usage

For ease of use, this is packaged behind these front-end scripts:

* [`rpi-image-tool`](doc/bin/rpi-image-tool.md): The main tool
* [`grow-root-fs`](doc/bin/grow-root-fs.md): Increase the size of the root filesystem
* [`dockerify`](doc/bin/dockerify.md): Import a Rasperry Pi boot image file as a docker container.
* [`undockerify`](doc/bin/undockerify.md): Export a Rasperry Pi boot image file from a `pi` docker container
* [`pi`](doc/bin/pi.md): Invoke a Raspberry Pi container.
  * Can be used to explore, validate, or test.
  * Can be used to perform scripted setup awkward with `docker` builds.
* [`setup-disk`](doc/bin/setup-disk.md): Create a thinly-provisioned filesystem image to

## Additional Resources

* [Running Pi OS On Any Hardware](doc/pi-os-anywhere.md)
* [Scripting](doc/scripting.md)
* [Extending the Rasperry Pi OS Image Tool](doc/extending.md)
* [Non-Raspberry Pi OS images](doc/non-raspos.md)
* [FAQ](doc/faq.md)

## External documentation

* [Docker](https://docs.docker.com/reference/)
* [`docker build`](https://docs.docker.com/engine/reference/commandline/build/)
* [`docker buildx`](https://docs.docker.com/engine/reference/commandline/build/)
* [`docker run`](https://docs.docker.com/engine/reference/commandline/run/)
* [Updating and Upgrading Raspberry Pi OS](https://www.raspberrypi.com/documentation/computers/os.html#updating-and-upgrading-raspberry-pi-os)
* [Raspberry Pi OS (64-bit) (download)](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-64-bit)
* [The `config.txt` file](https://www.raspberrypi.com/documentation/computers/config_txt.html)
* [`losetup`](https://man7.org/linux/man-pages/man8/losetup.8.html)
* [`kpartx`](https://man7.org/linux/man-pages/man8/losetup.8.html)
