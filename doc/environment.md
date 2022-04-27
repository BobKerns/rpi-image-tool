# Environment Variables for `rpi-image-tool`

The following environment variables are set up prior to invoking the
[`rpi-image-tool](bin/rpi-image-tool.md) subcommand scripts:

## From the host environent

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
  * Non-null iff `--interactive` is specified, or if the command to run is
   `bash`, `vi`, `nano`, or `emacs`.
* `PI_BUILDER`
  * The name:tag of the docker container that performs the work.
* `PI_VOLUME_SUFFIX`
  * The suffix for the name of the docker volume used to hold the image and intermediate
    work.
* `PI_VOLUME`
  * The full name of the docker volume used to hold the image and intermediate work.

## In the builder

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
  * The current working directory on the host. Paths to load will be relative to this.
    This can be set in the host environment to pin it to a directory independently of the
    working directory.
* `PI_SAVED`
  * The `saved/` subdirectory on the host, where unmodified copies of files to be modified
    are placed.
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
  * If set non-blank, the start script will skip the step of mapping and mounting the image
    filesystems.

    This happens before the supplied subcommand script is run; it can be set in a
    `.override` file for the script or with the `--no-mount` command line option.
