/* ---------- window.c ------------- */

#include "dflat.h"

int foreground, background;   /* current video colors */

static void TopLine(WINDOW, int, RECT);
WINDOW inFocusWnd();
BOOL hasStatusBar(WINDOW);

static unsigned char line[MAXCOLS];

void cDisplayTitle(WINDOW, RECT);
void cRepaintBorder(WINDOW, RECT, RECT);
void shadow_char(WINDOW, int);
void shadowline(WINDOW, RECT);

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

/* -------- display a window's title --------- */
#if 0
void cDisplayTitle(WINDOW wnd, RECT rc)
{
                int tlen = min(strlen(GetTitle(wnd)), WindowWidth(wnd)-2);
                int tend = WindowWidth(wnd)-3-BorderAdj(wnd);
        	memset(line,' ',WindowWidth(wnd));
        	if (wnd->condition != ISMINIMIZED)
            	    strncpy(line + ((WindowWidth(wnd)-2 - tlen) / 2),
                 	    GetTitle(wnd), tlen);
        	if (TestAttribute(wnd, CONTROLBOX))
            	line[2-BorderAdj(wnd)] = CONTROLBOXCHAR;
        	if (TestAttribute(wnd, MINMAXBOX))    {
            	switch (wnd->condition)    {
                	case ISRESTORED:
                    	    line[tend+1] = MAXPOINTER;
                    	    line[tend]   = MINPOINTER;
                    	    break;
                	case ISMINIMIZED:
                    	    line[tend+1] = MAXPOINTER;
                    	    break;
                	case ISMAXIMIZED:
                    	    line[tend]   = MINPOINTER;
                    	    line[tend+1] = RESTOREPOINTER;
                    	    break;
                	default:
                    	break;
            	}
        	}
        	line[RectRight(rc)+1] = line[tend+3] = '\0';
			if (wnd != inFocusWnd())
				ClipString++;
        	writeline(wnd, line+RectLeft(rc),
                       	RectLeft(rc)+BorderAdj(wnd),
                       	0,
                       	FALSE);
			ClipString = 0;
}
#endif

static unsigned int SeCorner(WINDOW wnd, unsigned int stdse)
{
	if (TestAttribute(wnd, SIZEABLE) && wnd->condition == ISRESTORED)
		return SIZETOKEN;
	return stdse;
}

/* ------- display a window's border ----- */
void cRepaintBorder(WINDOW wnd, RECT rc, RECT clrc)
{
    int y;
    unsigned int lin, side, ne, nw, se, sw;

    if (wnd == inFocusWnd())    {
        lin  = FOCUS_LINE;
        side = FOCUS_SIDE;
        ne   = FOCUS_NE;
        nw   = FOCUS_NW;
        se   = SeCorner(wnd, FOCUS_SE);
        sw   = FOCUS_SW;
    }
    else    {
        lin  = LINE;
        side = SIDE;
        ne   = NE;
        nw   = NW;
        se   = SeCorner(wnd, SE);
        sw   = SW;
    }
    line[WindowWidth(wnd)] = '\0';
    /* -------- top frame corners --------- */
#if 0
    if (RectTop(rc) == 0)    {
        if (RectLeft(rc) == 0)
            wputch(wnd, nw, 0, 0);
        if (RectLeft(rc) < WindowWidth(wnd))    {
            if (RectRight(rc) >= WindowWidth(wnd)-1)
                wputch(wnd, ne, WindowWidth(wnd)-1, 0);
            TopLine(wnd, lin, clrc);
        }
    }
#endif

    /* ----------- window body ------------ */
    for (y = RectTop(rc); y <= RectBottom(rc); y++)    {
        int ch;
        if (y == 0 || y >= WindowHeight(wnd)-1)
            continue;
        if (RectLeft(rc) == 0)
            wputch(wnd, side, 0, y);
        if (RectLeft(rc) < WindowWidth(wnd) &&
                RectRight(rc) >= WindowWidth(wnd)-1)    {
            if (TestAttribute(wnd, VSCROLLBAR))
                ch = (    y == 1 ? UPSCROLLBOX      :
                          y == WindowHeight(wnd)-2  ?
                                DOWNSCROLLBOX       :
                          y-1 == wnd->VScrollBox    ?
                                SCROLLBOXCHAR       :
                          SCROLLBARCHAR );
            else
                ch = side;
            wputch(wnd, ch, WindowWidth(wnd)-1, y);
        }
        if (RectRight(rc) == WindowWidth(wnd))
            shadow_char(wnd, y);
    }

    if (RectTop(rc) <= WindowHeight(wnd)-1 &&
            RectBottom(rc) >= WindowHeight(wnd)-1)    {
        /* -------- bottom frame corners ---------- */
        if (RectLeft(rc) == 0)
            wputch(wnd, sw, 0, WindowHeight(wnd)-1);
        if (RectLeft(rc) < WindowWidth(wnd) &&
                RectRight(rc) >= WindowWidth(wnd)-1)
            wputch(wnd, se, WindowWidth(wnd)-1,
                WindowHeight(wnd)-1);


//              if (wnd->StatusBar == NULL)	{
                if (hasStatusBar(wnd) == FALSE)	{
        	/* ----------- bottom line ------------- */
        	memset(line,lin,WindowWidth(wnd)-1);
        	if (TestAttribute(wnd, HSCROLLBAR))    {
            	line[0] = LEFTSCROLLBOX;
            	line[WindowWidth(wnd)-3] = RIGHTSCROLLBOX;
            	memset(line+1, SCROLLBARCHAR, WindowWidth(wnd)-4);
            	line[wnd->HScrollBox] = SCROLLBOXCHAR;
        	}
        	line[WindowWidth(wnd)-2] = line[RectRight(rc)] = '\0';
        	if (RectLeft(rc) != RectRight(rc) ||
	        	(RectLeft(rc) && RectLeft(rc) < WindowWidth(wnd)-1))	{
				if (wnd != inFocusWnd())
					ClipString++;
            	writeline(wnd,
                			line+(RectLeft(clrc)),
                			RectLeft(clrc)+1,
                			WindowHeight(wnd)-1,
                			FALSE);
				ClipString = 0;
			}
		}
        if (RectRight(rc) == WindowWidth(wnd))
            shadow_char(wnd, WindowHeight(wnd)-1);
    }
    if (RectBottom(rc) == WindowHeight(wnd))
        /* ---------- bottom shadow ------------- */
        shadowline(wnd, rc);
}

#if 0
static void TopLine(WINDOW wnd, int lin, RECT rc)
{
    if (TestAttribute(wnd, HASMENUBAR))
        return;
    if (TestAttribute(wnd, HASTITLEBAR) && GetTitle(wnd))
        return;
	if (RectLeft(rc) == 0)	{
		RectLeft(rc) += BorderAdj(wnd);
		RectRight(rc) += BorderAdj(wnd);
	}
	if (RectRight(rc) < WindowWidth(wnd)-1)
		RectRight(rc)++;

    if (RectLeft(rc) < RectRight(rc))    {
        /* ----------- top line ------------- */
        memset(line,lin,WindowWidth(wnd)-1);
		if (TestAttribute(wnd, CONTROLBOX))	{
			strncpy(line+1, "   ", 3);
			*(line+2) = CONTROLBOXCHAR;
		}
        line[RectRight(rc)] = '\0';
        writeline(wnd, line+RectLeft(rc),
            RectLeft(rc), 0, FALSE);
    }
}
#endif

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
