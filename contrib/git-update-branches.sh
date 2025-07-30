#! /bin/sh
cd "$(dirname $0)/../" || exit 1


git fetch git@github.com:geofabrik/tirex.git
git fetch git@salsa.debian.org:debian-gis-team/tirex.git

for BRANCH in main geofabrik/noble geofabrik/jammy debian/latest ; do
	git push git@github.com:geofabrik/tirex.git "$BRANCH"
done
