/* ------------- applicat.c ------------- */

#include "dflat.h"

static int ScreenHeight;
WINDOW ApplicationWindow;

extern DBOX Display;

#ifdef INCLUDE_MULTI_WINDOWS
extern DBOX Windows;
#endif

void SelectColors(WINDOW);
void SetScreenHeight(int);
void SelectLines(WINDOW);

#ifdef INCLUDE_WINDOWOPTIONS
void SelectTexture(void);
void SelectBorder(WINDOW);
void SelectTitle(WINDOW);
void SelectStatusBar(WINDOW);
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

/* ----------- Prepare the Window menu ------------ */
void PrepWindowMenu(void *w, struct Menu *mnu)
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
        /* ----- point to the APPLICATION window ----- */
		if (ApplicationWindow == NULL)
			return;
		cwnd = FirstWindow(ApplicationWindow);
        /* ----- get the first 9 document windows ----- */
        while (cwnd != NULL && MenuNo < 9)    {
            if (isVisible(cwnd) && GetClass(cwnd) != MENUBAR &&
                    GetClass(cwnd) != STATUSBAR) {
                /* --- add the document window to the menu --- */
#if MSDOS | ELKS
                strncpy(Menus[MenuNo]+4, WindowName(cwnd), 20);
#endif
                pd->SelectionTitle = Menus[MenuNo];
                if (cwnd == oldFocus)    {
                    /* -- mark the current document -- */
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

static void DoWindowColors(WINDOW wnd)
{
    WINDOW cwnd;
    InitWindowColors(wnd);
	cwnd = FirstWindow(wnd);
	while (cwnd != NULL)	{
        DoWindowColors(cwnd);
#ifndef BUILD_SMALL_DFLAT
        if (GetClass(cwnd) == TEXT && GetText(cwnd) != NULL)
            SendMessage(cwnd, CLEARTEXT, 0, 0);
#endif
		cwnd = NextWindow(cwnd);
    }
}

/* ----- set up colors for the application window ------ */
void SelectColors(WINDOW wnd)
{
#ifdef INCLUDE_WINDOWMENU
    if (RadioButtonSetting(&Display, ID_MONO))
        cfg.mono = 1;   /* mono */
    else if (RadioButtonSetting(&Display, ID_REVERSE))
        cfg.mono = 2;   /* mono reverse */
    else
        cfg.mono = 0;   /* color */
    printf("color %d\n", cfg.mono);

    if (cfg.mono == 1)
        memcpy(cfg.clr, bw, sizeof bw);
    else if (cfg.mono == 2)
        memcpy(cfg.clr, reverse, sizeof reverse);
    else
#endif
        memcpy(cfg.clr, color, sizeof color);
    DoWindowColors(wnd);
}

/* ---- select screen lines ---- */
void SelectLines(WINDOW wnd)
{
    cfg.ScreenLines = SCREENHEIGHT;
    if (SCREENHEIGHT != cfg.ScreenLines)    {
        SetScreenHeight(cfg.ScreenLines);
		/* ---- re-maximize ---- */
        if (wnd->condition == ISMAXIMIZED)	{
            SendMessage(wnd, SIZE, (PARAM) GetRight(wnd),
                SCREENHEIGHT-1);
			return;
		}
		/* --- adjust if current size does not fit --- */
		if (WindowHeight(wnd) > SCREENHEIGHT)
            SendMessage(wnd, SIZE, (PARAM) GetRight(wnd),
                (PARAM) GetTop(wnd)+SCREENHEIGHT-1);
		/* --- if window is off-screen, move it on-screen --- */
		if (GetTop(wnd) >= SCREENHEIGHT-1)
			SendMessage(wnd, MOVE, (PARAM) GetLeft(wnd),
				(PARAM) SCREENHEIGHT-WindowHeight(wnd));
    }
}

/* ---- set the screen height in the video hardware ---- */
void SetScreenHeight(int height)
{
#if 0	/* display size changes not supported */
        SendMessage(NULL, SAVE_CURSOR, 0, 0);

        /* change display size here */

        SendMessage(NULL, RESTORE_CURSOR, 0, 0);
        SendMessage(NULL, RESET_MOUSE, 0, 0);
        SendMessage(NULL, SHOW_MOUSE, 0, 0);
    }
#endif
}

#ifdef INCLUDE_WINDOWMENU

/* ----- select the screen texture ----- */
void SelectTexture(void)
{
    cfg.Texture = CheckBoxSetting(&Display, ID_TEXTURE);
}

/* -- select whether the application screen has a border -- */
void SelectBorder(WINDOW wnd)
{
    cfg.Border = CheckBoxSetting(&Display, ID_BORDER);
    if (cfg.Border)
        AddAttribute(wnd, HASBORDER);
    else
        ClearAttribute(wnd, HASBORDER);
}

/* select whether the application screen has a status bar */
void SelectStatusBar(WINDOW wnd)
{
    cfg.StatusBar = CheckBoxSetting(&Display, ID_STATUSBAR);
    if (cfg.StatusBar)
        AddAttribute(wnd, HASSTATUSBAR);
    else
        ClearAttribute(wnd, HASSTATUSBAR);
}

/* select whether the application screen has a title bar */
void SelectTitle(WINDOW wnd)
{
    cfg.Title = CheckBoxSetting(&Display, ID_TITLE);
    if (cfg.Title)
        AddAttribute(wnd, HASTITLEBAR);
    else
        ClearAttribute(wnd, HASTITLEBAR);
}

#endif
