// direct.c
void cBuildList(WINDOW, char *, BOOL);

// message.c
extern BOOL AllocTesting;
extern jmp_buf AllocError;

// applicat.c
extern BOOL AltDown;

// textbox.c
void ComputeWindowTop(WINDOW);
void ComputeWindowLeft(WINDOW);
int ComputeVScrollBox(WINDOW);
int ComputeHScrollBox(WINDOW);
void MoveScrollBox(WINDOW, int);
void cWriteTextLine(WINDOW, RECT, int, BOOL);

// editbox.c
int CommandMsg(WINDOW, PARAM);
void TextBlockToN(char *, char *);
void cParagraphCmd(WINDOW);
int GetTextMsg(WINDOW, PARAM, PARAM);
#define zCurrChar(wnd) (TextLine(wnd, (unsigned int)(wnd->CurrLine))+(unsigned int)(wnd->CurrCol))
//#define TextLine(wnd, sel) \
//      (wnd->text + *((wnd->TextPointers) + sel))
//#define CurrPos(wnd) (*((wnd->TextPointers) + (unsigned int)(wnd->CurrLine))+(unsigned int)(wnd->CurrCol))

// editor.c
int cSetTextMsg(WINDOW, char *);
void AdjustTab(WINDOW);

// helpbox.c
struct helps *FindHelp(char *Help);
void BuildHelpBox(WINDOW wnd);
extern struct helps *FirstHelp;
extern struct helps *ThisHelp;
extern int HelpCount;
extern char HelpFileName[9];

int HelpTextPaintMsg(WINDOW wnd, PARAM p1, PARAM p2);
int HelpTextLeftButtonMsg(WINDOW wnd, PARAM p1, PARAM p2);
void cReadHelp(WINDOW wnd, WINDOW cwnd);

extern FILE *helpfp;
extern char hline [160];
extern BOOL Helping;

struct keywords { // private
        struct helps *hkey;
    int lineno;
    int off1, off2, off3;
    char isDefinition;
};

extern struct keywords *thisword; // private
extern int keywordcount; // private

#define MAXHELPSTACK 100
extern int HelpStack[MAXHELPSTACK];
extern int stacked;

FILE *OpenHelpFile(const char *fn, const char *md);
void ReadHelp(WINDOW);
BOOL cHelpBoxKeyboardMsg(WINDOW, WINDOW, PARAM);
void SelectHelp(WINDOW, struct helps *, BOOL);

// decomp.c
void SeekHelpLine(long, int);
void *GetHelpLine(char *);
