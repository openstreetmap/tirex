/* =====================================================================

  Tirex Tileserver

  Tileserver for the Tirex system using node.JS (www.nodejs.org).

  http://wiki.openstreetmap.org/wiki/Tirex

========================================================================

  Copyright (C) 2011  Jochen Topf <jochen.topf@geofabrik.de>
  
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with this program; If not, see <http://www.gnu.org/licenses/>.

===================================================================== */

var util  = require('util');
var net   = require('net');
var http  = require('http');
var url   = require('url');
var path  = require('path');
var fs    = require('fs');
var dgram = require('dgram');

// size in bytes of metatile header
var metatile_header_size = 20 + 8 * 64;

// open http connections waiting for answer
var open_connections = {};

// number of open http connections waiting for answer
var num_open_connections = 0;

var stats = {
    tiles_requested: 0,
    tiles_from_cache: 0,
    tiles_rendered: 0,
    http_requests: 0
};

var config = {
    configdir: '/etc/tirex',
    master_udp_port: 9322,
    tileserver_http_port: 9320
};

// =====================================================================

// get long value at offset from buffer
Buffer.prototype.getLong = function(offset) {
    return ((this[offset+3] * 256 + this[offset+2]) * 256 + this[offset+1]) * 256 + this[offset];
};

// =====================================================================

function send_image(x, y, z, fd, response) {
    var buffer = new Buffer(metatile_header_size);
    fs.read(fd, buffer, 0, metatile_header_size, 0, function(err, bytesRead) {
        if (err || bytesRead !== metatile_header_size) {
            response.writeHead(500, { 'Content-Type': 'text/plain' });
            response.end('Metatile error\n');
            fs.close(fd);
            return;
        }

        var pib = 20 + ((y%8) * 8) + ((x%8) * 64); // offset into lookup table in header

        var offset = buffer.getLong(pib);
        var size   = buffer.getLong(pib+4);

        var png = new Buffer(size);
        fs.read(fd, png, 0, size, offset, function(err, bytesRead) {
            if (err || bytesRead !== size) {
                response.writeHead(500, { 'Content-Type': 'text/plain' });
                response.end('Metatile error\n');
                fs.close(fd);
                return;
            }
            response.writeHead(200, {
                'Content-Type': 'image/png',
                'Content-Length': size
            });
            response.end(png);
            fs.close(fd);
        });
    });
}

function serialize_tirex_msg(msg) {
    var string = '', k;
    for (k in msg) {
        string += k + '=' + msg[k] + '\n';
    }
    return string;
}

function deserialize_tirex_msg(string) {
    var lines = string.split('\n');
    var msg = {}, i;
    for (i=0; i < lines.length; i++) {
        var line = lines[i].split('=');
        if (line[0] !== '') {
            msg[line[0]] = line[1];
        }
    }
    return msg;
}

function xyz_to_filename(x, y, z) {
    var path_components = [], i, v;

    // make sure we have metatile coordinates
    x -= x % 8;
    y -= y % 8;

    for (i=0; i <= 4; i++) {
        v = x & 0x0f;
        v <<= 4;
        v |= (y & 0x0f);
        x >>= 4;
        y >>= 4;
        path_components.unshift(v);
    }

    path_components.unshift(z);

    return path_components.join('/') + '.meta';
}

function fingerprint(map, z, x, y) {
    return [map, z, x, y].join('/');
}

function store_connection(req, res, map, z, x, y) {
    var l = fingerprint(map, z, x - x%8, y - y%8);

    if (! open_connections[l]) {
        open_connections[l] = [];
    }
    open_connections[l].push({ res: res, map: map, x: x, y: y, z: z });
}

function get_connections(map, z, x, y) {
    var l = fingerprint(map, z, x, y);

    var connections = open_connections[l];
    delete open_connections[l];

    return connections;
}

// for debugging only
function dump_open_connections() {
    var oclist = '', oc;
    for (oc in open_connections) {
        oclist += oc + '/' + open_connections[oc].length + ' ';
    }
    console.log("oc:", oclist);
}

function not_found(response, text) {
    response.writeHead(404, {'Content-Type': 'text/plain'});
    response.end((text || 'Not found') + '\n');
}

/* =====================================================================

  Read config

===================================================================== */

var maps = {};

var renderers = fs.readdirSync(config.configdir + '/renderer');

