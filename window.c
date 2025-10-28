/* ---------- window.c ------------- */

#include "dflat.h"

int foreground, background;   /* current video colors */

/* ------ write a line to video window client area ------ */
#if 0
void writeline(WINDOW wnd, char *str, int x, int y, BOOL pad)
{
    char *cp;
    int len;
    int dif;
	char wline[MAXCOLS];

    memset(wline, 0, sizeof(wline));
    len = LineLength(str);
    dif = strlen(str) - len;
    strncpy(wline, str, c_ClientWidth(wnd) + dif);
    if (pad)    {
        cp = wline+strlen(wline);
        while (len++ < c_ClientWidth(wnd)-x)
            *cp++ = ' ';
    }
    wputs(wnd, wline, x, y);
}
#endif

/* ------ compute the logical line length of a window ------ */
#if 0
int cLineLength(char *ln)
{
    int len = strlen(ln);
    char *cp = ln;
    while ((cp = strchr(cp, CHANGECOLOR)) != NULL)    {
        cp++;
        len -= 3;
    }
    cp = ln;
    while ((cp = strchr(cp, RESETCOLOR)) != NULL)    {
        cp++;
        --len;
    }
    return len;
}
#endif
