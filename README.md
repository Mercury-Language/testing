Automated testing of Mercury ROTDs
==================================

`runtests.sh` downloads the latest ROTD from <http://dl.mercurylang.org> and
runs a series of bootchecks. It is designed to be run as a cron job, and
should be mostly portable to any Unix-like system (adapt as required).

Configuration occurs in the `conf` file. Each "test platform" can be further
customised in a `conf.<platform>` file.

The output is a directory of HTML and log files, to be served by a web server
of your choosing.
