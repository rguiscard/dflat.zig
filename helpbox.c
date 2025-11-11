/* ------------ helpbox.c ----------- */

#include "dflat.h"
#include "htree.h"

/* ---------- dfalloc.c ---------- */

BOOL AllocTesting = FALSE;
jmp_buf AllocError;

static void AllocationError(void)
{
//	WINDOW wnd;
	static BOOL OnceIn = FALSE;
	extern jmp_buf AllocError;
	extern BOOL AllocTesting;
	static char *ErrMsg[] = {
		"旼컴컴컴컴컴컴컴커",
		"� Out of Memory! �",
		"읕컴컴컴컴컴컴컴켸"
	};
	int x, y;
	char savbuf[108];
	RECT rc = {30,11,47,13};

	if (!OnceIn)	{
	    OnceIn = TRUE;
            // FIXME: uncomment after porting.
            // SendMessage(ApplicationWindow, CLOSE_WINDOW, 0, 0);
	    /* ------ close all windows ------ */
            // getvideo(rc, savbuf);
            // for (x = 0; x < 18; x++)	{
            //     for (y = 0; y < 3; y++)		{
            //         int c = (255 & (*(*(ErrMsg+y)+x))) | 0x7000;
            //         PutVideoChar(x+rc.lf, y+rc.tp, c);
            //     }
            // }
            // getkey();
            // storevideo(rc, savbuf);
            if (AllocTesting)
	        longjmp(AllocError, 1);
	}
}

static void *DFcalloc(size_t nitems, size_t size)
{
	void *rtn = calloc(nitems, size);
	if (size && rtn == NULL)
		AllocationError();
	return rtn;
}

//#define MAXHEIGHT (SCREENHEIGHT-10)
#define MAXHEIGHT (24-10)
#define MAXHELPKEYWORDS 50  /* --- maximum keywords in a window --- */
#define MAXHELPSTACK 100

struct helps *FirstHelp;
int HelpCount;
char HelpFileName[9];

FILE *helpfp;
BOOL Helping;

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

