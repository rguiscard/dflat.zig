/* ---------------- menubar.c ------------------ */

#include "dflat.h"

/*
MBAR *ActiveMenuBar;
MENU *ActiveMenu;
*/

// return FALSE to break;
BOOL cBuildMenu(WINDOW wnd, char *title, int offset, char **buf) {
    if (strlen(*buf+offset) < strlen(title)+3)
        return FALSE;
    *buf = DFrealloc(*buf, strlen(*buf)+5);
    memmove(*buf+offset+4, *buf+offset, strlen(*buf)-offset+1);
    CopyCommand(*buf+offset,title,FALSE,wnd->WindowColors [STD_COLOR] [BG]);

    return TRUE;
}

void cPaintMenu(WINDOW wnd, int offset, int offset1, int selection) {
    char *cp;
    char sel[MAXCOLS];
    memset(sel, '\0', MAXCOLS);
    strcpy(sel, GetText(wnd)+offset);
    cp = strchr(sel, CHANGECOLOR);
    if (cp != NULL)
        *(cp + 2) = background | 0x80;
//    wputs(wnd, sel, offset-ActiveMenuBar->ActiveSelection*4, 0);
    wputs(wnd, sel, offset-selection*4, 0);
    GetText(wnd)[offset1] = ' ';
}

/*
WINDOW GetDocFocus(void)
{
	WINDOW wnd = ApplicationWindow;
	if (wnd != NULL)	{
		wnd = LastWindow(wnd);
		while (wnd != NULL && (GetClass(wnd) == MENUBAR ||
							GetClass(wnd) == STATUSBAR))
			wnd = PrevWindow(wnd);
		if (wnd != NULL)
			while (wnd->childfocus != NULL)
				wnd = wnd->childfocus;
	}
	return wnd ? wnd : ApplicationWindow;
}
*/
