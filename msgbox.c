/* ------------------ msgbox.c ------------------ */

#include "dflat.h"

//extern DBOX MsgBox;
//extern DBOX InputBoxDB;
//WINDOW CancelWnd;

//static int ReturnValue;
/* does nothing
void CloseCancelBox(void)
{
    if (CancelWnd != NULL)
        SendMessage(CancelWnd, CLOSE_WINDOW, 0, 0);
}
*/

/* Current not in use. Port later */
#if NOT_IN_USE 
static char *InputText;
static int TextLength;

int cInputBoxProc(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2)
{
    int rtn;
    switch (msg)    {
        case CREATE_WINDOW:
            rtn = DefaultWndProc(wnd, msg, p1, p2);
            SendMessage(ControlWindow(&InputBoxDB,ID_INPUTTEXT),
                        SETTEXTLENGTH, TextLength, 0);
            SendMessage(ControlWindow(&InputBoxDB,ID_INPUTTEXT),
                        ADDTEXT, (PARAM) InputText, 0);
            return rtn;
        case COMMAND:
            if ((int) p1 == ID_OK && (int) p2 == 0)
                GetItemText(wnd, ID_INPUTTEXT,
                            InputText, TextLength);
            break;
        default:
            break;
    }
    return DefaultWndProc(wnd, msg, p1, p2);
}

BOOL InputBox(WINDOW wnd,char *ttl,char *msg,char *text,int len,int wd)
{
	int ln = wd ? wd : len;
	ln = min(SCREENWIDTH-8, ln);
    InputText = text;
    TextLength = len;
    InputBoxDB.dwnd.title = ttl;
    InputBoxDB.dwnd.w = 4 + max(20, max(ln, max(strlen(ttl), strlen(msg))));
    InputBoxDB.ctl[1].dwnd.x = (InputBoxDB.dwnd.w-2-ln)/2;
    InputBoxDB.ctl[0].dwnd.w = strlen(msg);
    InputBoxDB.ctl[0].itext = msg;
    InputBoxDB.ctl[1].itext = NULL;
    InputBoxDB.ctl[1].dwnd.w = ln;
    InputBoxDB.ctl[2].dwnd.x = (InputBoxDB.dwnd.w - 20) / 2;
    InputBoxDB.ctl[3].dwnd.x = InputBoxDB.ctl[2].dwnd.x + 10;
    InputBoxDB.ctl[2].isetting = ON;
    InputBoxDB.ctl[3].isetting = ON;
    return DialogBox(wnd, &InputBoxDB, TRUE, InputBoxProc);
}
#endif

int MsgHeight(char *msg)
{
    int h = 1;
    while ((msg = strchr(msg, '\n')) != NULL)    {
        h++;
        msg++;
    }
    return min(h, SCREENHEIGHT-10);
}

int MsgWidth(char *msg)
{
    int w = 0;
    char *cp = msg;
    while ((cp = strchr(msg, '\n')) != NULL)    {
        w = max(w, (int) (cp-msg));
        msg = cp+1;
    }
    return min(max(strlen(msg),w), SCREENWIDTH-10);
}
