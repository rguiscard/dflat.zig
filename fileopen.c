/* ----------- fileopen.c ------------- */

#include "dflat.h"

static BOOL DlgFileOpen(char *, char *, char *, DBOX *);
static int DlgFnOpen(WINDOW, MESSAGE, PARAM, PARAM);
static void InitDlgBox(WINDOW);
static void StripPath(char *);
static BOOL IncompleteFilename(char *);

static char FileSpec[15];
static char SrchSpec[15];
static char FileName[MAXPATH];

extern DBOX FileOpen;
extern DBOX SaveAs;

/*
 * Dialog Box to select a file to open
 */
BOOL OpenFileDialogBox(char *Fspec, char *Fname)
{
    return DlgFileOpen(Fspec, Fspec, Fname, &FileOpen);
}

/*
 * Dialog Box to select a file to save as
 */
BOOL SaveAsDialogBox(char *Fspec, char *Sspec, char *Fname)
{
    return DlgFileOpen(Fspec, Sspec ? Sspec : Fspec, Fname, &SaveAs);
}

/* --------- generic file open ---------- */
static BOOL DlgFileOpen(char *Fspec, char *Sspec, char *Fname, DBOX *db)
{
    BOOL rtn;

    strncpy(FileSpec, Fspec, sizeof(FileSpec)-1);
    strncpy(SrchSpec, Sspec, sizeof(FileSpec)-1);

    if ((rtn = DialogBox(NULL, db, TRUE, DlgFnOpen)) != FALSE)
        strcpy(Fname, FileName);

    return rtn;
}

/*
 *  Process dialog box messages
 */
static int DlgFnOpen(WINDOW wnd,MESSAGE msg,PARAM p1,PARAM p2)
{
    switch (msg)    {
        case CREATE_WINDOW:    {
            int rtn = DefaultWndProc(wnd, msg, p1, p2);
            DBOX *db = wnd->extension;
            WINDOW cwnd = ControlWindow(db, ID_FILENAME);
            SendMessage(cwnd, SETTEXTLENGTH, 64, 0);
            return rtn;
        }
        case INITIATE_DIALOG:
            InitDlgBox(wnd);
            break;
        case COMMAND:
            switch ((int) p1)    {
                case ID_OK:
                {
                    if ((int)p2 == 0)	{
                        GetItemText(wnd, ID_FILENAME, FileName, MAXPATH);
                        if (CheckAndChangeDir(FileName))
                            strcpy(FileName, "*");
                        if (IncompleteFilename(FileName)) {
                            /* --- no file name yet --- */
                            DBOX *db = wnd->extension;
                            WINDOW cwnd = ControlWindow(db, ID_FILENAME);
                            strncpy(FileSpec, FileName, sizeof(FileSpec)-1);
                            strncpy(SrchSpec, FileName, sizeof(FileSpec)-1);
                            InitDlgBox(wnd);
                            SendMessage(cwnd, SETFOCUS, TRUE, 0);
                            return TRUE;
                        }
                    }
                    break;
                }
                case ID_FILES:
                    switch ((int) p2)    {
                        case ENTERFOCUS:
                        case LB_SELECTION:
                            /* selected a different filename */
                            GetDlgListText(wnd, FileName, ID_FILES);
                            PutItemText(wnd, ID_FILENAME, FileName);
                            break;
                        case LB_CHOOSE:
                            /* chose a file name */
                            GetDlgListText(wnd, FileName, ID_FILES);
                            SendMessage(wnd, COMMAND, ID_OK, 0);
                            break;
                        default:
                            break;
                    }
                    return TRUE;
                case ID_DIRECTORY:
                    switch ((int) p2)    {
                        case ENTERFOCUS:
                            PutItemText(wnd, ID_FILENAME, FileSpec);
                            break;
                        case LB_CHOOSE:
                        {
                            /* chose dir */
                            char dd[MAXPATH];
                            GetDlgListText(wnd, dd, ID_DIRECTORY);
                            chdir(dd);
                            InitDlgBox(wnd);
                            SendMessage(wnd, COMMAND, ID_OK, 0);
                            break;
                        }
                        default:
                            break;
                    }
                    return TRUE;

                default:
                    break;
            }
        default:
            break;
    }
    return DefaultWndProc(wnd, msg, p1, p2);
}

BOOL BuildFileList(WINDOW, char *);
void BuildDirectoryList(WINDOW);
void BuildPathDisplay(WINDOW);

/*
 *  Initialize the dialog box
 */
static void InitDlgBox(WINDOW wnd)
{
    if (*FileSpec)
        PutItemText(wnd, ID_FILENAME, FileSpec);
    if (BuildFileList(wnd, SrchSpec))
        BuildDirectoryList(wnd);
    BuildPathDisplay(wnd);
}

/*
 * Strip the path information from a file spec
 */
static void StripPath(char *filespec)
{
    char *cp, *cp1;

    cp = filespec;
    while (TRUE)    {
        cp1 = strchr(cp, '/');
        if (cp1 == NULL)
            break;
        cp = cp1+1;
    }
    strcpy(filespec, cp);
}


static BOOL IncompleteFilename(char *s)
{
    int lc = strlen(s)-1;
    if (strchr(s, '?') || strchr(s, '*') || !*s)
        return TRUE;
    return FALSE;
}
