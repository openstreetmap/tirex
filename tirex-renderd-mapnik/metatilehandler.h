/*
 * Part of TIREX - a map tile rendering tool-chain for OpenStreetMap.
 * 
 * Originally written by Jochen Topf & Frederik Ramm; public domain.
 *
 * TIREX component: renderd (tile rendering daemon).
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

#include "requesthandler.h"
#include "networkrequest.h"
#include "networkresponse.h"
#include "mapnikwrapper.h"

#define MAXZOOM 25

struct entry {
    int offset;
    int size;
};

struct meta_layout {
    char magic[4];
    int count; // METATILE ^ 2
    int x, y, z; // lowest x,y of this metatile, plus z
    struct entry index[]; // count entries
};

class MetatileHandler : public RequestHandler
{
    public:

    MetatileHandler(const std::string& tiledir);
    ~MetatileHandler();
    const std::string getRequestType() const { return std::string("metatile_render_request"); }
    const NetworkResponse *handleRequest(const NetworkRequest *request) const;
    void xyz_to_meta(char *path, size_t len, const char *tile_dir, const char *map, int x, int y, int z) const;
    bool mkdirp(const char *tile_dir, const char *map, int x, int y, int z) const;
    void addMapnikWrapper(const std::string& map, MapnikWrapper *w) { mMapnikWrappers[map] = w; }

    private:

    long long fourpow[MAXZOOM];
    long long twopow[MAXZOOM];

    unsigned int mTileWidth;
    unsigned int mTileHeight;
    unsigned int mMetaTileRows;
    unsigned int mMetaTileColumns;
    std::string mTileDir;

    std::map<std::string, MapnikWrapper *> mMapnikWrappers;
};

#endif

