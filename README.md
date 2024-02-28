# Tirex Tile Rendering System

Tirex is a bunch of tools that let you run a tile server. A tile server
is a web server that hands out pre-rendered map raster images to clients.

The web page for Tirex is at http://wiki.openstreetmap.org/wiki/Tirex .
See there for more information.

## PREREQUISITES

You'll need the following Perl modules to run Tirex:

* IPC::ShareLite (Debian/Ubuntu: libipc-sharelite-perl)
* JSON           (Debian/Ubuntu: libjson-perl)
* GD             (Debian/Ubuntu: libgd-gd2-perl)
* LWP            (Debian/Ubuntu: libwww-perl)

You'll need a C++ compiler and build tools to compile the Mapnik backend.

## BUILDING

To build Tirex run

    make

in the main directory. This will compile the mapnik backend and create
the man pages for the Perl modules.

Call 'make clean' to cleanup after a 'make'.

## INSTALLING

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

## DEBIAN/UBUNTU

To create Debian/Ubuntu packages you need the package 'devscripts'
installed. Call

    make deb

to create the packages. The following packages will be created in the parent
directory:

    tirex
    tirex-backend-mapnik
    tirex-backend-wms
    tirex-backend-mapserver
    tirex-example-map
    tirex-munin-plugin
    tirex-nagios-plugin
    tirex-syncd

Call 'make deb-clean' to cleanup after a 'make deb'.

## TESTS

Call 'prove' in the main directory to run Perl unit tests. You need Test::More
(Debian/Ubuntu: libtest-simple-perl) and Test::Harness (Debian/Ubuntu:
libtest-harness-perl) installed.

There are some other tests in the 'test' directory. See the description at the
beginning of the scripts for information on how to use them.

