/*
 * Tirex Tile Rendering System
 *
 * Mapnik rendering backend
 *
 * Originally written by Jochen Topf & Frederik Ramm.
 *
 */

/**
 * MetatileHandler
 *
 * This class is responsible for analysing a "metatile" request received from
 * the network, calling the proper rendering functions to fulfil the request,
 * preparing the render result, and returning an answer to the client.
 */

#ifndef metatilehandler_included
#define metatilehandler_included

#include <string>
#include <mapnik/map.hpp>

#include "requesthandler.h"
#include "networkrequest.h"
#include "networkresponse.h"
#include "renderrequest.h"
#include "renderresponse.h"

#define MAXZOOM 25

struct entry {
    int offset;
    int size;
};

struct meta_layout {
    char magic[4];
    int count; // METATILE ^ 2
    int x, y, z; // lowest x,y of this metatile, plus z
    // entry index[]; // count entries
};

class MetatileHandler : public RequestHandler
{
    public:

    MetatileHandler(const std::string& tiledir, const std::map<std::string,std::string>& stylefiles, unsigned int tilesize, double scalefactor, int buffersize, unsigned int mtrowcol, const std::string & imagetype);
    ~MetatileHandler();
    const NetworkResponse *handleRequest(const NetworkRequest *request);
    void xyz_to_meta(char *path, size_t len, const char *tile_dir, int x, int y, int z) const;
    bool mkdirp(const char *tile_dir, int x, int y, int z) const;
    const std::string getRequestType() const { return "metatile_request"; }

    private:

    int64_t fourpow[MAXZOOM];
    int64_t twopow[MAXZOOM];
    const RenderResponse *render(const RenderRequest *rr);

    unsigned int mTileWidth;
    unsigned int mTileHeight;
    unsigned int mMetaTileRows;
    unsigned int mMetaTileColumns;
    std::string mImageType;
    int mBufferSize;
    double mScaleFactor;
    std::string mTileDir;
    mapnik::Map mMap;
    mapnik::Map *mPerZoomMap[MAXZOOM+1];
};

#endif

