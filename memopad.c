/* --------------- memopad.c ----------- */

#include "dflat.h"

char DFlatApplication[] = "memopad";

static char Untitled[] = "Untitled";
static int wndpos;

void LoadFile(WINDOW);
static void DeleteFile(WINDOW);
char *NameComponent(char *);
static void FixTabMenu(void);
void Calendar(WINDOW);
void BarChart(WINDOW);
void ShowPosition(WINDOW wnd);

#define CHARSLINE 80
#define LINESPAGE 66

/* ------- window processing module for the
                    memopad application window ----- */
int cMemoPadProc(WINDOW wnd,MESSAGE msg,PARAM p1,PARAM p2)
{
	int rtn;
    switch (msg)    {
		case CREATE_WINDOW:
		    rtn = DefaultWndProc(wnd, msg, p1, p2);
			if (cfg.InsertMode)
				SetCommandToggle(&MainMenu, ID_INSERT);
			if (cfg.WordWrap)
				SetCommandToggle(&MainMenu, ID_WRAP);
			FixTabMenu();
			return rtn;
        case COMMAND:
            switch ((int)p1)    {
//                case ID_NEW:
//                    NewFile(wnd);
//                    return TRUE;
//                case ID_OPEN:
//                    SelectFile(wnd);
//                    return TRUE;
//                case ID_SAVE:
//                    SaveFile(inFocus, FALSE);
//                    return TRUE;
//                case ID_SAVEAS:
//                    SaveFile(inFocus, TRUE);
//                    return TRUE;
                case ID_DELETEFILE:
                    DeleteFile(inFocus);
                    return TRUE;
				case ID_EXIT:	
					if (!YesNoBox("Exit Memopad?"))
						return FALSE;
					break;
				case ID_WRAP:
			        cfg.WordWrap = GetCommandToggle(&MainMenu, ID_WRAP);
    	            return TRUE;
				case ID_INSERT:
			        cfg.InsertMode = GetCommandToggle(&MainMenu, ID_INSERT);
    	            return TRUE;
				case ID_TAB2:
					cfg.Tabs = 2;
					FixTabMenu();
                    return TRUE;
				case ID_TAB4:
					cfg.Tabs = 4;
					FixTabMenu();
                    return TRUE;
				case ID_TAB6:
					cfg.Tabs = 6;					
					FixTabMenu();
                    return TRUE;
				case ID_TAB8:
					cfg.Tabs = 8;
					FixTabMenu();
                    return TRUE;
				case ID_CALENDAR:
					Calendar(wnd);
					return TRUE;
#ifdef INCLUDE_PICTUREBOX
				case ID_BARCHART:
					BarChart(wnd);
					return TRUE;
#endif
                case ID_ABOUT:
                    MessageBox(
                         "About D-Flat and the MemoPad",
                        "   ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿\n"
                        "   ³    ÜÜÜ   ÜÜÜ     Ü    ³\n"
                        "   ³    Û  Û  Û  Û    Û    ³\n"
                        "   ³    Û  Û  Û  Û    Û    ³\n"
                        "   ³    Û  Û  Û  Û Û  Û    ³\n"
                        "   ³    ßßß   ßßß   ßß     ³\n"
                        "   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ\n"
                        "D-Flat implements the SAA/CUA\n"
                        "interface in a public domain\n"
                        "C language library originally\n"
                        "published in Dr. Dobb's Journal\n"
                        "    ------------------------ \n"
                        "MemoPad is a multiple document\n"
                        "editor that demonstrates D-Flat");
                    return TRUE;
                default:
                    break;
            }
            break;
        default:
            break;
    }
    return DefaultWndProc(wnd, msg, p1, p2);
}

/* --- Load the notepad file into the editor text buffer --- */
void LoadFile(WINDOW wnd)
{
    char *Buf = NULL;
	int recptr = 0;
    FILE *fp;

    if ((fp = fopen(wnd->extension, "rt")) != NULL)    {
		while (!feof(fp))	{
//			handshake();
			Buf = DFrealloc(Buf, recptr+150);       //FIXME rewrite for ELKS
			memset(Buf+recptr, 0, 150);
        	fgets(Buf+recptr, 150, fp);
			recptr += strlen(Buf+recptr);
		}
        fclose(fp);
		if (Buf != NULL)	{
	        SendMessage(wnd, SETTEXT, (PARAM) Buf, 0);
		    free(Buf);
		}
    }
}

