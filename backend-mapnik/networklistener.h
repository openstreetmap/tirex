/*
 * Tirex Tile Rendering System
 *
 * Mapnik rendering backend
 *
 * Originally written by Jochen Topf & Frederik Ramm.
 *
 */

/**
 * NetworkListener
 *
 * Class that handles the main network loop, waiting for input on the
 * specified UDP socket, then calling the appropriate request handler
 * for the type of request received.
 */

#ifndef networklistener_included
#define networklistener_included

#include <map>
#include <string>

#include "requesthandler.h"
#include "mortal.h"
#include "debuggable.h"

#define MAX_DGRAM 0xffff

class NetworkListener : public Mortal, public Debuggable
{

    public:

    NetworkListener(int port, int sockfd, int parentfd, std::map<std::string, RequestHandler *> *handlers);
    ~NetworkListener();

    void run();

    private:

    std::map<std::string, RequestHandler *> *mpRequestHandlers;
    int mSocket;
    int mParent;

};
#endif
