/* ----------- fileopen.c ------------- */

#include "dflat.h"

static void StripPath(char *);

/*
 * Strip the path information from a file spec
 */
static void StripPath(char *filespec)
{
    char *cp, *cp1;

    cp = filespec;
    while (TRUE)    {
        cp1 = strchr(cp, '/');
        if (cp1 == NULL)
            break;
        cp = cp1+1;
    }
    strcpy(filespec, cp);
}
