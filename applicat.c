/* ------------- applicat.c ------------- */

#include "dflat.h"

static int ScreenHeight;
WINDOW ApplicationWindow;

#ifdef INCLUDE_MULTI_WINDOWS
extern DBOX Windows;
#endif

static WINDOW oldFocus;
#ifdef INCLUDE_MULTI_WINDOWS
static void MoreWindows(WINDOW);
static void ChooseWindow(WINDOW, int);
static int WindowSel;
static char *Menus[9] = {
    "~1.                      ",
    "~2.                      ",
    "~3.                      ",
    "~4.                      ",
    "~5.                      ",
    "~6.                      ",
    "~7.                      ",
    "~8.                      ",
    "~9.                      "
};
#endif

char **Argv;

#ifdef INCLUDE_WINDOWMENU
/* -------- return the name of a document window ------- */
/*
static char *WindowName(WINDOW wnd)
{
    if (GetTitle(wnd) == NULL)    {
        if (GetClass(wnd) == DIALOG)
            return ((DBOX *)(wnd->extension))->HelpName;
        else 
            return "Untitled";
    }
    else
        return GetTitle(wnd);
}
*/

/* ----------- Prepare the Window menu ------------ */
/* This is left to later fix zig version
void cPrepWindowMenu(void *w, struct Menu *mnu)
{
    WINDOW wnd = w;
    struct PopDown *p0 = mnu->Selections;
    struct PopDown *pd = mnu->Selections + 2;
    struct PopDown *ca = mnu->Selections + 13;
    int MenuNo = 0;
    WINDOW cwnd;
    mnu->Selection = 0;
    oldFocus = NULL;
    if (GetClass(wnd) != APPLICATION)    {
        oldFocus = wnd;
        // ----- point to the APPLICATION window ----- 
		if (ApplicationWindow == NULL)
			return;
		cwnd = FirstWindow(ApplicationWindow);
        // ----- get the first 9 document windows ----- 
        while (cwnd != NULL && MenuNo < 9)    {
            if (isVisible(cwnd) && GetClass(cwnd) != MENUBAR &&
                    GetClass(cwnd) != STATUSBAR) {
                // --- add the document window to the menu --- 
#if MSDOS | ELKS
                strncpy(Menus[MenuNo]+4, WindowName(cwnd), 20);
#endif
                pd->SelectionTitle = Menus[MenuNo];
                if (cwnd == oldFocus)    {
                    // -- mark the current document -- 
                    pd->Attrib |= CHECKED;
                    mnu->Selection = MenuNo+2;
                }
                else
                    pd->Attrib &= ~CHECKED;
                pd++;
                MenuNo++;
            }
			cwnd = NextWindow(cwnd);
        }
    }
    if (MenuNo)
        p0->SelectionTitle = "~Close all";
    else
        p0->SelectionTitle = NULL;
    if (MenuNo >= 9)    {
        *pd++ = *ca;
        if (mnu->Selection == 0)
            mnu->Selection = 11;
    }
    pd->SelectionTitle = NULL;
}
*/

/* window processing module for the More Windows dialog box */
static int WindowPrep(WINDOW wnd,MESSAGE msg,PARAM p1,PARAM p2)
{
    switch (msg)    {
        case INITIATE_DIALOG:    {
            WINDOW wnd1;
            WINDOW cwnd = ControlWindow(&Windows,ID_WINDOWLIST);
            int sel = 0;
            if (cwnd == NULL)
                return FALSE;
			wnd1 = FirstWindow(ApplicationWindow);
			while (wnd1 != NULL)	{
                if (isVisible(wnd1) && wnd1 != wnd &&
						GetClass(wnd1) != MENUBAR &&
                        	GetClass(wnd1) != STATUSBAR)    {
                    if (wnd1 == oldFocus)
                        WindowSel = sel;
                    SendMessage(cwnd, ADDTEXT,
                        (PARAM) WindowName(wnd1), 0);
                    sel++;
                }
				wnd1 = NextWindow(wnd1);
            }
            SendMessage(cwnd, LB_SETSELECTION, WindowSel, 0);
            AddAttribute(cwnd, VSCROLLBAR);
            PostMessage(cwnd, SHOW_WINDOW, 0, 0);
            break;
        }
        case COMMAND:
            switch ((int) p1)    {
                case ID_OK:
                    if ((int)p2 == 0) {
			int val = -1;
                        SendMessage(
                                    ControlWindow(&Windows,
                                    ID_WINDOWLIST),
                                    LB_CURRENTSELECTION, (PARAM)&val, 0);
			WindowSel = val;

	            }
                    break;
                case ID_WINDOWLIST:
                    if ((int) p2 == LB_CHOOSE)
                        SendMessage(wnd, COMMAND, ID_OK, 0);
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
    return DefaultWndProc(wnd, msg, p1, p2);
}

/* ---- the More Windows command on the Window menu ---- */
static void MoreWindows(WINDOW wnd)
{
    if (DialogBox(wnd, &Windows, TRUE, WindowPrep))
        ChooseWindow(wnd, WindowSel);
}

/* ----- user chose a window from the Window menu
        or the More Window dialog box ----- */
static void ChooseWindow(WINDOW wnd, int WindowNo)
{
    WINDOW cwnd = FirstWindow(wnd);
	while (cwnd != NULL)	{
        if (isVisible(cwnd) &&
				GetClass(cwnd) != MENUBAR &&
                	GetClass(cwnd) != STATUSBAR)
            if (WindowNo-- == 0)
                break;
		cwnd = NextWindow(cwnd);
    }
    if (cwnd != NULL)    {
        SendMessage(cwnd, SETFOCUS, TRUE, 0);
        if (cwnd->condition == ISMINIMIZED)
            SendMessage(cwnd, RESTORE, 0, 0);
    }
}

#endif    /* #ifdef INCLUDE_WINDOWMENU */
