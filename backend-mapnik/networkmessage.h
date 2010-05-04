/*
 * Tirex Tile Rendering System
 *
 * Mapnik rendering backend
 *
 * Originally written by Jochen Topf & Frederik Ramm.
 *
 */

/**
 * NetworkMessage
 *
 * Superclass for messages forming renderd's network protocol. Protocol
 * messages consist of a series of lines, ending with LF or CRLF, and
 * each line contains a plain-text key, followed by an equal sign, and
 * a plain-text value. Keys must not contain equal signs; lines without
 * equal signs are ignored; the order does not matter; and neither keys
 * nor values may contain CR or LF.
 * 
 * Example message:
 *
 * request=render
 * type=metatile
 * map=default
 * x=16
 * y=24
 * z=5
 */

#ifndef networkmessage_included
#define networkmessage_included

#include "debuggable.h"

#include <string>
#include <map>

class NetworkMessage : public Debuggable
{
    private:
        std::map<std::string, std::string> mParams;

    public:
        NetworkMessage();
        ~NetworkMessage();
        bool parse(const std::string &buffer);
        bool build(std::string &buffer) const;
        const std::string getParam(const std::string &key, const std::string &def) const;
        int getParam(const std::string &key, int def) const;
        void setParam(const std::string &key, const std::string &value);
        void setParam(const std::string &key, int value);
};

#endif
