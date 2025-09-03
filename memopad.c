/* --------------- memopad.c ----------- */

#include "dflat.h"

char DFlatApplication[] = "memopad";

static char Untitled[] = "Untitled";

void LoadFile(WINDOW);
void DeleteFile(WINDOW);
char *NameComponent(char *);
void ShowPosition(WINDOW wnd);

#define CHARSLINE 80
#define LINESPAGE 66

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
void DeleteFile(WINDOW wnd)
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
//			if (!TestAttribute(wnd, READONLY) &&
//						Clipboard != NULL)
				ActivateCommand(&MainMenu, ID_PASTE);
			if (wnd->DeletedText != NULL)
				ActivateCommand(&MainMenu, ID_UNDO);
		}
	}
}
