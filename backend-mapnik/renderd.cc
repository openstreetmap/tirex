/*
 * Tirex Tile Rendering System
 *
 * Mapnik rendering backend
 *
 * Originally written by Jochen Topf & Frederik Ramm.
 *
 */

#include "renderd.h"

#include <iostream>
#include <syslog.h>

#include <mapnik/version.hpp>
#include <mapnik/datasource_cache.hpp>
#include <mapnik/font_engine_freetype.hpp>
#include <exception>

#include "networklistener.h"

bool RenderDaemon::loadFonts(const boost::filesystem::path &dir, bool recurse)
{
    if (!boost::filesystem::exists(dir)) return false;
    boost::filesystem::directory_iterator end_itr;
    for (boost::filesystem::directory_iterator itr(dir); itr != end_itr; ++itr)
    {
        if (boost::filesystem::is_directory(*itr) && recurse)
        {
            if (!loadFonts(*itr, true)) return false;
        }
        else
        {
#if (BOOST_FILESYSTEM_VERSION == 3)
            mapnik::freetype_engine::register_font(itr->path().string());
#else // v2
            mapnik::freetype_engine::register_font(itr->string());
#endif
        }
    }
    return true;
}

bool RenderDaemon::loadMapnikWrapper(const char *configfile)
{
    // create mapnik instances
    bool rv = false;
    FILE *f = fopen(configfile, "r");
    if (!f)
    {
        warning("cannot open '%s'", configfile);
        return rv;
    }

    char linebuf[255];
    std::string tiledir;
    std::map<std::string, std::string> mapfiles;
    std::string stylename;
    unsigned int tilesize = 256;
    unsigned int mtrowcol = 8;
    double scalefactor = 1.0;
    int buffersize = -1;
    std::string imagetype = "png256";
    int lineno = 0;

    while (char *line = fgets(linebuf, sizeof(linebuf), f))
    {
        lineno++;
        while (isspace(*line)) line++;
        if (*line == '#') continue;
        if (!*line) continue;
        char *eq = strchr(line, '=');
        if (eq)
        {
            char *last = eq-1;
            // trim space before equal sign
            while (last > line && isspace(*last)) *last-- = 0;
            *eq++ = 0;
            // trim space after equal sign
            while (isspace(*eq)) eq++;
            // trim space at end of line
            last = eq + strlen(eq) - 1;
            while (last > eq && isspace(*last)) *last-- = 0;
            if (!strcmp(line, "tiledir"))
            {
                tiledir.assign(eq);
            }
            else if (!strncmp(line, "mapfile", 7))
            {
                mapfiles.insert(std::pair<std::string, std::string>(line+7, eq));
            }
            else if (!strcmp(line, "scalefactor"))
            {
                scalefactor = atof(eq);
            }
            else if (!strcmp(line, "buffersize"))
            {
                buffersize = atoi(eq);
            }
            else if (!strcmp(line, "tilesize"))
            {
                tilesize = atoi(eq);
            }
            else if (!strcmp(line, "metarowscols"))
            {
                mtrowcol = atoi(eq);
            }
            else if (!strcmp(line, "maxrequests"))
            {
                mMaxRequests  = atoi(eq);
            }
            else if (!strcmp(line, "name"))
            {
                stylename.assign(eq);
            }
            else if (!strcmp(line, "imagetype"))
            {
                imagetype.assign(eq);
            }
            else if (!strcmp(line, "minz"))
            {
                // no error
            }
            else if (!strcmp(line, "maxz"))
            {
                // no error
            }
            else
            {
                warning("parse error on line %d of config file %s", lineno, configfile);
            }
        }
        else
        {
            warning("parse error on line %d of config file %s", lineno, configfile);
        }
    }
    fclose(f);

    if (mapfiles.empty())
    {
        warning("cannot add %s: missing mapfile option", configfile);
        return rv;
    }

    if (tiledir.empty())
    {
        warning("cannot add %s: missing tiledir option", configfile);
        return rv;
    }

    if (access(tiledir.c_str(), W_OK) == -1)
    {
        warning("cannot add %s: tile directory '%s' not accessible", configfile, tiledir.c_str());
        return rv;
    }

    if (stylename.empty())
    {
        warning("cannot add %s: missing name option", configfile);
        return rv;
    }

    try
    {
        mHandlerMap[stylename] = new MetatileHandler(tiledir, mapfiles, tilesize, 
            scalefactor, buffersize, mtrowcol, imagetype);
        mHandlerMap[stylename]->setStatusReceiver(this);
        debug("added style '%s' from map %s", stylename.c_str(), configfile);
        rv = true;
    }
    catch (std::exception const& ex)
    {
        warning("cannot add %s", configfile);
        warning("%s", ex.what());
    }
    return rv;
}

