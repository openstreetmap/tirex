#!/bin/sh
#
#  renderd-test.sh
#
#  You can use this script to test the tirex-renderd-test renderer
#  without the renderd-manager.
#

export TIREX_RENDERD_NAME="test"
export TIREX_RENDERD_PORT=9330
export TIREX_RENDERD_SYSLOG_FACILITY="local0"
export TIREX_RENDERD_MAPFILES="etc/maps/test.conf.dist"
export TIREX_RENDERD_DEBUG=1
export TIREX_RENDERD_PIPE_FILENO=1
export TIREX_RENDERD_ALIVE_TIMEOUT=10

exec perl -Ilib bin/tirex-renderd-test

