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

#include <mapnik/datasource_cache.hpp>
#include <mapnik/font_engine_freetype.hpp>

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
            mapnik::freetype_engine::register_font(itr->string());
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
    std::string mapfile;
    std::string stylename;
    
    while (char *line = fgets(linebuf, sizeof(linebuf), f))
    {
        while (isspace(*line)) line++;
        if (*line == '#') continue;
        char *eq = strchr(line, '=');
        if (eq)
        {
            *eq++ = 0;
            char *last = eq + strlen(eq) - 1;
            while (last > eq && isspace(*last)) *last-- = 0;
            printf("_%s_%s_\n", line, eq);
            if (!strcmp(line, "tiledir"))
            {
                tiledir.assign(eq);
            }
            else if (!strcmp(line, "mapfile"))
            {
                mapfile.assign(eq);
            }
            else if (!strcmp(line, "name"))
            {
                stylename.assign(eq);
            }
        }
    }
    fclose(f);

    if (mapfile.empty())
    {
        warning("cannot add %s: missing mapfile option", configfile);
        return rv;
    }

    if (tiledir.empty())
    {
        warning("cannot add %s: missing tiledir option", configfile);
        return rv;
    }

    if (stylename.empty())
    {
        warning("cannot add %s: missing name option", configfile);
        return rv;
    }

    try
    {
        mHandlerMap[stylename] = new MetatileHandler(tiledir, mapfile);
        mHandlerMap[stylename]->setStatusReceiver(this);
        debug("added style '%s' from map %s", stylename.c_str(), configfile);
        rv = true;
    }
    catch (mapnik::config_error cfgerr)
    {
        warning("cannot add %s", configfile);
        warning("%s", cfgerr.what());
    }
    return rv;
}

RenderDaemon::RenderDaemon(int argc, char **argv)
{
    // store for later use in setProgramName
    mArgc = argc;
    mArgv = argv;
    if (argc) mProgramName.assign(argv[0]);

    setStatus("initializing");

    char *tmp = getenv("TIREX_BACKEND_DEBUG");
    Debuggable::msDebugLogging = tmp ? true : false;

    std::string strfac;
    tmp = getenv("TIREX_BACKEND_SYSLOG");
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
        die("Cannot use log facility '%s' - only local0-local7, user, daemon are allowed.", strfac.c_str());
    }
    openlog("tirex-renderer-mapnik", Debuggable::msDebugLogging ? LOG_PERROR|LOG_PID : LOG_PID, fac);

    tmp = getenv("TIREX_BACKEND_SOCKET_FILENO");
    mSocketFd = tmp ? atoi(tmp) : -1;

    tmp = getenv("TIREX_BACKEND_PIPE_FILENO");
    mParentFd = tmp ? atoi(tmp) : -1;

    tmp = getenv("TIREX_BACKEND_PORT");
    mPort = tmp ? atoi(tmp) : 9320;

    tmp = getenv("TIREX_BACKEND_CFG_plugindir");
    if (tmp) mapnik::datasource_cache::instance()->register_datasources(tmp);

    tmp = getenv("TIREX_BACKEND_CFG_fontdir_recurse");
    bool fr = tmp ? atoi(tmp) : false;
    tmp = getenv("TIREX_BACKEND_CFG_fontdir");
    if (tmp) loadFonts(tmp, fr);

    tmp = getenv("TIREX_BACKEND_MAPFILES");
    if (tmp)
    {
        char *dup = strdup(tmp);
        char *tkn = strtok(dup, " ");
        while (tkn)
        {
            loadMapnikWrapper(tkn);
            tkn = strtok(NULL, " ");
        }
    }

    if (mHandlerMap.empty())
        die("Cannot load any Mapnik styles");

}

RenderDaemon::~RenderDaemon() 
{
};

void RenderDaemon::run()
{
    NetworkListener listener(mPort, mSocketFd, mParentFd, &mHandlerMap);
    setStatus("idle");
    listener.run();
}

void RenderDaemon::setStatus(const char *status)
{
#ifdef linux
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
    exit(9); // return with EXIT_CODE_RESTART==9 which means everything is ok, the backend can be restartet if the backend-manager wants to
}

