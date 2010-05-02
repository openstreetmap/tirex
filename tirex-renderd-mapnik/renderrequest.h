/*
 * Part of TIREX - a map tile rendering tool-chain for OpenStreetMap.
 * 
 * Originally written by Jochen Topf & Frederik Ramm; public domain.
 *
 * TIREX component: renderd (tile rendering daemon).
 */

/**
 * RenderRequest
 *
 * Class that encapsulates a render request. Any metatile information
 * must already have been resolved into plain coordinates.
 */

#ifndef renderrequest_included
#define renderrequest_included

class RenderRequest 
{
    public:
        unsigned int width;
        unsigned int height;
        double east;
        double west;
        double north;
        double south;
        unsigned int srs;
        unsigned int bbox_srs;
};

#endif