RenderDaemon::RenderDaemon(int argc, char **argv) :
    mArgc(argc),
    mArgv(argv),
    mProgramName(argc ? argv[0] : "")
{
    setStatus("initializing");

    mMaxRequests = -1;

    char *tmp = getenv("TIREX_BACKEND_DEBUG");
    Debuggable::msDebugLogging = tmp ? true : false;

    std::string strfac;
    tmp = getenv("TIREX_BACKEND_SYSLOG_FACILITY");
    if (tmp) strfac = tmp;
    int fac = LOG_DAEMON;
    if (strfac.empty()) fac = LOG_DAEMON;
    else if (strfac == "local0") fac = LOG_LOCAL0;
    else if (strfac == "local1") fac = LOG_LOCAL1;
    else if (strfac == "local2") fac = LOG_LOCAL2;
    else if (strfac == "local3") fac = LOG_LOCAL3;
    else if (strfac == "local4") fac = LOG_LOCAL4;
    else if (strfac == "local5") fac = LOG_LOCAL4;
    else if (strfac == "local6") fac = LOG_LOCAL6;
    else if (strfac == "user") fac = LOG_USER;
    else if (strfac == "daemon") fac = LOG_DAEMON;
    else
    {
        die(2, "Cannot use log facility '%s' - only local0-local7, user, daemon are allowed.", strfac.c_str());
    }
    openlog("tirex-backend-mapnik", Debuggable::msDebugLogging ? LOG_PERROR|LOG_PID : LOG_PID, fac);
    info("Renderer started (name=%s)", getenv("TIREX_BACKEND_NAME"));

    tmp = getenv("TIREX_BACKEND_SOCKET_FILENO");
    mSocketFd = tmp ? atoi(tmp) : -1;

    tmp = getenv("TIREX_BACKEND_PIPE_FILENO");
    mParentFd = tmp ? atoi(tmp) : -1;

    tmp = getenv("TIREX_BACKEND_PORT");
    mPort = tmp ? atoi(tmp) : 9320;

    tmp = getenv("TIREX_BACKEND_CFG_plugindir");
#if MAPNIK_VERSION >= 200200
    if (tmp) mapnik::datasource_cache::instance().register_datasources(tmp);
#else
    if (tmp) mapnik::datasource_cache::instance()->register_datasources(tmp);
#endif

    tmp = getenv("TIREX_BACKEND_CFG_fontdir_recurse");
    bool fr = tmp ? atoi(tmp) : true;
    tmp = getenv("TIREX_BACKEND_CFG_fontdir");
    if (tmp) loadFonts(tmp, fr);

    tmp = getenv("TIREX_BACKEND_MAP_CONFIGS");
    if (tmp)
    {
        char *dup = strdup(tmp);
        char *tkn = strtok(dup, " ");
        while (tkn)
        {
            if (!loadMapnikWrapper(tkn)) {
                die(2, "Unable to load map");
            }
            tkn = strtok(NULL, " ");
        }
    }

    if (mHandlerMap.empty())
        die(2, "Cannot load any Mapnik styles");

}

RenderDaemon::~RenderDaemon()
{
}

void RenderDaemon::run()
{
    NetworkListener listener(mPort, mSocketFd, mParentFd, &mHandlerMap, mMaxRequests);
    setStatus("idle");
    listener.run();
}

void RenderDaemon::setStatus(const char *status)
{
#ifdef __linux__
    char **p = mArgv;
    for (int i=1;i<mArgc;i++) { for (char *c = *(++p); *c != 0; c++) *c=0; }
//    sprintf(*mArgv, "%s: %s", mProgramName.c_str(), status);
    sprintf(*mArgv, "mapnik: %s                                ", status);
#endif
}

int main(int argc, char **argv)
{
    RenderDaemon mtd(argc, argv);
    mtd.run();
    exit(9); // return with EXIT_CODE_RESTART==9 which means everything is ok, the backend can be restarted if the backend-manager wants to
}

