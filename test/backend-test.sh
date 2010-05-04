#!/bin/sh
#
#  backend-test.sh
#
#  You can use this script to test a backend
#  without the tirex-backend-manager.
#

export TIREX_BACKEND_NAME="test"
export TIREX_BACKEND_PORT=9330
export TIREX_BACKEND_SYSLOG_FACILITY="local0"
export TIREX_BACKEND_MAPFILES="etc/renderer/test/checkerboard.conf.dist"
export TIREX_BACKEND_DEBUG=1
export TIREX_BACKEND_PIPE_FILENO=1
export TIREX_BACKEND_ALIVE_TIMEOUT=10

exec perl -Ilib backends/test

