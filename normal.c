/* ------------- normal.c ------------ */

#include "dflat.h"

void SaveBorder(RECT);
void RestoreBorder(RECT);
#ifdef INCLUDE_MINIMIZE
//RECT PositionIcon(WINDOW);
#endif
struct window dwnd = {DUMMY, NULL, NormalProc,
                                {-1,-1,-1,-1}};
static short *Bsave;
static int Bht, Bwd;
BOOL WindowMoving;
BOOL WindowSizing;

#if 0
#ifdef INCLUDE_MINIMIZE
/* ---- compute lower right icon space in a rectangle ---- */
static RECT LowerRight(RECT prc)
{
    RECT rc;
    RectLeft(rc) = RectRight(prc) - ICONWIDTH;
    RectTop(rc) = RectBottom(prc) - ICONHEIGHT;
    RectRight(rc) = RectLeft(rc)+ICONWIDTH-1;
    RectBottom(rc) = RectTop(rc)+ICONHEIGHT-1;
    return rc;
}
/* ----- compute a position for a minimized window icon ---- */
RECT PositionIcon(WINDOW wnd)
{
	WINDOW pwnd = GetParent(wnd);
    RECT rc;
    RectLeft(rc) = SCREENWIDTH-ICONWIDTH;
    RectTop(rc) = SCREENHEIGHT-ICONHEIGHT;
    RectRight(rc) = SCREENWIDTH-1;
    RectBottom(rc) = SCREENHEIGHT-1;
    if (pwnd != NULL)    {
        RECT prc = WindowRect(pwnd);
		WINDOW cwnd = FirstWindow(pwnd);
        rc = LowerRight(prc);
        /* - search for icon available location - */
		while (cwnd != NULL)	{
            if (cwnd->condition == ISMINIMIZED)    {
                RECT rc1;
                rc1 = WindowRect(cwnd);
                if (RectLeft(rc1) == RectLeft(rc) &&
                        RectTop(rc1) == RectTop(rc))    {
                    RectLeft(rc) -= ICONWIDTH;
                    RectRight(rc) -= ICONWIDTH;
                    if (RectLeft(rc) < RectLeft(prc)+1)   {
                        RectLeft(rc) =
                            RectRight(prc)-ICONWIDTH;
                        RectRight(rc) =
                            RectLeft(rc)+ICONWIDTH-1;
                        RectTop(rc) -= ICONHEIGHT;
                        RectBottom(rc) -= ICONHEIGHT;
                        if (RectTop(rc) < RectTop(prc)+1)
                            return LowerRight(prc);
                    }
                    break;
                }
            }
			cwnd = NextWindow(cwnd);
        }
    }
    return rc;
}
#endif
#endif

/* --- save video area to be used by dummy window border --- */
void SaveBorder(RECT rc) // should be private
{
    RECT lrc;
    int i;
    short *cp;
    Bht = RectBottom(rc) - RectTop(rc) + 1;
    Bwd = RectRight(rc) - RectLeft(rc) + 1;
    Bsave = DFrealloc(Bsave, (Bht + Bwd) * 4);

    lrc = rc;
    RectBottom(lrc) = RectTop(lrc);
    getvideo(lrc, Bsave);
    RectTop(lrc) = RectBottom(lrc) = RectBottom(rc);
    getvideo(lrc, Bsave + Bwd);
    cp = Bsave + Bwd * 2;
    for (i = 1; i < Bht-1; i++)    {
        *cp++ = GetVideoChar(RectLeft(rc),RectTop(rc)+i);
        *cp++ = GetVideoChar(RectRight(rc),RectTop(rc)+i);
    }
}
/* ---- restore video area used by dummy window border ---- */
void RestoreBorder(RECT rc) // should be private
{
    if (Bsave != NULL)    {
        RECT lrc;
        int i;
        short *cp;
        lrc = rc;
        RectBottom(lrc) = RectTop(lrc);
        storevideo(lrc, Bsave);
        RectTop(lrc) = RectBottom(lrc) = RectBottom(rc);
        storevideo(lrc, Bsave + Bwd);
        cp = Bsave + Bwd * 2;
        for (i = 1; i < Bht-1; i++)    {
            PutVideoChar(RectLeft(rc),RectTop(rc)+i, *cp++);
            PutVideoChar(RectRight(rc),RectTop(rc)+i, *cp++);
        }
        free(Bsave);
        Bsave = NULL;
    }
}

BOOL isVisible(WINDOW wnd)
{
    while (wnd != NULL)    {
        if (isHidden(wnd))
            return FALSE;
        wnd = GetParent(wnd);
    }
    return TRUE;
}
