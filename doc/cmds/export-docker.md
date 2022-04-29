# `export-docker` (subcommand)

Usage:
> `rpi-image-tool export-docker` *file*

* *file* defaults to '-', meaning `stdout`, suitable for piping to the `docker import`
  command.

[*Source*](../../cmds/export-docker)

The `dockerify` subcommand to the [`rpi-image-tool`](../bin/rpi-image-tool.md) produces a
`tar` file suitable for import by `docker`, excluding content that should not be imported.

It is used by the [`dockerify` script](../bin/dockerify.md), which coordinates generation
with importing the result into a `docker` image.
