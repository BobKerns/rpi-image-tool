# `pi` (command)

Usage:

> `pi` *options*\* *imageName* [*cmd*] *args*\*

[*Source*](../../bin/pi)

Run a Raspberry Pi `docker` image.

*cmd* defaults to `bash`.

In addition to the usual `docker` options, *options*, may contain:

* `--no-interactive` | `--interactive`:
  > The `pi` command defaults to `--interactive`. `--no-interactive` overrides this.
* `--no-tty` | `--tty`:
  > The `pi` command defaults to `--tty`. `--no-tty` overrides this.
  >
  > With `--no-tty`, `stdout` and `stderr` are distinct streams. `--tty` combines them before forwarding
  > from the container.
* `--no-rm` | `--rm`:
  > The `pi` command defaults to `--rm`, removing the container after each run. `--no-rm`
  > overrides this, leaving the container alive.
* `--platform` *platform*:
  > The `pi` command defaults this to the value in the image. If the image is wrong,
  > you can override it.
* `--disk` *disk*:
  > *disk* can be either a filename or a name, PARTUUID, UID, LABEL, PARTLABEL, or ID, as found by
  > `setup-disk --find` *disk*.
  >
  > The disk will be bind-mounted into the container under `/dev/host/`*disk*, and made
  > available for mounting via `LABEL=` or `UUID=`. The other identifiers are not supported.
* `--commit` *tag*:
  > Commit any changes made in the running of this container to a new image tagged *tag*.
  >
  > Use this for scripted building.
* `--systemd`:
  > Like `--init`, excepts runs `systemd` as the init process.
  >
  > This can be used to validate `systemd` configuration, or to enable installation of
  > packages that expect it to be running.

The current working directory is mounted as `/mnt/host`, and made the working directory in
the container, unless overridden with `--workingdir` *directory*.
