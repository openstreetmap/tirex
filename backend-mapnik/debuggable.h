/*
 * Tirex Tile Rendering System
 *
 * Mapnik rendering backend
 *
 * Originally written by Jochen Topf & Frederik Ramm.
 *
 */

/**
 * Debuggable
 *
 * Superclass for classes that may log debug info
 */

#ifndef debuggable_included
#define debuggable_included

#include <sys/types.h>
#include <malloc.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <syslog.h>

class Debuggable
{
    protected:

    void debug(const char *fmt, ...) const
    {
        if (!msDebugLogging) return;
        va_list ap;
        va_start(ap, fmt);
        vsyslog(LOG_DEBUG, fmt, ap);
        va_end(ap);
    }
    void info(const char *fmt, ...) const
    {
        va_list ap;
        va_start(ap, fmt);
        vsyslog(LOG_INFO, fmt, ap);
        va_end(ap);
    }
    void notice(const char *fmt, ...) const
    {
        va_list ap;
        va_start(ap, fmt);
        vsyslog(LOG_NOTICE, fmt, ap);
        va_end(ap);
    }
    void warning(const char *fmt, ...) const
    {
        va_list ap;
        va_start(ap, fmt);
        vsyslog(LOG_WARNING, fmt, ap);
        va_end(ap);
    }
    void error(const char *fmt, ...) const
    {
        va_list ap;
        va_start(ap, fmt);
        vsyslog(LOG_ERR, fmt, ap);
        va_end(ap);
    }

    public:

    static bool msDebugLogging;
};

#endif

