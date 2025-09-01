/* -------------- checkbox.c ------------ */

#include "dflat.h"

BOOL CheckBoxSetting(DBOX *db, enum commands cmd)
{
    CTLWINDOW *ct = FindCommand(db, cmd, CHECKBOX);
    return ct ? (ct->wnd ? (ct->setting==ON) : (ct->isetting==ON)) : FALSE;
}
