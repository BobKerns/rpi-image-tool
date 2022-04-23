# FAQ

## Why is it all written in `bash`?

I thought this was going to be simple. But as I ran into more and more roadblocks, I had to
perform a vast array of experiments, and it started getting more complex. But at each stage,
the process has entailed running commands from bash to see what they do. The script being
done in bash makes it simple to incorporate those strips.

I may reimplement some of the more complex parts, probably in `python`. But I'd like to
preserve the ability to easily add functionality as simple `bash` scripts.

But I recognize that one needs to know `bash` scripting well to be able to really understand
much of this, and `bash` scripts come with asome degree of fragility and other issues of
maintainability.

## Why `docker`?

By containerizing, dependence on user environment and setup is minimized. The same core code will operate identicially on any host environment.

The most complex, [`rpi-image-tool`](bin/rpi-image-tool), handles environment variables and sets up volume and bind mounts for the container.

The only exposure to the host OS are the scripts in the `bin/` directory, each of which simply handles parameters and invokes `docker` appopriately.

## Why are images stored in a `docker` volume?

This prevents any issues of interference from the host operating system. It might also
provide a performance advantage, but I haven't benchmarked it.

Working on a copy of the original ensures repeatability. Host files are never modified, and
only final results are written.

## Why do the docker images have to be run with `--privileged`?

Unfortunately, docker containers implement loop devices in a way that requires this. Even doing `--cap-add ALL` is insufficient. We use loop devices to access image files as if they
were block devices, so we can partition, format, resize, and mount them.

Doing it in userspace with a `fuse` filesystem would be preferable, but there is no robust `fuse` filesystem driver for `ext4` that supports writing.

Aside from the obvious security implications, loop devices end up being shared between privileged containers, which can be a problem if they are not properly cleaned up.

The scripts attempt to ensure proper cleanup, but when it fails to happen, you may have to
clean up manually from a bash prompt inside a container, using `losetup -d <device>` and `kpartx -d <device>`. You often need both.

## What are the obvious security implications mentioned above?

Basically, script code can do things that affect the host or other containers, so you don't have the usual isolation and should be extra careful about untrusted scripts.

But you probably aren't going to be running untrusted scripts, assuming you trust this
package and me. But I encourage you to distrust this package and me, and audit the code
for yourself.

## A package I need isn't included in the tool. How can I add it?

You have two choices: add it to the layer in the [`Dockerfile](../Dockerfile) that does
`apt-get install`, or create your own `Dockerfile` that begins with `FROM rpiimagetool`
and adds it.

Modifying the existing `Dockerfile` is the way to go if you're going to do a pull request
so others can get the benefit.

Creating your own is the better choice when it's for your private needs. Then you won't
have to worry about mergeing in changes; your contriution will be a layer atop the existin
tool.

## Why is it so slow?

There is a lot of data copying, plus running the pi image involves emulation using `quemu`,
so may be slower, depending on the relative speeds of the host processor vs an actual Pi.

1. The original image is copied to a docker container (and decompressed if needed).
2. The files in the image are copied to a `tar` file via a pipe, then untarred into
   a Rasperry Pi `docker` image.
3. Any needed packages are downloaded and installed into the Pi `docker` image.
   * The download may be cached, saving time on subsequent runs.
4. The files from the Pi image are then tarred, piped, and written to a new disk image.
5. The disk image is then optionally compressed into a `.zip` file.
6. The result is then copied back to the host filesystem.
