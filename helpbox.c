/* ------------ helpbox.c ----------- */

#include "dflat.h"
#include "htree.h"

extern DBOX HelpBox;

/* -------- strings of D-Flat classes for calling default
      help text collections -------- */
char *ClassNames[] = {
    #undef ClassDef
    #define ClassDef(c,b,a) #c,
    #include "classes.h"
    NULL
};

#define MAXHEIGHT (SCREENHEIGHT-10)
#define MAXHELPKEYWORDS 50  /* --- maximum keywords in a window --- */
#define MAXHELPSTACK 100

struct helps *FirstHelp;
struct helps *ThisHelp;
int HelpCount;
char HelpFileName[9];

int HelpStack[MAXHELPSTACK];
int stacked;

//void zReFocus(WINDOW wnd);
int HelpTextProc(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2);
int HelpTextPaintMsg(WINDOW wnd, PARAM p1, PARAM p2);
int HelpTextLeftButtonMsg(WINDOW wnd, PARAM p1, PARAM p2);
void cReadHelp(WINDOW wnd, WINDOW cwnd);

/* --- keywords in the current help text -------- */
static struct keywords {
	struct helps *hkey;
    int lineno;
    int off1, off2, off3;
    char isDefinition;
} KeyWords[MAXHELPKEYWORDS];
static struct keywords *thisword;
static int keywordcount;

FILE *helpfp;
char hline [160];
BOOL Helping;

void SelectHelp(WINDOW, struct helps *, BOOL);
void ReadHelp(WINDOW);
struct helps *FindHelp(char *);
static void DisplayDefinition(WINDOW, char *);
void BestFit(WINDOW, DIALOGWINDOW *);

int HelpTextProc(WINDOW, MESSAGE, PARAM, PARAM);

/* ------------- KEYBOARD message ------------ */
BOOL cHelpBoxKeyboardMsg(WINDOW wnd, WINDOW cwnd, PARAM p1)
{
//    WINDOW cwnd;
//
//    cwnd = ControlWindow(wnd->extension, ID_HELPTEXT);
//    if (cwnd == NULL || inFocus != cwnd)
//        return FALSE;

    // cwnd is not null, checked by zig side
    switch ((int)p1)    {
        case '\r':
			if (keywordcount)
	            if (thisword != NULL)    {
					char *hp = thisword->hkey->hname;
        	        if (thisword->isDefinition)
            	        DisplayDefinition(GetParent(wnd), hp);
                	else
                    	SelectHelp(wnd, thisword->hkey, TRUE);
	            }
            return TRUE;
        case '\t':
			if (!keywordcount)
				return TRUE;
            if (thisword == NULL ||
					++thisword == KeyWords+keywordcount)
	            thisword = KeyWords;
            break;
        case SHIFT_HT:
			if (!keywordcount)
				return TRUE;
			if (thisword == NULL || thisword == KeyWords)
				thisword = KeyWords+keywordcount;
			--thisword;
			break;;
        default:
			return FALSE;
    }
    if (thisword->lineno < cwnd->wtop ||
            thisword->lineno >=
                cwnd->wtop + ClientHeight(cwnd))  {
        int distance = ClientHeight(cwnd)/2;
        do    {
            cwnd->wtop = thisword->lineno-distance;
            distance /= 2;
        }
        while (cwnd->wtop < 0);
    }
    SendMessage(cwnd, PAINT, 0, 0);
    return TRUE;
}

/* ---- PAINT message for the helpbox text editbox ---- */
int HelpTextPaintMsg(WINDOW wnd, PARAM p1, PARAM p2)
{
    int rtn;
    if (thisword != NULL)    {
        WINDOW pwnd = GetParent(wnd);
        char *cp;
        cp = TextLine(wnd, thisword->lineno);
        cp += thisword->off1;
        *(cp+1) =
            (pwnd->WindowColors[SELECT_COLOR][FG] & 255) | 0x80;
        *(cp+2) =
            (pwnd->WindowColors[SELECT_COLOR][BG] & 255) | 0x80;
        rtn = DefaultWndProc(wnd, PAINT, p1, p2);
        *(cp+1) =
            (pwnd->WindowColors[HILITE_COLOR][FG] & 255) | 0x80;
        *(cp+2) =
            (pwnd->WindowColors[HILITE_COLOR][BG] & 255) | 0x80;
        return rtn;
    }
    return DefaultWndProc(wnd, PAINT, p1, p2);
}

