#include "metatilehandler.h"
#include "renderrequest.h"
#include "renderresponse.h"

#include "sys/time.h"
#include <boost/filesystem.hpp>
#include <mapnik/image_util.hpp>
#include <limits.h>
#include <iostream>
#include <fstream>

#define MERCATOR_WIDTH 40075016.685578488
#define MERCATOR_OFFSET 20037508.342789244

MetatileHandler::MetatileHandler(const std::string& tiledir)
{
    mTileDir = tiledir;
    mTileWidth = 256;
    mTileHeight = 256;
    mMetaTileRows = 8;
    mMetaTileColumns = 8;

    fourpow[0] = 1;
    twopow[0] = 1;
    for (unsigned int i = 1; i < MAXZOOM; i++)
    {
        fourpow[i] = 4 * fourpow[i-1];
        twopow[i] = 2 * twopow[i-1];
    }
}

MetatileHandler::~MetatileHandler()
{
}

const NetworkResponse *MetatileHandler::handleRequest(const NetworkRequest *request) const
{
    debug(">> MetatileHandler::handleRequest");
    struct timeval start, end;
    gettimeofday(&start, NULL);

    int x = request->getParam("x", -1);
    int y = request->getParam("y", -1);
    int z = request->getParam("z", -1);

    if (x % mMetaTileColumns)
    {
        error("given value for 'x' (%d) is not divisible by %d", x, mMetaTileColumns);
        return NetworkResponse::makeErrorResponse(request, "invalid value for x");
    }

    if (y % mMetaTileRows)
    {
        error("given value for 'y' (%d) is not divisible by %d", y, mMetaTileRows);
        return NetworkResponse::makeErrorResponse(request, "invalid value for y");
    }

    unsigned int mtc = mMetaTileColumns;
    if (mtc > fourpow[z]) mtc = fourpow[z];
    unsigned int mtr = mMetaTileRows;
    if (mtr > fourpow[z]) mtr = fourpow[z];

    RenderRequest rr;

    // compute render extent in epsg:3857 which the database is likely to use.
    // note that if the database should use something different, this will be
    // taken care of later.

    rr.west = x * MERCATOR_WIDTH / twopow[z] - MERCATOR_OFFSET;
    rr.east = (x + mtc) * MERCATOR_WIDTH / twopow[z] - MERCATOR_OFFSET;
    rr.north = (twopow[z] - y) * MERCATOR_WIDTH / twopow[z] - MERCATOR_OFFSET;
    rr.south = (twopow[z] - y - mtr) * MERCATOR_WIDTH / twopow[z] - MERCATOR_OFFSET;

    // we specify the bbox in epsg:3857, and we also want our image returned
    // in this projection. 
    rr.bbox_srs = 3857;
    rr.srs = 3857;

    rr.width = mTileWidth * mtc;
    rr.height = mTileHeight * mtr;

    std::string map = request->getParam("map", "default");
    std::map<std::string, MapnikWrapper *>::const_iterator mw = 
        mMapnikWrappers.find(map);
    if (mw == mMapnikWrappers.end()) 
    {
        debug("no mapnik map by the name of %s", map.c_str());
        return NULL;
    }

    updateStatus("rendering z=%d x=%d y=%d map=%s", z, x, y, map.c_str());
    const RenderResponse *rrs = mw->second->render(&rr);
    updateStatus("idle");

    NetworkResponse *resp;

    if (!rrs)
    {
        return NetworkResponse::makeErrorResponse(request, "renderer internal error");
    }
    else
    {
        struct meta_layout m;
        struct entry offsets[mMetaTileRows * mMetaTileColumns];
        std::string rawpng[mMetaTileRows * mMetaTileColumns];
        memset(&m, 0, sizeof(m));
        memset(&offsets, 0, sizeof(offsets));

        // it seems that mod_tile expects us to always put the theoretical
        // number of tiles in this meta tile, not the real number (in standard
        // setup, only zoom levels 3+ will have 64 tiles, 0-2 have less)
        // m.count = mtr * mtc;
        m.count = mMetaTileRows * mMetaTileColumns;
        memcpy(m.magic, "META", 4);
        m.x = x;
        m.y = y;
        m.z = z;
        size_t offset = sizeof(m) + sizeof(offsets);
        int index = 0;

        char metafilename[PATH_MAX];
        xyz_to_meta(metafilename, PATH_MAX, mTileDir.c_str(), map.c_str(), x, y, z);
        if (!mkdirp(mTileDir.c_str(), map.c_str(), x, y, z))
        {
            return NetworkResponse::makeErrorResponse(request, "renderer internal error");
        }

        char tmpfilename[PATH_MAX];
        snprintf(tmpfilename, PATH_MAX, "%s.%d.tmp", metafilename, getpid());
        std::ofstream outfile(tmpfilename, std::ios::out | std::ios::binary | std::ios::trunc);
        outfile.write((const char*) &m, sizeof(m));

        for (unsigned int col = 0; col < mtc; col++)
        {
            for (unsigned int row = 0; row < mtr; row++)
            {
                mapnik::image_view<mapnik::ImageData32> view(col * mTileWidth, 
                    row * mTileHeight, mTileWidth, mTileHeight, rrs->image->data());
                rawpng[index] = mapnik::save_to_string(view, "png256");
                offsets[index].offset = offset;
                offset += offsets[index].size = rawpng[index].length();
                index++;
            }
        }

        outfile.write((const char*) &offsets, sizeof(offsets));

        for (int i=0; i < index; i++)
        {
            outfile.write(rawpng[i].data(), rawpng[i].size());
        }

        outfile.close();
        delete rrs;
        rename(tmpfilename, metafilename);
        debug("created %s", metafilename);

        resp = new NetworkResponse(request);
        resp->setParam("map", map);
        resp->setParam("result", "ok");
        resp->setParam("x", x);
        resp->setParam("y", y);
        resp->setParam("z", z);
        resp->setParam("metatile", metafilename);
        gettimeofday(&end, NULL);
        char buffer[20];
        snprintf(buffer, 20, "%ld", (end.tv_sec-start.tv_sec) * 1000 + (end.tv_usec - start.tv_usec) / 1000);
        resp->setParam("render_time", buffer);
    }
    debug("<< MetatileHandler::handleRequest");
    return resp;
}

void MetatileHandler::xyz_to_meta(char *path, size_t len, const char *tile_dir, const char *map, int x, int y, int z) const
{
    unsigned char i, hash[5];

    for (i=0; i<5; i++) {
        hash[i] = ((x & 0x0f) << 4) | (y & 0x0f);
        x >>= 4;
        y >>= 4;
    }
    snprintf(path, len, "%s/%s/%d/%u/%u/%u/%u/%u.meta", tile_dir, map, z, hash[4], hash[3], hash[2], hash[1], hash[0]);
    return;
}

bool MetatileHandler::mkdirp(const char *tile_dir, const char *map, int x, int y, int z) const
{
    unsigned char i, hash[5];
    char path[PATH_MAX];

    for (i=0; i<5; i++) {
        hash[i] = ((x & 0x0f) << 4) | (y & 0x0f);
        x >>= 4;
        y >>= 4;
    }
    snprintf(path, PATH_MAX, "%s/%s/%d/%u/%u/%u/%u", tile_dir, map, z, hash[4], hash[3], hash[2], hash[1]);
    try
    {
        boost::filesystem::create_directories(path);
    }
    catch(boost::filesystem::basic_filesystem_error<boost::filesystem::path> bfe)
    {
        error("cannot create directory %s: %s", path, bfe.what());
        return false;
    }
    return true;
}