/* -------- delete a file ------------ */
static void DeleteFile(WINDOW wnd)
{
    if (wnd->extension != NULL)    {
        if (strcmp(wnd->extension, Untitled))    {
            char *fn = NameComponent(wnd->extension);
            if (fn != NULL)    {
                char msg[30];
                sprintf(msg, "Delete %s?", fn);
                if (YesNoBox(msg))    {
                    unlink(wnd->extension);
                    SendMessage(wnd, CLOSE_WINDOW, 0, 0);
                }
            }
        }
    }
}
/* ------ display the row and column in the statusbar ------ */
void ShowPosition(WINDOW wnd)
{
    char status[30];
    sprintf(status, "Line:%4d  Column: %2d",
        wnd->CurrLine, wnd->CurrCol);
    SendMessage(GetParent(wnd), ADDSTATUS, (PARAM) status, 0);
}

/* -- point to the name component of a file specification -- */
char *NameComponent(char *FileName)
{
    char *Fname;
    if ((Fname = strrchr(FileName, '/')) == NULL)
        Fname = FileName-1;
    return Fname + 1;
}

static void FixTabMenu(void)
{
	char *cp = GetCommandText(&MainMenu, ID_TABS);
	if (cp != NULL)	{
		cp = strchr(cp, '(');
		if (cp != NULL)	{
#if MSDOS | ELKS   /* can't overwrite .rodata */
			*(cp+1) = cfg.Tabs + '0';
#endif
			if (inFocus && (GetClass(inFocus) == POPDOWNMENU))
				SendMessage(inFocus, PAINT, 0, 0);
		}
	}
}

void PrepFileMenu(void *w, struct Menu *mnu)
{
	WINDOW wnd = w;
	DeactivateCommand(&MainMenu, ID_SAVE);
	DeactivateCommand(&MainMenu, ID_SAVEAS);
	DeactivateCommand(&MainMenu, ID_DELETEFILE);
	if (wnd != NULL && GetClass(wnd) == EDITBOX) {
		if (isMultiLine(wnd))	{
			ActivateCommand(&MainMenu, ID_SAVE);
			ActivateCommand(&MainMenu, ID_SAVEAS);
			ActivateCommand(&MainMenu, ID_DELETEFILE);
		}
	}
}

void PrepSearchMenu(void *w, struct Menu *mnu)
{
	WINDOW wnd = w;
	DeactivateCommand(&MainMenu, ID_SEARCH);
	DeactivateCommand(&MainMenu, ID_REPLACE);
	DeactivateCommand(&MainMenu, ID_SEARCHNEXT);
	if (wnd != NULL && GetClass(wnd) == EDITBOX) {
		if (isMultiLine(wnd))	{
			ActivateCommand(&MainMenu, ID_SEARCH);
			ActivateCommand(&MainMenu, ID_REPLACE);
			ActivateCommand(&MainMenu, ID_SEARCHNEXT);
		}
	}
}

void PrepEditMenu(void *w, struct Menu *mnu)
{
	WINDOW wnd = w;
	DeactivateCommand(&MainMenu, ID_CUT);
	DeactivateCommand(&MainMenu, ID_COPY);
	DeactivateCommand(&MainMenu, ID_CLEAR);
	DeactivateCommand(&MainMenu, ID_DELETETEXT);
	DeactivateCommand(&MainMenu, ID_PARAGRAPH);
	DeactivateCommand(&MainMenu, ID_PASTE);
	DeactivateCommand(&MainMenu, ID_UNDO);
	if (wnd != NULL && GetClass(wnd) == EDITBOX) {
		if (isMultiLine(wnd))	{
			if (TextBlockMarked(wnd))	{
				ActivateCommand(&MainMenu, ID_CUT);
				ActivateCommand(&MainMenu, ID_COPY);
				ActivateCommand(&MainMenu, ID_CLEAR);
				ActivateCommand(&MainMenu, ID_DELETETEXT);
			}
			ActivateCommand(&MainMenu, ID_PARAGRAPH);
			if (!TestAttribute(wnd, READONLY) &&
						Clipboard != NULL)
				ActivateCommand(&MainMenu, ID_PASTE);
			if (wnd->DeletedText != NULL)
				ActivateCommand(&MainMenu, ID_UNDO);
		}
	}
}
