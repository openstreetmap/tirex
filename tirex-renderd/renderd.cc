#include "renderd.h"

#include <iostream>
#include <syslog.h>

#include <boost/program_options.hpp>

#include <mapnik/datasource_cache.hpp>
#include <mapnik/font_engine_freetype.hpp>

#include "networklistener.h"

namespace po = boost::program_options;

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

bool RenderDaemon::loadMapnikWrappers(MetatileHandler *mth, const boost::filesystem::path &dir)
{
    // create mapnik instances
    if (!boost::filesystem::exists(dir)) return false;
    boost::filesystem::directory_iterator end_itr;
    bool rv = false;
    for (boost::filesystem::directory_iterator itr(dir); itr != end_itr; ++itr)
    {
        if (boost::filesystem::extension(*itr) == ".xml")
        {
            try
            {
                MapnikWrapper *w = new MapnikWrapper(itr->string());
                mth->addMapnikWrapper(boost::filesystem::basename(*itr), w);
                debug("added map %s", boost::filesystem::basename(*itr).c_str());
                rv = true;
            }
            catch (mapnik::config_error cfgerr)
            {
                warning("cannot add %s", boost::filesystem::basename(*itr).c_str());
                warning("%s", cfgerr.what());
            }
        }
    }
    return rv;
}

RenderDaemon::RenderDaemon(int argc, char **argv)
{
    // store for later use in setProgramName
    mArgc = argc;
    mArgv = argv;
    if (argc) mProgramName.assign(argv[0]);

    po::options_description desc("Allowed options");
    desc.add_options()
        ("help", 
            "produce help message")
        ("port", po::value<int>()->default_value(9320), 
            "UDP port to listen on")
        ("sockfd", po::value<int>()->default_value(-1), 
            "file descriptor of an already-opened UDP socket (supersedes --port)")
        ("parentfd", po::value<int>()->default_value(-1), 
            "file descriptor to send alive messages to")
        ("mapdir", po::value<std::string>()->default_value("/etc/mapnik-osm-data/"),
            "directory where to find Mapnik map files")
        ("plugindir", po::value<std::string>()->default_value("/usr/lib/mapnik/input"), 
            "directory where to find Mapnik datasource plugins")
        ("fontdir", po::value<std::string>()->default_value("/usr/lib/mapnik/fonts"),
            "directory to load fonts from")
        ("fontdir-recurse", po::value<bool>()->default_value(false), 
            "for recursing font directory")
        ("tiledir", po::value<std::string>()->default_value("/var/lib/tirex/tiles"), 
            "directory where to store meta tiles")
        ("syslog", po::value<std::string>()->default_value("daemon"), 
            "syslog facility for logging")
        ("debug", 
            "activate debug logging")
    ;

    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);    

    setStatus("initializing");

    if (vm.count("help")) 
    {
        std::cout << desc << std::endl;
        exit(1);
    }
    if (vm.count("debug")) 
    {
        Debuggable::msDebugLogging = true;
    }

    std::string strfac = vm["syslog"].as<std::string>();
    int fac = LOG_DAEMON;
    if (strfac == "local0") fac = LOG_LOCAL0;
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
    openlog("tirex-renderd", Debuggable::msDebugLogging ? LOG_PERROR|LOG_PID : LOG_PID, fac);

    mSocketFd = vm["sockfd"].as<int>();
    mParentFd = vm["parentfd"].as<int>();
    mPort = vm["port"].as<int>();

    mapnik::datasource_cache::instance()->register_datasources(vm["plugindir"].as<std::string>());
    loadFonts(vm["fontdir"].as<std::string>(), vm["fontdir-recurse"].as<bool>());

    // create handlers for requests
    MetatileHandler *mth = new MetatileHandler(vm["tiledir"].as<std::string>());
    if (!loadMapnikWrappers(mth, vm["mapdir"].as<std::string>()))
    {
        die("Cannot load any Mapnik styles (*.xml) from %s", vm["mapdir"].as<std::string>().c_str());
    }
    mHandlerMap[mth->getRequestType()] = mth;
    mth->addStatusReceiver(this);
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
    sprintf(*mArgv, "%s: %s", mProgramName.c_str(), status);
#endif
}

int main(int argc, char **argv)
{
    RenderDaemon mtd(argc, argv);
    mtd.run();
}

