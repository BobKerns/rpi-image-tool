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
