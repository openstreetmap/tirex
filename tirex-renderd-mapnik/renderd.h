#ifndef renderd_included
#define renderd_included

#include "metatilehandler.h"
#include "requesthandler.h"
#include "mortal.h"
#include "debuggable.h"
#include "statusreceiver.h"
#include <boost/filesystem.hpp>
#include <string>
#include <map>

class RenderDaemon : public Mortal, public Debuggable, public StatusReceiver
{
    private:

    bool loadFonts(const boost::filesystem::path &dir, bool recurse);
    bool loadMapnikWrappers(MetatileHandler *mth, const boost::filesystem::path &dir);
    int mPort;
    int mSocketFd;
    int mParentFd;
    std::map<std::string, RequestHandler *> mHandlerMap;
    int mArgc;
    char **mArgv;
    std::string mProgramName;

    protected:

    void setStatus(const char *status);

    public:

    void run();
    RenderDaemon(int argc, char **argv);
    ~RenderDaemon();
};

#endif
