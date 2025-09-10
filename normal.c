/* ------------- normal.c ------------ */

#include "dflat.h"

#ifdef INCLUDE_MULTI_WINDOWS
void PaintOverLappers(WINDOW wnd);
void PaintUnderLappers(WINDOW wnd);
#endif

static void SaveBorder(RECT);
void RestoreBorder(RECT);
void GetVideoBuffer(WINDOW);
void PutVideoBuffer(WINDOW);
#ifdef INCLUDE_MINIMIZE
RECT PositionIcon(WINDOW);
#endif
void dragborder(WINDOW, int, int);
void sizeborder(WINDOW, int, int);
int px = -1, py = -1;
int diff;
struct window dwnd = {DUMMY, NULL, NormalProc,
                                {-1,-1,-1,-1}};
void SetParent(WINDOW, WINDOW);
static short *Bsave;
static int Bht, Bwd;
BOOL WindowMoving;
BOOL WindowSizing;
WINDOW HiddenWindow;

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

/* ---- build a dummy window border for moving or sizing --- */
void dragborder(WINDOW wnd, int x, int y)
{
    RestoreBorder(dwnd.rc);
    /* ------- build the dummy window -------- */
    dwnd.rc.lf = x;
    dwnd.rc.tp = y;
    dwnd.rc.rt = dwnd.rc.lf+WindowWidth(wnd)-1;
    dwnd.rc.bt = dwnd.rc.tp+WindowHeight(wnd)-1;
    dwnd.ht = WindowHeight(wnd);
    dwnd.wd = WindowWidth(wnd);
//    dwnd.parent = GetParent(wnd);
    SetParent(&dwnd, GetParent(wnd));
    dwnd.attrib = VISIBLE | HASBORDER | NOCLIP;
    InitWindowColors(&dwnd);
    SaveBorder(dwnd.rc);
    RepaintBorder(&dwnd, NULL);
}
/* ---- write the dummy window border for sizing ---- */
void sizeborder(WINDOW wnd, int rt, int bt)
{
    int leftmost = GetLeft(wnd)+10;
    int topmost = GetTop(wnd)+3;
    int bottommost = SCREENHEIGHT-1;
    int rightmost  = SCREENWIDTH-1;
    if (GetParent(wnd))    {
        bottommost = min(bottommost,
            GetClientBottom(GetParent(wnd)));
        rightmost  = min(rightmost,
            GetClientRight(GetParent(wnd)));
    }
    rt = min(rt, rightmost);
    bt = min(bt, bottommost);
    rt = max(rt, leftmost);
    bt = max(bt, topmost);
    SendMessage(NULL, MOUSE_CURSOR, rt, bt);

    if (rt != px || bt != py)
        RestoreBorder(dwnd.rc);

    /* ------- change the dummy window -------- */
    dwnd.ht = bt-dwnd.rc.tp+1;
    dwnd.wd = rt-dwnd.rc.lf+1;
    dwnd.rc.rt = rt;
    dwnd.rc.bt = bt;
    if (rt != px || bt != py)    {
        px = rt;
        py = bt;
        SaveBorder(dwnd.rc);
        RepaintBorder(&dwnd, NULL);
    }
}

#ifdef INCLUDE_MULTI_WINDOWS
/* ----- adjust a rectangle to include the shadow ----- */
static RECT adjShadow(WINDOW wnd)
{
    RECT rc;
    rc = wnd->rc;
    if (TestAttribute(wnd, SHADOW))    {
        if (RectRight(rc) < SCREENWIDTH-1)
            RectRight(rc)++;           
        if (RectBottom(rc) < SCREENHEIGHT-1)
            RectBottom(rc)++;
    }
    return rc;
}
/* --- repaint a rectangular subsection of a window --- */
static void near PaintOverLap(WINDOW wnd, RECT rc)
{
    if (isVisible(wnd))    {
        int isBorder, isTitle, isData;
        isBorder = isTitle = FALSE;
        isData = TRUE;
        if (TestAttribute(wnd, HASBORDER))    {
            isBorder =  RectLeft(rc) == 0 &&
                        RectTop(rc) < WindowHeight(wnd);
            isBorder |= RectLeft(rc) < WindowWidth(wnd) &&
                        RectRight(rc) >= WindowWidth(wnd)-1 &&
                        RectTop(rc) < WindowHeight(wnd);
            isBorder |= RectTop(rc) == 0 &&
                        RectLeft(rc) < WindowWidth(wnd);
            isBorder |= RectTop(rc) < WindowHeight(wnd) &&
                        RectBottom(rc) >= WindowHeight(wnd)-1 &&
                        RectLeft(rc) < WindowWidth(wnd);
        }
        else if (TestAttribute(wnd, HASTITLEBAR))
            isTitle = RectTop(rc) == 0 &&
                      RectRight(rc) > 0 &&
                      RectLeft(rc)<WindowWidth(wnd)-BorderAdj(wnd);

        if (RectLeft(rc) >= WindowWidth(wnd)-BorderAdj(wnd))
            isData = FALSE;
        if (RectTop(rc) >= WindowHeight(wnd)-BottomBorderAdj(wnd))
            isData = FALSE;
        if (TestAttribute(wnd, HASBORDER))    {
            if (RectRight(rc) == 0)
                isData = FALSE;
            if (RectBottom(rc) == 0)
                isData = FALSE;
        }
        if (TestAttribute(wnd, SHADOW))
            isBorder |= RectRight(rc) == WindowWidth(wnd) ||
                        RectBottom(rc) == WindowHeight(wnd);
        if (isData)	{
			wnd->wasCleared = FALSE;
            SendMessage(wnd, PAINT, (PARAM) &rc, TRUE);
		}
        if (isBorder)
            SendMessage(wnd, BORDER, (PARAM) &rc, 0);
        else if (isTitle)
            DisplayTitle(wnd, &rc);
    }
}
/* ------ paint the part of a window that is overlapped
            by another window that is being hidden ------- */
