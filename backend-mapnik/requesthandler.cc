/*
 * Tirex Tile Rendering System
 *
 * Mapnik rendering backend
 *
 * Originally written by Jochen Topf & Frederik Ramm.
 *
 */

#include "requesthandler.h"

#include <vector>
#include <stdarg.h>

RequestHandler::RequestHandler()
{
    mpStatusReceiver = NULL;
}

void RequestHandler::updateStatus(const char *fmt, ...) const
{
    char buffer[256];
    va_list args;
    va_start(args, fmt);
    vsnprintf(buffer, 255, fmt, args);
    buffer[255]=0;
    va_end(args);
    if (mpStatusReceiver) mpStatusReceiver->setStatus(buffer);
}
