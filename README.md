# undead-bootstrap

Like live-bootstrap, but not totally (a)live

## Summary

This project intends to (regularly, but manually triggered) run [live-bootstrap](https://github.com/fosslinux/live-bootstrap)
in chroot mode on GitHub CI and provide both the input source archives (distfiles) and output files (packages) for
[download](https://github.com/schierlm/undead-bootstrap/releases/).

See the link to the submodule in the file listing above to find out which version of live-bootstrap has last been run.

Work is split into four steps (running as separate CI jobs):
- First step builds everything up to `bash` and creates a tarball of the distfiles and the results.
- Second step builds up to the sysc switch (including Linux kernel, but excluding kexec-tools), and creates a tarball of the packages.
- Third step builds up to `binutils-2.38` (automatically skipping what has been built before), again building a tarball of the packages.
- Fourth step builds to the end (automatically skipping what has been built before), again building a tarball of the packages.

Nondistributable binaries (heirloom-devtools) are excluded from the first step build and rebuilt in every subsequent step.
In case build steps take noticably longer than an hour, I'll split up the steps further (by patching the build skript to exit early
based on `${STEPNUMBER}` environment variable).

## Trivia

The name of the project is a pun on `live-bootstrap` and the fact that running it on CI is not actually "(a)live", but not "dead" either,
combined with the upcoming holiday that is said to be confused with Christmas by mathematicians (as `OCT 31 == DEC 25`).
