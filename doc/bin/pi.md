# `pi` (command)

Usage:

> `pi` *options*\* *imageName* [*cmd*] *args*\*

[*Source*](../../bin/pi)

Run a Raspberry Pi `docker` image.

In addition to the usual `docker` options, *options*, may contain:

* `--nodefault` | `--default`:
  > By default, the `pi` command supplies `--interactive`, `--tty`, and `--rm` for an interactive terminal session to the pi image. `--nodefault` overrides this, allowing for
  other use cases.
* `--disk` *disk*
  > *disk* can be either a filename or a name, PARTUUID, UID, LABEL, PARTLABEL, or ID, as found by
  > `setup-disk --find` *disk*.
  >
  > The disk will be bind-mounted into the container under `/dev/host/`*disk*, and made
  > available for mounting via `LABEL=` or `UUID=`. The other identifiers are not supported.

The current working directory is mounted as `/mnt/host`, and made the working directory in
the container.
