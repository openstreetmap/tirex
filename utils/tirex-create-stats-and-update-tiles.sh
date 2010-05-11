#!/bin/sh
#-----------------------------------------------------------------------------
#
#  tirex-create-stats-and-update-tiles.sh
#
#  This is an example script that creates statistics for existing tiles and
#  updates the oldest tiles. You can adapt it to your needs and start it every
#  few hours from cron.
#
#  Note that creating the tile statistics can take a long time, because
#  every metatile file on the disk has to be found and stat()ed. Depending
#  on how many tiles you have and hour fast your system is, you might want
#  to run this script only once per day
#
#-----------------------------------------------------------------------------

# how many of the oldest metatiles should be put into the queue?
OLDESTNUM=5000

# map that we want the statistics for
MAP=default

#-----------------------------------------------------------------------------

# append output to logfile
exec >>/var/log/tirex/do-tirex-stats-and-update.log 2>&1

# do not run if this lockfile exists, because the osm database is updated
# (you only need this if you have some other script that touches this file
# when the database is beeing updated)
[ -f /osm/update/osmupdate.lock ] && exit

# directory where the statistics should go
DIR=/var/lib/tirex/stats

DATE=`date +%FT%H`

echo "--------------------------------------"
echo -n "Starting "
date

# stop background rendering
tirex-rendering-control --debug --stop

# find old statistics files (from earlier runs of this script) and remove them
find $DIR -type f -mtime +1 -name tiles-\* | xargs --no-run-if-empty rm

# check tile directory and create statistics
tirex-tiledir-check --list=$DIR/tiles-$DATE-$MAP.csv --stats=$DIR/tiles-$DATE-$MAP.stats $MAP

# link tiles.stats to newest statistics file
rm -f $DIR/tiles-$MAP.stats
ln -s $DIR/tiles-$DATE-$MAP.stats $DIR/tiles-$MAP.stats

# find $OLDESTNUM oldest metatiles...
sort --field-separator=, --numeric-sort --reverse $DIR/tiles-$DATE-$MAP.csv | head -$OLDESTNUM | cut -d, -f4 >$DIR/tiles-$DATE-$MAP.oldest

# ...and add them to tirex queue
tirex-batch --prio=20 <$DIR/tiles-$DATE-$MAP.oldest

# re-start background rendering
tirex-rendering-control --debug --continue

echo -n "Done "
date

#-- THE END ----------------------------------------------------------------------------
