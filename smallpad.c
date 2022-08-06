/* --------------- smallpad.c ----------- */

#include "dflat.h"

char DFlatApplication[] = "SmallPad";

static char Untitled[] = "Untitled";
static int wndpos;

static int SmallPadProc(WINDOW, MESSAGE, PARAM, PARAM);
static void NewFile(WINDOW);
static void OpenPadWindow(WINDOW, char *);
static int OurEditorProc(WINDOW, MESSAGE, PARAM, PARAM);

void PrepFileMenu(void *w, struct Menu *mnu)
{
}

/* --------------------- the main menu --------------------- */
DEFMENU(MainMenu)
    /* --------------- the File popdown menu ----------------*/
    POPDOWN( "~File",  PrepFileMenu, "Read/write/print files. Go to DOS" )
        SELECTION( "~New",        ID_NEW,          0, 0 )
        SEPARATOR
        SELECTION( "E~xit",       ID_EXIT,     ALT_X, 0 )
    ENDPOPDOWN
ENDMENU

/* ------------- the System Menu --------------------- */
DEFMENU(SystemMenu)
    POPDOWN("System Menu", NULL, NULL)
        SELECTION("~Move",     ID_SYSMOVE,     0,         0 )
        SELECTION("~Size",     ID_SYSSIZE,     0,         0 )
        SEPARATOR
        SELECTION("~Close",    ID_SYSCLOSE,    CTRL_F4,   0 )
    ENDPOPDOWN
ENDMENU

int main(int argc, char *argv[])
{
    WINDOW wnd;
    if (!init_messages())
        return 1;
    Argv = argv;
    if (!LoadConfig())
        cfg.ScreenLines = SCREENHEIGHT;
    wnd = CreateWindow(APPLICATION,
                        "D-Flat SmallPad",
                        0, 0, -1, -1,
                        &MainMenu,
                        NULL,
                        SmallPadProc,
                        MOVEABLE  |
                        SIZEABLE  |
                        HASBORDER |
                        MINMAXBOX
                   /* | HASSTATUSBAR */
                        );

    SendMessage(wnd, SETFOCUS, TRUE, 0);
    while (argc > 1)    {
        OpenPadWindow(wnd, argv[1]);
        --argc;
        argv++;
    }
    while (dispatch_message())
        ;
    return 0;
}

/* ------- window processing module for the
                    memopad application window ----- */
static int SmallPadProc(WINDOW wnd,MESSAGE msg,PARAM p1,PARAM p2)
{
    int rtn;
    switch (msg)    {
        case COMMAND:
            switch ((int)p1)    {
                case ID_NEW:
                    NewFile(wnd);
                    return TRUE;
                case ID_EXIT:
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
/* --- The New command. Open an empty editor window --- */
static void NewFile(WINDOW wnd)
{
    OpenPadWindow(wnd, Untitled);
}

/* --- open a document window and load a file --- */
static void OpenPadWindow(WINDOW wnd, char *FileName)
{
    static WINDOW wnd1;
    wndpos += 2;
    if (wndpos == 20)
        wndpos = 2;
    wnd1 = CreateWindow(EDITOR,
                FileName,
                (wndpos-1)*2, wndpos, 10, 40,
                NULL, wnd, OurEditorProc,
                SHADOW     |
                MINMAXBOX  |
                CONTROLBOX |
                VSCROLLBAR |
                HSCROLLBAR |
                MOVEABLE   |
                HASBORDER  |
                SIZEABLE   |
                MULTILINE
    );
    SendMessage(wnd1, SETFOCUS, TRUE, 0);
}

/* ------ display the row and column in the statusbar ------ */
static void ShowPosition(WINDOW wnd)
{
    char status[30];
    sprintf(status, "Line:%4d  Column: %2d",
        wnd->CurrLine, wnd->CurrCol);
    SendMessage(GetParent(wnd), ADDSTATUS, (PARAM) status, 0);
}
/* ----- window processing module for the editboxes ----- */
static int OurEditorProc(WINDOW wnd,MESSAGE msg,PARAM p1,PARAM p2)
{
    int rtn;
    switch (msg)    {
        case SETFOCUS:
            if ((int)p1)    {
                wnd->InsertMode = 1;
                wnd->WordWrapMode = 1;
            }
            rtn = DefaultWndProc(wnd, msg, p1, p2);
            if ((int)p1 == FALSE)
                SendMessage(GetParent(wnd), ADDSTATUS, 0, 0);
            else 
                ShowPosition(wnd);
            return rtn;
        case KEYBOARD_CURSOR:
            rtn = DefaultWndProc(wnd, msg, p1, p2);
            ShowPosition(wnd);
            return rtn;
        case COMMAND:
            switch ((int) p1)	{
                default:
                    break;
            }
            break;
        case CLOSE_WINDOW:
            wndpos = 0;
            if (wnd->extension != NULL)    {
                free(wnd->extension);
                wnd->extension = NULL;
            }
            break;
        default:
            break;
    }
    return DefaultWndProc(wnd, msg, p1, p2);
}
