# Scripting

Random one-off updates and modifications are to be discouraged.
To achieve a repeatable process, _all_ setup should be scripted.
Systematically enabling that is the primary purpose of this tool.

If you supply a script to `rpi-image-tool` all of the subcommands will be regular `bash` commands.

The `--interactive` mode (and the availability of `bash`, `emacs`, `vi`, or `nano`) are useful for working
out just what is required, but the result should be captured in a setup script.

`rpi-image-tool` in non-interactive mode outputs to `stdout` and `stderr` appropriately, making it
friendly for use in scripts itself, perhaps as step near the end of a larger build process.
