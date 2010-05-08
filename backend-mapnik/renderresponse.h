/*
 * Tirex Tile Rendering System
 *
 * Mapnik rendering backend
 *
 * Originally written by Jochen Topf & Frederik Ramm.
 *
 */

/**
 * RenderResponse
 *
 * Class that encapsulates a render response - usually a plain image.
 */

#ifndef renderresponse_included
#define renderresponse_included

#include <mapnik/version.hpp>
#include <mapnik/graphics.hpp>

class RenderResponse
{
    public:
#if MAPNIK_VERSION >= 800
        mapnik::image_32 *image;
#else
        mapnik::Image32 *image;
#endif

    RenderResponse() { image = NULL; }
    ~RenderResponse() { if (image) delete image; }

};

#endif
