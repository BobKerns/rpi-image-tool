# `pi` (command)

Usage:

> `pi` *options*\* *imageName* [*cmd*] *args*\*

[*Source*](../../bin/pi)

Run a Raspberry Pi `docker` image.

In addition to the usual `docker` options, *options*, may contain:

* `--nodefault` | `--default`:
  > By default, the `pi` command supplies `--interactive`, `--tty`, and `--rm` for an interactive terminal session to the pi image. `--nodefault` overrides this, allowing for
  other use cases.

The current working directory is mounted as `/mnt/host`, and made the working directory in
the container.
