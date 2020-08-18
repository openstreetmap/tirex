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
#if MAPNIK_VERSION >= 300000
#define image_data_32 image_rgba8
#define image_32 image_rgba8
#include <mapnik/image.hpp>
#include <mapnik/image_view_any.hpp>
#else
#include <mapnik/graphics.hpp>
#endif

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
