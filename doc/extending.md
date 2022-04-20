# Extending the Raspberry Pi OS Image Tool

The `rpi-image-tool` can be extended in three ways.

1) Scripts in or below the current directory can be referenced by relative pathname and be invoked.
They will be run in-context and can access the mounted filesystems, use the
environment variables, and run the other subcommands directly.

2) Scripts placed in a `cmds/` subdirectory of the current directory will be on the `$PATH`, and thus
can be referenced by name, without the `cmds/` prefix.

3) The docker container can be extended by copying additional subcommand scripts to `/data/cmds`
in your `Dockerfile`

e.g.:

```docker
FROM rpiimagetool:latest
COPY mycmds/ /data/cmds
```

You can build your new container image via:

```bash
docker build --pull --rm -f Dockerfile -t mytool:latest
```

Setting `$PI_BUILDER` to your new image will cause it to be used instead of the default,
or you can supply the `--builder <image:tag>` option to `rpi-image-tool`.

Scripts should be self-documenting by including a documentation comment at the start.
Documentation comments are a block of comments starting with `'#### '`.
Parameter substitution is performed, so you can reference environment variables or
invoke shell commands to generate the documentation output.

The scripts should follow the following format:

```bash
#!/bin/bash

#### This is a documentation comment
#### Usage: ${PI_INVOKER} [--myflag] myarg
####
#### The space after the #### is required, unless the line is blank.

# This sets up variables and utility shell functions, and ensures
# that the --help, --verbose, and --debug options are handled uniformly.
. "${PI_INCLUDES}/vars.sh"

echo <<EOF
Your code here.
You may invoke non-bash tools with 'exec', e.g. 'exec node mysripts/my-node-script'
This would be prefered over forcing my-node-script into the necessary form.
EOF

exec node myscripts/my-node-script
```

A few commands may need to alter the setup, such as skipping the mounting of the image filesystems.
To accomplish this for a script `myscript`, create a file `myscript.override`. Setting the variable `PI_NO_MOUNT` will suppress the mounting. You can use the bash function `do_mount_all` to later mount
the filesystems (or `find_partions` to map the devices and set the environment variables w/o mounting
the filesystems).

## Environment Variables

The following environment variables are set up prior to invoking the subcommand scripts:

### From the host environent

* `PI_USER_CWD`
  * The current working directory in the host
* `PI_USER_NAME`
  * The host user invoking the builder
* `PI_USER_IMAGE_FILE`
  * The image file path as supplied by the user, for error reporting
* `PI_IMAGE_FILE_ABSOLUTE`
  * The absolute path of the image file in the host environment, for error reporting.
* `PI_INVOKER_BASE`
  * The name of the command used to invoke the builder, for help messages and errors.
* `PI_INVOKER`
  * The help message to use for the builder script and options, up to the subcommand.
* `PI_INTERACTIVE`
  * Non-null iff `--interactive` is specified, or if the command to run is `bash`, `vi`, `nano`, or `emacs`.
* `PI_BUILDER`
  * The name:tag of the docker container that performs the work.
* `PI_VOLUME_SUFFIX`
  * The suffix for the name of the docker volume used to hold the image and intermediate work.
* `PI_VOLUME`
  * The full name of the docker volume used to hold the image and intermediate work.

### In the builder

* `PI_INCLUDES`
  * The directory that holds scripts to be sourced.
* `PI_CMDS`
  * The directory that contains the subcommands.
* `PI_WORKDIR`
  * The initial working directory for commands.
* `PI_BUILD`
  * A directory for storing values to be stored into the image
* `PI_TMP`
  * A temporary directory
* `PI_HOST_DIR`
  * The current working directory on the host. Paths to load will be relative to this. This can be set in the
    host environment to pin it to a directory independently of the working directory.
* `PI_SAVED`
  * The `saved/` subdirectory on the host, where unmodified copies of files to be modified are placed.
* `PI_ROOT`
  * The path to the mounted root filesystem from the image
* `PI_BOOT`
  * The path to the mounted boot filesystem from the image
* `PI_VERBOSE`
  * non-empty if the `--verbose` flag was supplied.
* `PI_DEBUG`
  * non-empty if the `--debug` flag was supplied
* `PI_BOOTDEV`
  * The device name from which the image boot filesystem is mounted.
* `PI_ROOTDEV`
  * The device name from which the image root filesystem is mounted.
* `PI_LOOPDEV`
  * The device name for the full image file as a block device.
* `PI_IMAGE_FILE`
  * The path to the image to be processed.
* `PI_NO_MOUNT`
  * If set non-blank, the start script will skip the step of mapping and mounting the image filesystems.
    This happens before the supplied subcommand script is run; it can be set in a `.override` file for
    the script or with the `--no-mount` command line option.
