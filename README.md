# Tirex Tile Rendering System

Tirex is a bunch of tools that let you run a tile server. A tile server
is a web server that hands out pre-rendered map raster images to clients.

The web page for Tirex is at http://wiki.openstreetmap.org/wiki/Tirex .
See there for more information.

## Prerequisites

You'll need the following Perl modules to run Tirex:

* IPC::ShareLite (Debian/Ubuntu: libipc-sharelite-perl)
* JSON           (Debian/Ubuntu: libjson-perl)
* GD             (Debian/Ubuntu: libgd-gd2-perl)
* LWP            (Debian/Ubuntu: libwww-perl)

You'll need a C++ compiler and build tools to compile the Mapnik backend.

## Building

To build Tirex run

    make

in the main directory. This will compile the mapnik backend and create
the man pages for the Perl modules.

Call 'make clean' to cleanup after a 'make'.

## Installing

To install Tirex call

    make install

as root user. This will install the main parts of Tirex including the
tirex-master, tirex-backend-manager and the Mapnik backend.

This will not install the example map, or the munin or nagios plugins.
To install those, call

    make install-example-map
    make install-munin
    make install-nagios

respectively. You can also install everything with

    make install-all

## Debian & Ubuntu

### `git-buildpackage`, `cowbuilder` & Backports

[Geofabrik](https://www.geofabrik.de/) maintains backports of Tirex on it's
[github fork](https://github.com/geofabrik/tirex).

| OS                                   | Branch                                                                       |
|--------------------------------------|------------------------------------------------------------------------------|
| Ubuntu 24.04.2 LTS (Noble Numbat)    | [`geofabrik/noble`](https://github.com/geofabrik/tirex/tree/geofabrik/noble) |
| Ubuntu 22.04.2 LTS (Jammy Jellyfish) | [`geofabrik/jammy`](https://github.com/geofabrik/tirex/tree/geofabrik/jammy) |

To build these backports, clone the repo, switch to the branch and call:

	gbp buildpackage --git-pbuilder --git-ignore-branch --git-dist=DIST

(e.g. `… --git-dist=noble`).

This will produce files like `tirex_0.8.0-1~geofabriknoble1_amd64.deb`

The Debian GIS Team's guide to [Packaging with
Git](https://debian-gis-team.pages.debian.net/policy/packaging.html#git-packaging),
explains how to set up a build environment, and [create a cowbuilder
environment](https://debian-gis-team.pages.debian.net/policy/packaging.html#git-pbuilder).

Geofabrik makes no guarantee that the backport(s) will work for the duration
that the OS release is supported upstream.

### Directly building

To create Debian/Ubuntu packages you need the package 'devscripts'
installed. Call

    make deb

to create the packages. The following packages will be created in the parent
directory:

    tirex

Call 'make deb-clean' to cleanup after a 'make deb'.

### Packages in OS

This package is also maintained in Debian by the [Debian GIS Team](https://wiki.debian.org/Teams/DebianGis).

 * [Debian packages](https://packages.debian.org/search?keywords=tirex)
 * [Ubuntu packages](https://packages.ubuntu.com/search?keywords=tirex)
 * [Debian Salsa/git packaging repo](https://salsa.debian.org/debian-gis-team/tirex)

## TESTS

Call 'prove' in the main directory to run Perl unit tests. You need Test::More
(Debian/Ubuntu: libtest-simple-perl) and Test::Harness (Debian/Ubuntu:
libtest-harness-perl) installed.

There are some other tests in the 'test' directory. See the description at the
beginning of the scripts for information on how to use them.