/* ---- LEFT_BUTTON message for the helpbox text editbox ---- */
int HelpTextLeftButtonMsg(WINDOW wnd, PARAM p1, PARAM p2)
{
    int rtn, mx, my, i;

    rtn = DefaultWndProc(wnd, LEFT_BUTTON, p1, p2);
    mx = (int)p1 - GetClientLeft(wnd);
    my = (int)p2 - GetClientTop(wnd);
    my += wnd->wtop;
    thisword = KeyWords;
    for (i = 0; i < keywordcount; i++)    {
        if (my == thisword->lineno)    {
            if (mx >= thisword->off2 &&
                        mx < thisword->off3)    {
                SendMessage(wnd, PAINT, 0, 0);
                if (thisword->isDefinition)    {
                    WINDOW pwnd = GetParent(wnd);
                    if (pwnd != NULL)
                        DisplayDefinition(GetParent(pwnd),
                            thisword->hkey->hname);
                }
                break;
            }
        }
        thisword++;
    }
	if (i == keywordcount)
		thisword = NULL;
    return rtn;
}

/* -------- read the help text into the editbox ------- */
void cReadHelp(WINDOW wnd, WINDOW cwnd)
{
    int linectr = 0;
    thisword = KeyWords;
	keywordcount = 0;

    /* ----- read the help text ------- */
    while (TRUE)    {
        unsigned char *cp = hline, *cp1;
        int colorct = 0;
        if (GetHelpLine(hline) == NULL)
            break;
        if (*hline == '<')
            break;
        hline[strlen(hline)-1] = '\0';
        /* --- add help text to the help window --- */
        while (cp != NULL)    {
            if ((cp = strchr(cp, '[')) != NULL)    {
                /* ----- hit a new key word ----- */
                if (*(cp+1) != '.' && *(cp+1) != '*')    {
                    cp++;
                    continue;
                }
                thisword->lineno = cwnd->wlines;
                thisword->off1 = (int) ((char *)cp - hline);
                thisword->off2 = thisword->off1 - colorct * 4;
                thisword->isDefinition = *(cp+1) == '*';
                colorct++;
                *cp++ = CHANGECOLOR;
                *cp++ =
            (wnd->WindowColors [HILITE_COLOR] [FG] & 255) | 0x80;
                *cp++ =
            (wnd->WindowColors [HILITE_COLOR] [BG] & 255) | 0x80;
                cp1 = cp;
                if ((cp = strchr(cp, ']')) != NULL)    {
                    if (thisword != NULL)
                        thisword->off3 =
                            thisword->off2 + (int) (cp - cp1);
                    *cp++ = RESETCOLOR;
                }
                if ((cp = strchr(cp, '<')) != NULL)    {
                    char *cp1 = strchr(cp, '>');
                    if (cp1 != NULL)    {
						char hname[80];
                        int len = (int) (cp1 - (char *)cp);
						memset(hname, 0, 80);
                        strncpy(hname, cp+1, len-1);
						thisword->hkey = FindHelp(hname);
                        memmove(cp, cp1+1, strlen(cp1));
                    }
                }
				thisword++;
				keywordcount++;
            }
        }
        PutItemText(wnd, ID_HELPTEXT, hline);
        /* -- display help text as soon as window is full -- */
        if (++linectr == ClientHeight(cwnd))	{
			struct keywords *holdthis = thisword;
		    thisword = NULL;
            SendMessage(cwnd, PAINT, 0, 0);
		    thisword = holdthis;
		}
        if (linectr > ClientHeight(cwnd) &&
                !TestAttribute(cwnd, VSCROLLBAR))    {
            AddAttribute(cwnd, VSCROLLBAR);
            SendMessage(cwnd, BORDER, 0, 0);
        }
    }
    thisword = NULL;
}

/* ---- compute the displayed length of a help text line --- */
static int HelpLength(char *s)
{
    int len = strlen(s);
    char *cp = strchr(s, '[');
    while (cp != NULL)    {
        len -= 4;
        cp = strchr(cp+1, '[');
    }
    cp = strchr(s, '<');
    while (cp != NULL)    {
        char *cp1 = strchr(cp, '>');
        if (cp1 != NULL)
            len -= (int) (cp1-cp)+1;
        cp = strchr(cp1, '<');
    }
    return len;
}

/* ----------- load the help text file ------------ */
void LoadHelpFile(char *fname)
{
	long where;
	int i;
    if (Helping)
        return;
    UnLoadHelpFile();
    if ((helpfp = OpenHelpFile(fname, "rb")) == NULL)
        return;
	strcpy(HelpFileName, fname);
	fseek(helpfp, - (long) sizeof(long), SEEK_END);
	fread(&where, sizeof(long), 1, helpfp);
	fseek(helpfp, where, SEEK_SET);
	fread(&HelpCount, sizeof(int), 1, helpfp);
	FirstHelp = DFcalloc(sizeof(struct helps) * HelpCount, 1);
	for (i = 0; i < HelpCount; i++)	{
		int len;
		fread(&len, sizeof(int), 1, helpfp);
		if (len)	{
			(FirstHelp+i)->hname = DFcalloc(len+1, 1);
			fread((FirstHelp+i)->hname, len+1, 1, helpfp);
		}
		fread(&len, sizeof(int), 1, helpfp);
		if (len)	{
			(FirstHelp+i)->comment = DFcalloc(len+1, 1);
			fread((FirstHelp+i)->comment, len+1, 1, helpfp);
		}
		fread(&(FirstHelp+i)->hptr, sizeof(int)*5+sizeof(long), 1, helpfp);
	}
    fclose(helpfp);
	helpfp = NULL;
}

