# `dockerify` (command)

Usage:

> `dockerify` *imageName*

[*Source*](../../bin/dockerify)

Create a `docker` image *imageName* from the current image, after committing any pending changes.

e.g.:

```bash
dockerify pi:latest
```

This image can then be run (on any platform) via the [`pi`](pi.md) command.
