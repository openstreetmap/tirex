/*
 * Part of TIREX - a map tile rendering tool-chain for OpenStreetMap.
 * 
 * Originally written by Jochen Topf & Frederik Ramm; public domain.
 *
 * TIREX component: renderd (tile rendering daemon).
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

