#!/bin/sh
#-----------------------------------------------------------------------------
#
#  tirex-create-stats-and-update-tiles.sh
#
#  This is an script that creates statistics for existing tiles and updates
#  the oldest tiles. You can start it every few hours from cron.
#
#  Note that creating the tile statistics can take a long time, because
#  every metatile file on the disk has to be found and stat()ed. Depending
#  on how many tiles you have and hour fast your system is, you might want
#  to run this script only once per day
#
#  Arguments:
#   - command line arguments: replace default map settings
#   - environment variable ENABLED: enable tirex batch update
#   - environment variable JOIN: enable/disable joined handling of all maps
#   - environment variable OLDEST: number of tiles to pass to rendering
#   - environment variable STOPRENDERING: enable/disable rendering during runtime
#  Example:
#  ENABLED=true OLDESTNUM=10000 tirex-create-stats-and-update-tiles.sh mymap1 mymap2
#-----------------------------------------------------------------------------

# how many of the oldest metatiles should be put into the queue?
if [ -z "$OLDESTNUM" ]; then
    OLDESTNUM=5000
fi

# maps that we want the statistics for (replaced by args)
if [ -z "$*" ]; then
    MAPS="default osm"
else
    MAPS=$*
fi

# pass data to tirex
if [ -z "$ENABLED" ]; then
    ENABLED="false"
fi

# join data from all maps instead of handling them individual
if [ -z "$JOIN" ]; then
    JOIN="true"
fi

# enable/disable rendering
if [ -z "$STOPRENDERING" ]; then
    STOPRENDERING="true"
fi

#-----------------------------------------------------------------------------

# append output to logfile
exec >>/var/log/tirex/tirex-create-stats-and-update-tiles.log 2>&1

# do not run if this lockfile exists, because the osm database is updated
# (you only need this if you have some other script that touches this file
# when the database is beeing updated)
[ -f /osm/update/osmupdate.lock ] && exit

# directory where the statistics should go
DIR=/var/lib/tirex/stats

DATE=`date +%FT%H`

echo "--------------------------------------"
echo -n "Starting "
if [ $ENABLED != "false" ]; then
    echo -n "(rendering $OLDESTNUM tiles) "
else
    echo -n "(not rendering $OLDESTNUM tiles) "
fi
date

# stop background rendering
if [ $STOPRENDERING != "false" ]; then
    tirex-rendering-control --debug --stop
fi

# find old statistics files (from earlier runs of this script) and remove them
find $DIR -type f -mtime +1 -name tiles-\* | xargs --no-run-if-empty rm

if [ $JOIN != "false" ]; then
    >$DIR/tiles-$DATE-ALLMAPS.csv
fi

for MAP in $MAPS; do
    # check tile directory and create statistics
    tirex-tiledir-check --list=$DIR/tiles-$DATE-$MAP.csv --stats=$DIR/tiles-$DATE-$MAP.stats $MAP

    # link tiles.stats to newest statistics file
    rm -f $DIR/tiles-$MAP.stats
    ln -s tiles-$DATE-$MAP.stats $DIR/tiles-$MAP.stats

    if [ $JOIN != "false" ]; then
        cat $DIR/tiles-$DATE-$MAP.csv >> $DIR/tiles-$DATE-ALLMAPS.csv
    else
        # find $OLDESTNUM oldest metatiles...
        sort --field-separator=, --numeric-sort --reverse $DIR/tiles-$DATE-$MAP.csv | head -$OLDESTNUM | cut -d, -f4 >$DIR/tiles-$DATE-$MAP.oldest

        # ...and add them to tirex queue
        if [ $ENABLED != "false" ]; then
            tirex-batch --prio=20 <$DIR/tiles-$DATE-$MAP.oldest
        fi
    fi
done

if [ $JOIN != "false" ]; then
    sort --field-separator=, --numeric-sort --reverse $DIR/tiles-$DATE-ALLMAPS.csv | head -$OLDESTNUM | cut -d, -f4 >$DIR/tiles-$DATE-ALLMAPS.oldest
    if [ $ENABLED != "false" ]; then 
        tirex-batch --prio=20 <$DIR/tiles-$DATE-ALLMAPS.oldest
    fi
fi

# re-start background rendering
if [ $STOPRENDERING != "false" ]; then
    tirex-rendering-control --debug --continue
fi

echo -n "Done "
date

#-- THE END ----------------------------------------------------------------------------
