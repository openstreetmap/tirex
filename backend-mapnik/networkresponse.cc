#include "networkresponse.h"

#include <sys/types.h>
#include <malloc.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

NetworkResponse::NetworkResponse(const NetworkRequest *request)
{
    std::string id = request->getParam("id", "");
    if (id.length()) setParam("id", id);
    std::string type = request->getType();
    setParam("type", type);
}

NetworkResponse::NetworkResponse()
{
}

NetworkResponse::~NetworkResponse()
{
}

const NetworkResponse *NetworkResponse::makeErrorResponse(const NetworkRequest *request, const char *fmt, ...)
{
    char buffer[0xffff];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buffer, sizeof(buffer), fmt, ap);
    va_end(ap);
    NetworkResponse *rv = request ? new NetworkResponse(request) : new NetworkResponse();
    rv->setParam("errmsg", buffer);
    rv->setParam("result", "error");
    return rv;
};

