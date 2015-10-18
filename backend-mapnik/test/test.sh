#!/bin/sh

if [ -f ne_110m_admin_0_countries.shp ]
then 
    :
else
    wget -O admin.zip http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/110m/cultural/ne_110m_admin_0_countries.zip
    unzip -o admin.zip
    rm -f admin.zip 
    rm -f ne_110m_admin_0_countries.README.html
    rm -f ne_110m_admin_0_countries.VERSION.txt
fi 

TILEDIR=/tmp/tile$$.dir
mkdir $TILEDIR

cat > test.conf <<EOF
name=test
tiledir=$TILEDIR
mapfile=test.xml
EOF

if [ -f test.xml ]
then
   :
else
   cat > test.xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<Map srs="+init=epsg:3857" background-color="#b5d0d0">
<Style name="countries">
  <Rule>
     <LineSymbolizer stroke-width="0.5" stroke="#808080" />
     <PolygonSymbolizer fill="#eeeeee" />
  </Rule>
</Style>

<Layer name="countries" srs="+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs">
    <StyleName>countries</StyleName>
    <Datasource>
       <Parameter name="type"><![CDATA[shape]]></Parameter>
       <Parameter name="file"><![CDATA[ne_110m_admin_0_countries.shp]]></Parameter>
    </Datasource>
</Layer>
</Map>
EOF
fi

FONTDIR=/tmp/font$$.dir
mkdir $FONTDIR

export TIREX_BACKEND_CFG_plugindir=/usr/lib/mapnik/input
export TIREX_BACKEND_CFG_fontdir=$FONTDIR
export TIREX_BACKEND_CFG_fontdir_recurse=0
export TIREX_BACKEND_CFG_MAP_CONFIGS=test.conf
export TIREX_BACKEND_PORT=9330
export TIREX_BACKEND_SYSLOG_FACILITY=local0
export TIREX_BACKEND_MAP_CONFIGS=test.conf
export TIREX_BACKEND_DEBUG=1
export TIREX_BACKEND_PIPE_FILENO=1
export TIREX_BACKEND_ALIVE_TIMEOUT=10

echo starting backend...
../backend-mapnik > /dev/null 2>&1 &
PID=$!
sleep 2
echo sending query...
echo "id=1
map=test
prio=1
type=metatile_render_request
x=0
y=0
z=3" | nc -w 5 -u localhost  $TIREX_BACKEND_PORT > nc.out.$$

MT=`grep metatile= nc.out.$$ |cut -d= -f2`
RS=`grep result= nc.out.$$ |cut -d= -f2`

rm -f nc.out.$$
rmdir $FONTDIR
kill $PID

if [ "$RS" = "ok" ]
then
   if [ -f $MT ]
   then
      echo looks ok - check $MT with viewmeta.pl
      exit 0
   fi
fi

echo something is wrong
