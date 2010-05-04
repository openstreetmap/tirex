/*
 * Tirex Tile Rendering System
 *
 * Mapnik rendering backend
 *
 * Originally written by Jochen Topf & Frederik Ramm.
 *
 */

/**
 * Mortal
 *
 * Superclass for classes that may terminate the program.
 */

#ifndef mortal_included
#define mortal_included

#include <sys/types.h>
#include <malloc.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

class Mortal
{
    protected:

    void die(const char *fmt, ...)
    {
        char *cpy;
        cpy = (char *) malloc(strlen(fmt) + 256);
        sprintf(cpy, "%s\n", fmt);
        va_list ap;
        va_start(ap, fmt);
        vfprintf(stderr, cpy, ap);
        va_end(ap);
        exit(1);
    }
};

#endif

