/* ---------- window.c ------------- */

#include "dflat.h"

int foreground, background;   /* current video colors */

/* ------ write a line to video window client area ------ */
void writeline(WINDOW wnd, char *str, int x, int y, BOOL pad)
{
    char *cp;
    int len;
    int dif;
	char wline[MAXCOLS];

    memset(wline, 0, sizeof(wline));
    len = LineLength(str);
    dif = strlen(str) - len;
    strncpy(wline, str, ClientWidth(wnd) + dif);
    if (pad)    {
        cp = wline+strlen(wline);
        while (len++ < ClientWidth(wnd)-x)
            *cp++ = ' ';
    }
    wputs(wnd, wline, x, y);
}

/* ------ compute the logical line length of a window ------ */
int LineLength(char *ln)
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

void PutWindowLine(WINDOW wnd, void *s, int x, int y)
{
	int saved = FALSE, sv;
	if (x < ClientWidth(wnd) && y < ClientHeight(wnd))	{
		char *en = (char *)s+ClientWidth(wnd)-x;
		if (strlen(s)+x > ClientWidth(wnd))	{
			sv = *en;
			*en = '\0';
			saved = TRUE;
		}
		ClipString++;
		wputs(wnd, s, x+BorderAdj(wnd), y+TopBorderAdj(wnd));
		--ClipString;
		if (saved)
			*en = sv;
	}
}
