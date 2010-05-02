#include "mapnikwrapper.h"

#include <mapnik/map.hpp>
#include <mapnik/datasource_cache.hpp>
#include <mapnik/font_engine_freetype.hpp>
#include <mapnik/agg_renderer.hpp>
#include <mapnik/filter_factory.hpp>
#include <mapnik/color_factory.hpp>
#include <mapnik/image_util.hpp>
#include <mapnik/config_error.hpp>
#include <mapnik/load_map.hpp>

MapnikWrapper::MapnikWrapper(const std::string& mapfilename)
{
    load_map(mMap, mapfilename);
}

MapnikWrapper::~MapnikWrapper()
{
}

const RenderResponse *MapnikWrapper::render(const RenderRequest *rr)
{
    debug(">> MapnikWrapper::render");
    char init[255];

    // we hard-code the parameters for SRS 3857 since this is the only one used internally,
    // and not guaranteed to be available in user's /usr/share/proj/epsg file. Any other
    // projection will have been configured by the user, so if they configure a projection
    // not known on their system it is their fault.
    if (rr->srs == 3857)
    {
        strcpy(init, "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext  +no_defs");
    }
    else
    {
        sprintf(init, "+init=epsg:%d", rr->srs);
    }
    mMap.set_srs(init);

    double west = rr->west;
    double south = rr->south;
    double east = rr->east;
    double north = rr->north;

    if (rr->srs != rr->bbox_srs)
    {
        mapnik::projection p1(init);
        sprintf(init, "+init=epsg:%d", rr->bbox_srs);
        mapnik::projection p0(init);
        mapnik::proj_transform pt(p0, p1);
        double z = 0.0;
        pt.forward(west, south, z);
        z = 0.0;
        pt.forward(east, north, z);

        debug("rendering for %f,%f - %f,%f in SRS %d (projected from %f,%f - %f,%f in SRS %d) to %dx%dpx",
            west, south, east, north, rr->srs, rr->west, rr->south, rr->east, rr->north, rr->bbox_srs, rr->width, rr->height);
    }
    else
    {
        debug("rendering area %f,%f - %f,%f in SRS %d to %dx%d px",
            west, south, east, north, rr->srs, rr->width, rr->height);
    }

    mapnik::Envelope<double> bbox(west, south, east, north);
    mMap.resize(rr->width, rr->height);
    mMap.zoomToBox(bbox);
    mMap.set_buffer_size(128);

    debug("width: %d, height:%d", rr->width, rr->height);
    RenderResponse *resp = new RenderResponse();
    resp->image = new mapnik::Image32(rr->width, rr->height);
    mapnik::agg_renderer<mapnik::Image32> renderer(mMap, *(resp->image));
    try
    {
        renderer.apply();
    }
    catch (mapnik::datasource_exception dex)
    {
        delete resp;
        resp = NULL;
        error("Mapnik datasource exception: %s", dex.what());
    }
    catch (mapnik::config_error cer)
    {
        delete resp;
        resp = NULL;
        error("Mapnik config error: %s", cer.what());
    }
    debug("<< MapnikWrapper::render");

    return resp;
}

