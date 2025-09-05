/* ----------------- dialbox.c -------------- */

#include "dflat.h"

int inFocusCommand(DBOX *);
BOOL dbShortcutKeys(DBOX *, int);
void FirstFocus(DBOX *db);
void NextFocus(DBOX *db);
void PrevFocus(DBOX *db);
void FixColors(WINDOW wnd);
CTLWINDOW *WindowControl(DBOX *, WINDOW);
static CTLWINDOW *AssociatedControl(DBOX *, enum commands);

static DBOX **dbs = NULL;
static int dbct = 0;

/* --- clear all heap allocations to control text fields --- */
void ClearDialogBoxes(void)
{
    int i;
    for (i = 0; i < dbct; i++)    {
        CTLWINDOW *ct = (*(dbs+i))->ctl;
        while (ct->Class)    {
            if ((ct->Class == EDITBOX ||
				 ct->Class == TEXTBOX ||
                 ct->Class == COMBOBOX) &&
                    ct->itext != NULL)	{
                free(ct->itext);
				ct->itext = NULL;
			}
            ct++;
        }
    }
    if (dbs != NULL)    {
        free(dbs);
        dbs = NULL;
    }
    dbct = 0;
}

/* ----- return command code of in-focus control window ---- */
/*
int inFocusCommand(DBOX *db)
{
    CTLWINDOW *ct = db->ctl;
    while (ct->Class)    {
        if (ct->wnd == inFocus)
            return ct->command;
        ct++;
    }
    return -1;
}
*/

/* -------- find a specified control structure ------- */
/*
CTLWINDOW *FindCommand(DBOX *db, enum commands cmd, int Class)
{
    CTLWINDOW *ct = db->ctl;
    while (ct->Class)    {
        if (Class == -1 || ct->Class == Class)
            if (cmd == ct->command)
                return ct;
        ct++;
    }
    return NULL;
}
*/

/* ---- return the window handle of a specified command ---- */
/*
WINDOW ControlWindow(const DBOX *db, enum commands cmd)
{
    const CTLWINDOW *ct = db->ctl;
    while (ct->Class)    {
        if (ct->Class != TEXT && cmd == ct->command)
            return ct->wnd;
        ct++;
    }
    return NULL;
}
*/

/* --- return a pointer to the control structure that matches a window --- */
/*
CTLWINDOW *WindowControl(DBOX *db, WINDOW wnd)
{
    CTLWINDOW *ct = db->ctl;
    while (ct->Class)    {
        if (ct->wnd == wnd)
            return ct;
        ct++;
    }
    return NULL;
}
*/

/* ---- set a control ON or OFF ----- */
/*
void ControlSetting(DBOX *db, enum commands cmd,
                                int Class, int setting)
{
    CTLWINDOW *ct = FindCommand(db, cmd, Class);
    if (ct != NULL)	{
        ct->isetting = setting;
		if (ct->wnd != NULL)
			ct->setting = setting;
	}
}
*/

/* ----- test if a control is on or off ----- */
/*
BOOL isControlOn(DBOX *db, enum commands cmd, int Class)
{
    const CTLWINDOW *ct = FindCommand(db, cmd, Class);
    return ct ? (ct->wnd ? ct->setting : ct->isetting) : FALSE;
}
*/

/* -- find control structure associated with text control -- */
static CTLWINDOW *AssociatedControl(DBOX *db,enum commands Tcmd)
{
    CTLWINDOW *ct = db->ctl;
    while (ct->Class)    {
        if (ct->Class != TEXT)
            if (ct->command == Tcmd)
                break;
        ct++;
    }
    return ct;
}

/* --- process dialog box shortcut keys --- */
BOOL dbShortcutKeys(DBOX *db, int ky)
{
    CTLWINDOW *ct;
    int ch = AltConvert(ky);

    if (ch != 0)    {
        ct = db->ctl;
        while (ct->Class)    {
            char *cp = ct->itext;
            while (cp && *cp)    {
                if (*cp == SHORTCUTCHAR &&
                            tolower(*(cp+1)) == ch)    {
                    if (ct->Class == TEXT)
                        ct = AssociatedControl(db, ct->command);
                    if (ct->Class == RADIOBUTTON)
                        SetRadioButton(db, ct);
                    else if (ct->Class == CHECKBOX)    {
                        ct->setting ^= ON;
                        SendMessage(ct->wnd, PAINT, 0, 0);
                    }
                    else if (ct->Class)    {
                        SendMessage(ct->wnd, SETFOCUS, TRUE, 0);
                        if (ct->Class == BUTTON)
                           SendMessage(ct->wnd,KEYBOARD,'\r',0);
                    }
                    return TRUE;
                }
                cp++;
            }
            ct++;
        }
    }
	return FALSE;
}

/* ---- change the focus to the first control --- */
void FirstFocus(DBOX *db)
{
    CTLWINDOW *ct = db->ctl;
	if (ct != NULL)	{
		while (ct->Class == TEXT || ct->Class == BOX)	{
			ct++;
			if (ct->Class == 0)
				return;
		}
		SendMessage(ct->wnd, SETFOCUS, TRUE, 0);
	}
}

/* ---- change the focus to the next control --- */
void NextFocus(DBOX *db)
{
    CTLWINDOW *ct = WindowControl(db, inFocus);
	int looped = 0;
	if (ct != NULL)	{
		do	{
			ct++;
			if (ct->Class == 0)	{
				if (looped)
					return;
				looped++;
				ct = db->ctl;
			}
		} while (ct->Class == TEXT || ct->Class == BOX);
		SendMessage(ct->wnd, SETFOCUS, TRUE, 0);
	}
}

/* ---- change the focus to the previous control --- */
void PrevFocus(DBOX *db)
{
    CTLWINDOW *ct = WindowControl(db, inFocus);
	int looped = 0;
	if (ct != NULL)	{
		do	{
			if (ct == db->ctl)	{
				if (looped)
					return;
				looped++;
				while (ct->Class)
					ct++;
			}
			--ct;
		} while (ct->Class == TEXT || ct->Class == BOX);
		SendMessage(ct->wnd, SETFOCUS, TRUE, 0);
	}
}

void SetFocusCursor(WINDOW wnd)
{
    if (wnd == inFocus)    {
        SendMessage(NULL, SHOW_CURSOR, 0, 0);
        SendMessage(wnd, KEYBOARD_CURSOR, 1, 0);
    }
}
