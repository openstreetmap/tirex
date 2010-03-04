/*
 * Part of TIREX - a map tile rendering tool-chain for OpenStreetMap.
 * 
 * Originally written by Jochen Topf & Frederik Ramm; public domain.
 *
 * TIREX component: renderd (tile rendering daemon).
 */

/**
 * MapnikWrapper
 *
 * This class is responsible for preparing a render request and having it
 * executed by Mapnik. The result is then returned in the form of an image.
 */

#ifndef mapnikwrapper_included
#define mapnikwrapper_included

#include <mapnik/map.hpp>

#include "renderrequest.h"
#include "renderresponse.h"
#include "debuggable.h"

class MapnikWrapper : public Debuggable
{

public:

    MapnikWrapper(const std::string &mapfilename);
    ~MapnikWrapper();
    const RenderResponse *render(const RenderRequest *rr);

private:

    mapnik::Map mMap;

};
#endif