static void PaintOver(WINDOW wnd)
{
    RECT wrc, rc;
    wrc = adjShadow(HiddenWindow);
    rc = adjShadow(wnd);
    rc = subRectangle(rc, wrc);
    if (ValidRect(rc))
        PaintOverLap(wnd, RelativeWindowRect(wnd, rc));
}
/* --- paint the overlapped parts of all children --- */
static void PaintOverChildren(WINDOW pwnd)
{
    WINDOW cwnd = FirstWindow(pwnd);
    while (cwnd != NULL)    {
        if (cwnd != HiddenWindow)    {
            PaintOver(cwnd);
            PaintOverChildren(cwnd);
        }
        cwnd = NextWindow(cwnd);
    }
}
/* -- recursive overlapping paint of parents -- */
static void PaintOverParents(WINDOW wnd)
{
    WINDOW pwnd = GetParent(wnd);
    if (pwnd != NULL)    {
        PaintOverParents(pwnd);
        PaintOver(pwnd);
        PaintOverChildren(pwnd);
    }
}
/* - paint the parts of all windows that a window is over - */
void PaintOverLappers(WINDOW wnd)
{
    HiddenWindow = wnd;
    PaintOverParents(wnd);
}
/* --- paint those parts of a window that are overlapped --- */
void near PaintUnderLappers(WINDOW wnd)
{
    WINDOW hwnd = NextWindow(wnd);
    while (hwnd != NULL)    {
        /* ------- test only at document window level ------ */
        WINDOW pwnd = GetParent(hwnd);
/*        if (pwnd == NULL || GetClass(pwnd) == APPLICATION)  */  {
            /* ---- don't bother testing self ----- */
            if (isVisible(hwnd) && hwnd != wnd)    {
                /* --- see if other window is descendent --- */
                while (pwnd != NULL)    {
                    if (pwnd == wnd)
                        break;
                    pwnd = GetParent(pwnd);
                }
                /* ----- don't test descendent overlaps ----- */
                if (pwnd == NULL)    {
                    /* -- see if other window is ancestor --- */
                    pwnd = GetParent(wnd);
                    while (pwnd != NULL)    {
                        if (pwnd == hwnd)
                            break;
                        pwnd = GetParent(pwnd);
                    }
                    /* --- don't test ancestor overlaps --- */
                    if (pwnd == NULL)    {
                        HiddenWindow = GetAncestor(hwnd);
                        ClearVisible(HiddenWindow);
                        PaintOver(wnd);
                        SetVisible(HiddenWindow);
                    }
                }
            }
        }
        hwnd = NextWindow(hwnd);
    }
    /* --------- repaint all children of this window
        the same way ----------- */
    hwnd = FirstWindow(wnd);
    while (hwnd != NULL)    {
        PaintUnderLappers(hwnd);
        hwnd = NextWindow(hwnd);
    }
}
#endif /* #ifdef INCLUDE_MULTI_WINDOWS */

/* --- save video area to be used by dummy window border --- */
static void SaveBorder(RECT rc)
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
void RestoreBorder(RECT rc)
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

/*
BOOL isDerivedFrom(WINDOW wnd, CLASS Class)
{
    CLASS tclass = GetClass(wnd);
    while (tclass != -1)    {
        if (tclass == Class)
            return TRUE;
        tclass = (classdefs[tclass].base);
    }
    return FALSE;
}
*/

/* -- find the oldest document window ancestor of a window -- */
WINDOW GetAncestor(WINDOW wnd)
{
    if (wnd != NULL)    {
        while (GetParent(wnd) != NULL)    {
            if (GetClass(GetParent(wnd)) == APPLICATION)
                break;
            wnd = GetParent(wnd);
        }
    }
    return wnd;
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

/* -- adjust a window's rectangle to clip it to its parent - */
/*
static RECT near ClipRect(WINDOW wnd)
{
    RECT rc;
    rc = WindowRect(wnd);
    if (TestAttribute(wnd, SHADOW))    {
        RectBottom(rc)++;
        RectRight(rc)++;
    }
	return ClipRectangle(wnd, rc);
}
*/

/* -- get the video memory that is to be used by a window -- */
/*
void GetVideoBuffer(WINDOW wnd)
{
    RECT rc;
    int ht;
    int wd;

    rc = ClipRect(wnd);
    ht = RectBottom(rc) - RectTop(rc) + 1;
    wd = RectRight(rc) - RectLeft(rc) + 1;
    wnd->videosave = DFrealloc(wnd->videosave, (ht * wd * 2));
    get_videomode();
    getvideo(rc, wnd->videosave);
}
*/

/* -- put the video memory that is used by a window -- */
/*
void PutVideoBuffer(WINDOW wnd)
{
    if (wnd->videosave != NULL)    {
    	RECT rc;
    	rc = ClipRect(wnd);
    	get_videomode();
    	storevideo(rc, wnd->videosave);
    	free(wnd->videosave);
    	wnd->videosave = NULL;
	}
}
*/

/* ------- return TRUE if awnd is an ancestor of wnd ------- */
/*
BOOL isAncestor(WINDOW wnd, WINDOW awnd)
{
	while (wnd != NULL)	{
		if (wnd == awnd)
			return TRUE;
		wnd = GetParent(wnd);
	}
	return FALSE;
}
*/
