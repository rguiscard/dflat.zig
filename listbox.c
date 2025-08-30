/* ------------- listbox.c ------------ */

#include "dflat.h"

#ifdef INCLUDE_EXTENDEDSELECTIONS
static int ExtendSelections(WINDOW, int, int);
static void TestExtended(WINDOW, PARAM);
static void ClearAllSelections(WINDOW);
static void SetSelection(WINDOW, int);
static void FlipSelection(WINDOW, int);
static void ClearSelection(WINDOW, int);
#else
#define TestExtended(w,p) /**/
#endif
void ChangeSelection(WINDOW, int, int);
void WriteSelection(WINDOW, int, int, RECT *);
static BOOL SelectionInWindow(WINDOW, int);

static int py = -1;    /* the previous y mouse coordinate */

#ifdef INCLUDE_EXTENDEDSELECTIONS
/* --------- SHIFT_F8 Key ------------ */
static void AddModeKey(WINDOW wnd)
{
    if (isMultiLine(wnd))    {
        wnd->AddMode ^= TRUE;
        SendMessage(GetParent(wnd), ADDSTATUS,
            wnd->AddMode ? ((PARAM) "Add Mode") : 0, 0);
    }
}
#endif

#ifdef INCLUDE_EXTENDEDSELECTIONS
/* --------- Space Bar Key ------------ */
static void SpacebarKey(WINDOW wnd, PARAM p2)
{
    if (isMultiLine(wnd))    {
        int sel = SendMessage(wnd, LB_CURRENTSELECTION, 0, 0);
        if (sel != -1)    {
            if (wnd->AddMode)
                FlipSelection(wnd, sel);
            if (ItemSelected(wnd, sel))    {
                if (!((int) p2 & (LEFTSHIFT | RIGHTSHIFT)))
                    wnd->AnchorPoint = sel;
                ExtendSelections(wnd, sel, (int) p2);
            }
            else
                wnd->AnchorPoint = -1;
            SendMessage(wnd, PAINT, 0, 0);
        }
    }
}
#endif

void ListCopyText(char *dst, char *src) {
    while (src && *src && *src != '\n')
        *dst++ = *src++;
    *dst = '\0';
}

static BOOL SelectionInWindow(WINDOW wnd, int sel)
{
    return (wnd->wlines && sel >= wnd->wtop &&
            sel < wnd->wtop+ClientHeight(wnd));
}

void WriteSelection(WINDOW wnd, int sel,
                                    int reverse, RECT *rc)
{
    if (isVisible(wnd))
        if (SelectionInWindow(wnd, sel))
            WriteTextLine(wnd, rc, sel, reverse);
}

#ifdef INCLUDE_EXTENDEDSELECTIONS
/* ----- Test for extended selections in the listbox ----- */
static void TestExtended(WINDOW wnd, PARAM p2)
{
    if (isMultiLine(wnd) && !wnd->AddMode &&
            !((int) p2 & (LEFTSHIFT | RIGHTSHIFT)))    {
        if (wnd->SelectCount > 1)    {
            ClearAllSelections(wnd);
            SendMessage(wnd, PAINT, 0, 0);
        }
    }
}

/* ----- Clear selections in the listbox ----- */
static void ClearAllSelections(WINDOW wnd)
{
    if (isMultiLine(wnd) && wnd->SelectCount > 0)    {
        int sel;
        for (sel = 0; sel < wnd->wlines; sel++)
            ClearSelection(wnd, sel);
    }
}

/* ----- Invert a selection in the listbox ----- */
static void FlipSelection(WINDOW wnd, int sel)
{
    if (isMultiLine(wnd))    {
        if (ItemSelected(wnd, sel))
            ClearSelection(wnd, sel);
        else
            SetSelection(wnd, sel);
    }
}

static int ExtendSelections(WINDOW wnd, int sel, int shift)
{    
    if (shift & (LEFTSHIFT | RIGHTSHIFT) &&
                        wnd->AnchorPoint != -1)    {
        int i = sel;
        int j = wnd->AnchorPoint;
        int rtn;
        if (j > i)
            swap(i,j);
        rtn = i - j;
        while (j <= i)
            SetSelection(wnd, j++);
        return rtn;
    }
    return 0;
}

static void SetSelection(WINDOW wnd, int sel)
{
    if (isMultiLine(wnd) && !ItemSelected(wnd, sel))    {
        char *lp = TextLine(wnd, sel);
        *lp = LISTSELECTOR;
        wnd->SelectCount++;
    }
}

static void ClearSelection(WINDOW wnd, int sel)
{
    if (isMultiLine(wnd) && ItemSelected(wnd, sel))    {
        char *lp = TextLine(wnd, sel);
        *lp = ' ';
        --wnd->SelectCount;
    }
}

BOOL ItemSelected(WINDOW wnd, int sel)
{
	if (sel != -1 && isMultiLine(wnd) && sel < wnd->wlines)    {
        char *cp = TextLine(wnd, sel);
        return (int)((*cp) & 255) == LISTSELECTOR;
    }
    return FALSE;
}
#endif

void ChangeSelection(WINDOW wnd,int sel,int shift)
{
    if (sel != wnd->selection)    {
#ifdef INCLUDE_EXTENDEDSELECTIONS
        if (sel != -1 && isMultiLine(wnd))        {
            int sels;
            if (!wnd->AddMode)
                ClearAllSelections(wnd);
            sels = ExtendSelections(wnd, sel, shift);
            if (sels > 1)
                SendMessage(wnd, PAINT, 0, 0);
            if (sels == 0 && !wnd->AddMode)    {
                ClearSelection(wnd, wnd->selection);
                SetSelection(wnd, sel);
                wnd->AnchorPoint = sel;
            }
        }
#endif
        WriteSelection(wnd, wnd->selection, FALSE, NULL);
        wnd->selection = sel;
		if (sel != -1)
	        WriteSelection(wnd, sel, TRUE, NULL);
     }
}
