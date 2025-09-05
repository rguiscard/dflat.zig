/* -------- radio.c -------- */

#include "dflat.h"

static CTLWINDOW *rct[MAXRADIOS];
/*
static BOOL Setting = TRUE;

void SetRadioButton(DBOX *db, CTLWINDOW *ct)
{
	Setting = FALSE;
	PushRadioButton(db, ct->command, Setting);
	Setting = TRUE;
}
*/

void cPushRadioButton(DBOX *db, enum commands cmd, BOOL setting)
{
    CTLWINDOW *ctt = db->ctl;
    CTLWINDOW *ct = FindCommand(db, cmd, RADIOBUTTON);
    int i;

	if (ct == NULL)
		return;

    /* --- clear all the radio buttons
                in this group on the dialog box --- */

    /* -------- build a table of all radio buttons at the
            same x vector ---------- */
    for (i = 0; i < MAXRADIOS; i++)
        rct[i] = NULL;
    while (ctt->Class)    {
        if (ctt->Class == RADIOBUTTON)
            if (ct->dwnd.x == ctt->dwnd.x)
                rct[ctt->dwnd.y] = ctt;
        ctt++;
    }

    /* ----- find the start of the radiobutton group ---- */
    i = ct->dwnd.y;
    while (i >= 0 && rct[i] != NULL)
        --i;
    /* ---- ignore everthing before the group ------ */
    while (i >= 0)
        rct[i--] = NULL;

    /* ----- find the end of the radiobutton group ---- */
    i = ct->dwnd.y;
    while (i < MAXRADIOS && rct[i] != NULL)
        i++;
    /* ---- ignore everthing past the group ------ */
    while (i < MAXRADIOS)
        rct[i++] = NULL;

    for (i = 0; i < MAXRADIOS; i++)    {
        if (rct[i] != NULL)    {
            int wason = rct[i]->setting;
            rct[i]->setting = OFF;
			if (setting)
	            rct[i]->isetting = OFF;
            if (wason)
                SendMessage(rct[i]->wnd, PAINT, 0, 0);
        }
    }
	/* ----- set the specified radio button on ----- */
    ct->setting = ON;
	if (setting)
	    ct->isetting = ON;
    SendMessage(ct->wnd, PAINT, 0, 0);
}

/*
BOOL RadioButtonSetting(DBOX *db, enum commands cmd)
{
    CTLWINDOW *ct = FindCommand(db, cmd, RADIOBUTTON);
    return ct ? (ct->wnd ? (ct->setting==ON) : (ct->isetting==ON)) : FALSE;
}
*/
