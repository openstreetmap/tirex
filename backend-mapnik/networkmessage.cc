#include <string.h>
#include <malloc.h>
#include <stdlib.h>

#include "networkmessage.h"

NetworkMessage::NetworkMessage()
{
}

NetworkMessage::~NetworkMessage()
{
}

const std::string NetworkMessage::getParam(const std::string &key, const std::string &def) const
{
    std::map<std::string, std::string>::const_iterator i = mParams.find(key);
    return (i == mParams.end() ? def : i->second);
}

int NetworkMessage::getParam(const std::string &key, int def) const
{
    std::map<std::string, std::string>::const_iterator i = mParams.find(key);
    return (i == mParams.end() ? def : atoi(i->second.c_str()));
}

void NetworkMessage::setParam(const std::string &key, const std::string &value) 
{
    mParams[key] = value;
}
void NetworkMessage::setParam(const std::string &key, int value)
{
    char buffer[32];
    snprintf(buffer, 31, "%d", value);
    buffer[31]=0;
    mParams[key] = buffer;
}

bool NetworkMessage::parse(const std::string &buffer)
{
    debug(">> NetworkMessage::parse");
    char *dup = strdup(buffer.c_str());
    char *token;
    token = strtok(dup, "\r\n");
    while (token)
    {
        char *eq = strchr(token, '=');
        if (eq)
        {
            *eq++ = 0;
            mParams[token] = eq;
        }
        else
        {
            // invalid line
        }
        token = strtok(NULL, "\r\n");
    }
    free(dup);
    debug("<< NetworkMessage::parse");
    return true;
}

bool NetworkMessage::build(std::string &buffer) const
{
    debug(">> NetworkMessage::build");
    buffer.clear();
    for (std::map<std::string, std::string>::const_iterator i = 
        mParams.begin(); i != mParams.end(); i++)
    {
        buffer.append(i->first);
        buffer.append("=");
        buffer.append(i->second);
        buffer.append("\n");
    }
    debug("<< NetworkMessage::build");
    return true;
}
