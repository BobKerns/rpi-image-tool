# `grow-root-fs` (command)

Usage:

> `grow-root-fs` (`add` | `set`) *amt* [ `B` | `K` | `M` | `G` ]

[*Source*](../../bin/grow-root-fs)

In the current image, grow the partition for the root filesystem, and expand the filesystem.

This is useful for simple workflows that copy files to the root filesystem, or as a first
step in more complex workflows where files are added that are too large for the filesystem,
prior to transferring the image to a `docker` image.

You probably don't need this if you are installing packages inside a `docker` container, as
a new image file will be created as a result.
