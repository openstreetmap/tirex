/*
 * Part of TIREX - a map tile rendering tool-chain for OpenStreetMap.
 * 
 * Originally written by Jochen Topf & Frederik Ramm; public domain.
 *
 * TIREX component: renderd (tile rendering daemon).
 */

/**
 * RenderResponse
 *
 * Class that encapsulates a render response - usually a plain image.
 */

#ifndef renderresponse_included
#define renderresponse_included

#include <mapnik/graphics.hpp>

class RenderResponse
{
    public:
        mapnik::Image32 *image;
   
    RenderResponse() { image = NULL; }
    ~RenderResponse() { if (image) delete image; }

};

#endif
