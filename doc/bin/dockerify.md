# `dockerify` (command)

Usage:

> `dockerify` [ `--platform` *platform* ] [ `--message` *msg* ] [ `--change` *change* ] *imageName*

[*Source*](../../bin/dockerify)

Create a `docker` image *imageName* from the current image, after committing any pending changes.

e.g.:

```bash
dockerify pi:latest
```

This image can then be run (on any platform) via the [`pi`](pi.md) command.

The `--platform` argument defaults to `linux/arm64`. This allows for potential use with
32-bit or other architectures.

The `--message` and `--change` arguments, if supplied, are passed to
[`docker import`](https://docs.docker.com/engine/reference/commandline/import/)