/* ------ free the memory used by the help file table ------ */
void UnLoadHelpFile(void)
{
	int i;
	for (i = 0; i < HelpCount; i++)	{
        free((FirstHelp+i)->comment);
        free((FirstHelp+i)->hname);
	}
	free(FirstHelp);
	FirstHelp = NULL;
    free(HelpTree);
	HelpTree = NULL;
}

/*
void BuildHelpBox(WINDOW wnd)
{
    int offset, i;

    // -- seek to the first line of the help text -- 
    SeekHelpLine(ThisHelp->hptr, ThisHelp->bit);
    // ----- read the title ----- 
    GetHelpLine(hline);
    hline[strlen(hline)-1] = '\0';
	free(HelpBox.dwnd.title);
    HelpBox.dwnd.title = DFmalloc(strlen(hline)+1);
    strcpy(HelpBox.dwnd.title, hline);
    // ----- set the height and width ----- 
    HelpBox.dwnd.h = min(ThisHelp->hheight, MAXHEIGHT)+7;
    HelpBox.dwnd.w = max(45, ThisHelp->hwidth+6);
    // ------ position the help window ----- 
	if (wnd != NULL)
	    BestFit(wnd, &HelpBox.dwnd);
    // ------- position the command buttons ------ 
    HelpBox.ctl[0].dwnd.w = max(40, ThisHelp->hwidth+2);
    HelpBox.ctl[0].dwnd.h =
                min(ThisHelp->hheight, MAXHEIGHT)+2;
    offset = (HelpBox.dwnd.w-40) / 2;
	for (i = 1; i < 5; i++)    {
   		HelpBox.ctl[i].dwnd.y =
           		min(ThisHelp->hheight, MAXHEIGHT)+3;
   		HelpBox.ctl[i].dwnd.x = (i-1) * 10 + offset;
	}
    // ---- disable ineffective buttons ---- 
    if (ThisHelp->nexthlp == -1)
        DisableButton(&HelpBox, ID_NEXT);
	else
        EnableButton(&HelpBox, ID_NEXT);
    if (ThisHelp->prevhlp == -1)
        DisableButton(&HelpBox, ID_PREV);
	else 
        EnableButton(&HelpBox, ID_PREV);
}
*/

/* ----- select a new help window from its name ----- */
/*
void SelectHelp(WINDOW wnd, struct helps *newhelp, BOOL recall)
{
	if (newhelp != NULL)	{
		int i, x, y;
		SendMessage(wnd, HIDE_WINDOW, 0, 0);
		if (recall && stacked < MAXHELPSTACK)
			HelpStack[stacked++] = ThisHelp-FirstHelp;
		ThisHelp = newhelp;
		SendMessage(GetParent(wnd), DISPLAY_HELP, (PARAM) ThisHelp->hname, 0);
		if (stacked)
		    EnableButton(&HelpBox, ID_BACK);
		else 
		    DisableButton(&HelpBox, ID_BACK);
		BuildHelpBox(NULL);
		AddTitle(wnd, HelpBox.dwnd.title);
		// --- reposition and resize the help window --- 
		HelpBox.dwnd.x = (SCREENWIDTH-HelpBox.dwnd.w)/2;
		HelpBox.dwnd.y = (SCREENHEIGHT-HelpBox.dwnd.h)/2;
		SendMessage(wnd, MOVE, HelpBox.dwnd.x, HelpBox.dwnd.y);
		SendMessage(wnd, SIZE,
						HelpBox.dwnd.x + HelpBox.dwnd.w - 1,
						HelpBox.dwnd.y + HelpBox.dwnd.h - 1);
		// --- reposition the controls --- 
	    for (i = 0; i < 5; i++)    {
			WINDOW cwnd = HelpBox.ctl[i].wnd;
			x = HelpBox.ctl[i].dwnd.x+GetClientLeft(wnd);
			y = HelpBox.ctl[i].dwnd.y+GetClientTop(wnd);
			SendMessage(cwnd, MOVE, x, y);
			if (i == 0)	{
				x += HelpBox.ctl[i].dwnd.w - 1;
				y += HelpBox.ctl[i].dwnd.h - 1;
				SendMessage(cwnd, SIZE, x, y);
			}
		}
		// --- read the help text into the help window --- 
		ReadHelp(wnd);
		ReFocus(wnd);
		SendMessage(wnd, SHOW_WINDOW, 0, 0);
	}
}
*/
/* ---- strip tildes from the help name ---- */
static void StripTildes(char *fh, char *hp)
{
	while (*hp)	{
		if (*hp != '~')
			*fh++ = *hp;
		hp++;
	}
	*fh = '\0';
}
/* --- return the comment associated with a help window --- */
char *HelpComment(char *Help)
{
	char FixedHelp[30];
	StripTildes(FixedHelp, Help);
    if ((ThisHelp = FindHelp(FixedHelp)) != NULL)
		return ThisHelp->comment;
	return NULL;
}

