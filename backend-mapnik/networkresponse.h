/*
 * Tirex Tile Rendering System
 *
 * Mapnik rendering backend
 *
 * Originally written by Jochen Topf & Frederik Ramm.
 *
 */

/**
 * NetworkResponse
 *
 * A response as written to the network interface.
 * 
 * @see NetworkMessage for details.
 */

#ifndef networkresponse_included
#define networkresponse_included

#include "networkmessage.h"
#include "networkrequest.h"

class NetworkResponse : public NetworkMessage
{

    private:

    public:
    static const NetworkResponse *makeErrorResponse(const NetworkRequest *request, const char *fmt, ...);
    NetworkResponse(const NetworkRequest *request);
    NetworkResponse();
    ~NetworkResponse();
};

#endif