var i, j;
for (i=0; i < renderers.length; i++) {
    var rdir = config.configdir + '/renderer/' + renderers[i];
    if (fs.statSync(rdir).isDirectory()) {
        var files = fs.readdirSync(rdir);
        for (j=0; j < files.length; j++) {
            var mapfile = rdir + '/' + files[j];
            var cfg = fs.readFileSync(mapfile, 'utf-8');
            var lines = cfg.split('\n');
            var map = { minz: 0, maxz: 0, stats: { tiles_requested: 0, tiles_from_cache: 0, tiles_rendered: 0 }};
            lines.forEach(function(line) {
                if (!line.match('^#') && !line.match('^$')) {
                    var kv = line.split('=');
                    map[kv[0]] = kv[1];
                }
            });
            maps[map.name] = map;
        }
    }
}

console.log('Maps:');
var name;
for (name in maps) {
    console.log(' ' + name + ' [' + maps[name].minz + '-' + maps[name].maxz + '] tiledir=' + maps[name].tiledir);
}

// =====================================================================

var sock = dgram.createSocket("udp4", function(buf, rinfo) {
    var msg = deserialize_tirex_msg(buf.toString('ascii', 0, rinfo.size));

    if (msg.id[0] !== 'n') {
        return;
    }

//    console.log("got msg:", msg);

    var conns = get_connections(msg.map, msg.z, msg.x, msg.y);

    if (conns !== undefined) {
        var imgfile = path.join(maps[msg.map].tiledir, xyz_to_filename(conns[0].x, conns[0].y, msg.z));
        fs.open(imgfile, 'r', null, function(err, fd) {
            while (conns.length > 0) {
                var conn = conns.shift();
                num_open_connections--;
//                console.log("connection=", msg.map, msg.z, conn.x, conn.y, imgfile);

                if (err) {
                    not_found(conn.res);
                } else {
                    stats.tiles_rendered++;
                    maps[msg.map].stats.tiles_rendered++;
                    send_image(conn.x, conn.y, msg.z, fd, conn.res);
                }
            }
        });
    }
});

//sock.bind(9090, '127.0.0.1');

var server = http.createServer(function(req, res) {
    console.log("req:", req.url);
    stats.http_requests++;

    var p = url.parse(req.url).pathname.split('/');

    if (p[0] !== '') { return not_found(res); }

    if (p[1] === 'maps') {
        res.writeHead(200, {'Content-Type': 'application/json;charset=utf-8'});
        var mapsout = {}, m;
        for (m in maps) {
            mapsout[m] = { minz: maps[m].minz, maxz: maps[m].maxz };
        }
        res.end(JSON.stringify(mapsout) + '\n');
        return;
    }

    if (p[1] === 'stats') {
        res.writeHead(200, {'Content-Type': 'application/json;charset=utf-8'});
        var m, out = {
            stats: stats,
            maps: {}
        };
        for (m in maps) {
            out.maps[m] = maps[m].stats;
        }
        res.write(JSON.stringify(out) + '\n');
        res.end();
        return;
    }

    if (p[1] !== 'tiles') { // must always start with "/tiles/"
        return not_found(res);
    }

    var map = p[2];
    if (maps[map] === undefined) {
        return not_found(res, 'Unknown map');
    }

    var z = parseInt(p[3]);
    if (z < maps[map].minz || z > maps[map].maxz) {
        return not_found(res, 'z out of range');
    }

    var x = parseInt(p[4]);
    var y = parseInt(path.basename(p[5], '.png'));

    var mx = x - x%8;
    var my = y - y%8;

    var limit = 1 << z;
    if (x < 0 || x >= limit || y < 0 || y >= limit) {
        return not_found(res);
    }

    stats.tiles_requested++;
    maps[map].stats.tiles_requested++;

    var imgfile = path.join(maps[map].tiledir, xyz_to_filename(x, y, z));

//    console.log(map, z, x, y, imgfile);

    fs.open(imgfile, 'r', null, function(err, fd) {
        if (err) {
            var s = serialize_tirex_msg({
                id:   'nodets-' + stats.tiles_requested,
                type: 'metatile_enqueue_request',
                prio: 8,
                map:  map,
                x:    mx,
                y:    my,
                z:    z
            });
//            console.log("send to tirex", s);
            var buf = new Buffer(s);

            sock.send(buf, 0, buf.length, config.master_udp_port, '127.0.0.1');

            store_connection(req, res, map, z, x, y);
            num_open_connections++;
        } else {
            stats.tiles_from_cache++;
            maps[map].stats.tiles_from_cache++;
            send_image(x, y, z, fd, res);
        }
    });

});

server.on('clientError', function(exception) {
    console.log("exception:", exception);
});

server.listen(config.tileserver_http_port);

