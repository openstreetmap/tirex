/*
 * Tirex Tile Rendering System
 *
 * Mapnik rendering backend
 *
 * Originally written by Jochen Topf & Frederik Ramm.
 *
 */

/**
 * NetworkRequest
 *
 * A request as read from the network interface.
 * 
 * @see NetworkMessage for details.
 */

#ifndef networkrequest_included
#define networkrequest_included

#include "networkmessage.h"

class NetworkRequest : public NetworkMessage
{
    private:
        std::string mDefaultType;

    public:
        const std::string getType() const;
        NetworkRequest();
        ~NetworkRequest();
};

#endif
