#include "networkrequest.h"

NetworkRequest::NetworkRequest()
{
    mDefaultType.assign("metatile_render_request");
}

NetworkRequest::~NetworkRequest()
{
}

const std::string NetworkRequest::getType() const
{
    return getParam("type", mDefaultType);
}

