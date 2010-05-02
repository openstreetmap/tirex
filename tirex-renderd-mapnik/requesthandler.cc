#include "requesthandler.h"

#include <vector>
#include <stdarg.h>

void RequestHandler::updateStatus(const char *fmt, ...) const
{
    char buffer[256];
    va_list args;
    va_start(args, fmt);
    vsnprintf(buffer, 255, fmt, args);
    buffer[255]=0;
    va_end(args);
// XXX this doesn't work for some reason
//    for (std::vector<StatusReceiver *>::const_iterator i = mStatusReceivers.begin(); i != mStatusReceivers.end(); i++) (*i)->setStatus(buffer);
}