/* ------- display a definition window --------- */
static void DisplayDefinition(WINDOW wnd, char *def)
{
    WINDOW dwnd;
    WINDOW hwnd = wnd;
    int y;
	struct helps *HoldThisHelp;

	HoldThisHelp = ThisHelp;
    if (GetClass(wnd) == POPDOWNMENU)
        hwnd = GetParent(wnd);
    y = GetClass(hwnd) == MENUBAR ? 2 : 1;
    if ((ThisHelp = FindHelp(def)) != NULL)    {
        dwnd = CreateWindow(
                    TEXTBOX,
                    NULL,
                    GetClientLeft(hwnd),
                    GetClientTop(hwnd)+y,
                    min(ThisHelp->hheight, MAXHEIGHT)+3,
                    ThisHelp->hwidth+2,
                    NULL,
                    wnd,
                    HASBORDER | NOCLIP | SAVESELF);
        if (dwnd != NULL)    {
            clearBIOSbuffer();
            /* ----- read the help text ------- */
            SeekHelpLine(ThisHelp->hptr, ThisHelp->bit);
            while (TRUE)    {
                clearBIOSbuffer();
                if (GetHelpLine(hline) == NULL)
                    break;
                if (*hline == '<')
                    break;
                hline[strlen(hline)-1] = '\0';
                SendMessage(dwnd,ADDTEXT,(PARAM)hline,0);
            }
            SendMessage(dwnd, SHOW_WINDOW, 0, 0);
            SendMessage(NULL, WAITKEYBOARD, 0, 0);
            SendMessage(NULL, WAITMOUSE, 0, 0);
            SendMessage(dwnd, CLOSE_WINDOW, 0, 0);
        }
    }
	ThisHelp = HoldThisHelp;
}

/* ------ compare help names with wild cards ----- */
static BOOL wildcmp(char *s1, char *s2)
{
    while (*s1 || *s2)    {
        if (tolower(*s1) != tolower(*s2))
            if (*s1 != '?' && *s2 != '?')
                return TRUE;
        s1++, s2++;
    }
    return FALSE;
}

/* --- ThisHelp = the help window matching specified name --- */
struct helps *FindHelp(char *Help)
{
	int i;
	struct helps *thishelp = NULL;
	for (i = 0; i < HelpCount; i++)	{
        if (wildcmp(Help, (FirstHelp+i)->hname) == FALSE)	{
		    thishelp = FirstHelp+i;
            break;
		}
	}
	return thishelp;
}

static int OverLap(int a, int b)
{
    int ov = a - b;
    if (ov < 0)
        ov = 0;
    return ov;
}

/* ----- compute the best location for a help dialogbox ----- */
void BestFit(WINDOW wnd, DIALOGWINDOW *dwnd)
{
    int above, below, right, left;
    if (GetClass(wnd) == MENUBAR ||
                GetClass(wnd) == APPLICATION)    {
        dwnd->x = dwnd->y = -1;
        return;
    }
    /* --- compute above overlap ---- */
    above = OverLap(dwnd->h, GetTop(wnd));
    /* --- compute below overlap ---- */
    below = OverLap(GetBottom(wnd), SCREENHEIGHT-dwnd->h);
    /* --- compute right overlap ---- */
    right = OverLap(GetRight(wnd), SCREENWIDTH-dwnd->w);
    /* --- compute left  overlap ---- */
    left = OverLap(dwnd->w, GetLeft(wnd));

    if (above < below)
        dwnd->y = max(0, GetTop(wnd)-dwnd->h-2);
    else
        dwnd->y = min(SCREENHEIGHT-dwnd->h, GetBottom(wnd)+2);
    if (right < left)
        dwnd->x = min(GetRight(wnd)+2, SCREENWIDTH-dwnd->w);
    else
        dwnd->x = max(0, GetLeft(wnd)-dwnd->w-2);

    if (dwnd->x == GetRight(wnd)+2 ||
            dwnd->x == GetLeft(wnd)-dwnd->w-2)
        dwnd->y = -1;
    if (dwnd->y ==GetTop(wnd)-dwnd->h-2 ||
            dwnd->y == GetBottom(wnd)+2)
        dwnd->x = -1;
}
