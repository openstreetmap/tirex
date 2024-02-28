/*
 * Tirex Tile Rendering System
 *
 * Mapnik rendering backend
 *
 * Originally written by Jochen Topf & Frederik Ramm.
 *
 */

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <stdio.h>
#include <errno.h>
#include <iostream>
#include <signal.h>
#include <strings.h>
#include <unistd.h>

#include "networklistener.h"
#include "networkrequest.h"
#include "networkresponse.h"

// stuff for handling the hangup signal properly
extern "C"
{
    static volatile sig_atomic_t gHangupOccurred;
    static void hangup_signal_handler(int /*param*/) { gHangupOccurred = 1; }
    static void install_sighup_handler(bool with_restart)
    {
        struct sigaction action;
        sigemptyset(&action.sa_mask);
        action.sa_handler = hangup_signal_handler;
        action.sa_flags = with_restart ? SA_RESTART : 0;
        sigaction(SIGHUP, &action, NULL);
    }
    static void ignore_sigpipe()
    {
        struct sigaction action;
        sigemptyset(&action.sa_mask);
        action.sa_handler = SIG_IGN;
        action.sa_flags = 0;
        sigaction(SIGPIPE, &action, NULL);
    }
}

NetworkListener::NetworkListener(int port, int sockfd, int parentfd, std::map<std::string, RequestHandler *> *handlers, int maxreq) :
    mpRequestHandlers(handlers),
    mSocket(-1),
    mParent(parentfd),
    mMaxRequests(maxreq)
{
    mRequestCount = 0;
    socklen_t length;
    sockaddr_in server;

    if (sockfd >= 0)
    {
        mSocket = sockfd;
        debug("using existing socket %d", sockfd);
    }
    else
    {
        mSocket = socket(AF_INET, SOCK_DGRAM, 0);
        if (mSocket < 0) die ("cannot open socket: %s", strerror(errno));
        int one = 1;
        setsockopt(mSocket, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(int));
        length = sizeof(server);
        bzero(&server, length);
        server.sin_family = AF_INET;
        server.sin_addr.s_addr = inet_addr("127.0.0.1");
        server.sin_port = htons(port);
        if (bind(mSocket, reinterpret_cast<sockaddr *>(&server), length) < 0) die("cannot bind to port %d: %s", port, strerror(errno));
        debug("bound to port %d", port);
    }
}

NetworkListener::~NetworkListener()
{
}

void NetworkListener::run()
{
    sockaddr_in client;
    socklen_t fromlen = sizeof(sockaddr_in);
    char buf[MAX_DGRAM];

    // install SIGHUP signal handler. use sigaction to avoid restarting after signal.
    gHangupOccurred = 0;
    int errcnt = 0;
    fd_set rfds;
    FD_ZERO(&rfds);
    time_t last_alive_sent = 0;
    install_sighup_handler(false);
    ignore_sigpipe();
    while (!gHangupOccurred)
    {
        timeval to = { 5, 0 };
        FD_SET(mSocket, &rfds);
        // do not select for writability of mParent, since it is
        // always writable.
        int n = select(mSocket + 1, &rfds, NULL, NULL, &to);

        // send alive message to parent.
        if (mParent > -1)
        {
            time_t now = time(NULL);
            if (now >= last_alive_sent + 5)
            {
                // we really are not interested in the write() result since
                // the parent is going to kill us anyway if it does not recieve
                // an alive message. The following construction gets rid of
                // the compiler warning about not using the return value.
                if (write(mParent, static_cast<const void *>("alive"), 5)) {};
                last_alive_sent = now;
            }
        }

        if (n <= 0)
        {
            if (n < 0 && errno != EINTR)
            {
                error("error while reading data: %s", strerror(errno));
                if (errcnt++ > 10)
                {
                    error("too many errors - exiting");
                    break;
                }
            }
            continue;
        }

        n = recvfrom(mSocket, buf, MAX_DGRAM, MSG_DONTWAIT, reinterpret_cast<sockaddr *>(&client), &fromlen);
        if (n < 0)
        {
            if (errno != EWOULDBLOCK && errno != EAGAIN && errno != EINTR)
            {
                error("error while reading data: %s", strerror(errno));
                if (errcnt++ > 10)
                {
                    error("too many errors - exiting");
                    break;
                }
            }
        }
        else
        {
            errcnt = 0;
            NetworkRequest *req = new NetworkRequest();
            std::string strbuf(buf, n);
            debug("read: %s", strbuf.c_str());
            const NetworkResponse *resp;
            if (!req->parse(strbuf))
            {
                error("error parsing request");
                resp = NetworkResponse::makeErrorResponse(NULL, "cannot parse request");
            }
            else
            {
                std::map<std::string, RequestHandler *>::const_iterator h = mpRequestHandlers->find(req->getParam("map", ""));
                install_sighup_handler(true);

                if (h != mpRequestHandlers->end())
                {
                    if (!(resp = h->second->handleRequest(req)))
                    {
                        error("handler returned null");
                        resp = NetworkResponse::makeErrorResponse(req,
                            "Handler for map '%s' encountered an error", req->getParam("map", "").c_str());
                    }
                }
                else
                {
                    error("no handler found for map style '%s'", req->getParam("map", "").c_str());
                    resp = NetworkResponse::makeErrorResponse(req,
                        "map style '%s' is not known", req->getParam("map", "").c_str());
                }
                install_sighup_handler(false);
            }

            std::string responseString;
            resp->build(responseString);
            debug("sending: %s", responseString.c_str());
            n = sendto(mSocket, responseString.data(), responseString.length(), 0, reinterpret_cast<sockaddr *>(&client), fromlen);
            if (n < 0)
            {
                error("error in sendto");
            }
            delete resp;
            delete req;
            if (mMaxRequests > -1 && ++mRequestCount > mMaxRequests) 
            {
                error("maxrequests reached, terminating");
                break;
            }
        }
    }
}


