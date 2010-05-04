/*
 * Tirex Tile Rendering System
 *
 * Mapnik rendering backend
 *
 * Originally written by Jochen Topf & Frederik Ramm.
 *
 */

/**
 * StatusReceiver
 *
 * Superclass ("interface") for classes that receive status chnage
 * information.
 */

#ifndef statusreceiver_included
#define statusreceiver_included

class StatusReceiver
{
    public:

    virtual void setStatus(const char *status) = 0;
};

#endif

