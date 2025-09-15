/* ------------- normal.c ------------ */

#include "dflat.h"

void SaveBorder(RECT);
void RestoreBorder(RECT);

static short *Bsave;
static int Bht, Bwd;
BOOL WindowMoving;
BOOL WindowSizing;

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
