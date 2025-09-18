// direct.c
void cBuildList(WINDOW, char *, BOOL);

// message.c
extern BOOL AllocTesting;
extern jmp_buf AllocError;

// normal.c
void SaveBorder(RECT);
void RestoreBorder(RECT);

// applicat.c
extern BOOL AltDown;

// textbox.c
void DeleteTextMsg(WINDOW, int);
void InsertTextAt(WINDOW, char *, int);
void CloseWindowMsg(WINDOW);
void ComputeWindowTop(WINDOW);
void ComputeWindowLeft(WINDOW);
int ComputeVScrollBox(WINDOW);
int ComputeHScrollBox(WINDOW);
void MoveScrollBox(WINDOW, int);

// pictbox.c
typedef struct {
    enum VectTypes vt;
    RECT rc;
} VECT;

// menubar.c
BOOL cBuildMenu(WINDOW, char *, int, char **);
void cPaintMenu(WINDOW, int, int, int);
WINDOW GetDocFocus(void);

//listbox.c
void WriteSelection(WINDOW, int, int, RECT *);
void ChangeSelection(WINDOW, int, int);
void ListCopyText(char *, char *);

// editbox.c
void Forward(WINDOW);
void Backward(WINDOW);
void End(WINDOW);
void Home(WINDOW);
void Downward(WINDOW);
void Upward(WINDOW);
void StickEnd(WINDOW);
void NextWord(WINDOW);
void PrevWord(WINDOW);
void ModTextPointers(WINDOW, int, int);
void SetAnchor(WINDOW, int, int);
void ExtendBlock(WINDOW, int, int);
void DoKeyStroke(WINDOW, int, PARAM);
void DelKey(WINDOW);
void ShiftTabKey(WINDOW, PARAM);
void TabKey(WINDOW, PARAM);
void KeyTyped(WINDOW, int);

void StickEnd(WINDOW);
int CommandMsg(WINDOW, PARAM);
void TextBlockToN(char *, char *);
void ParagraphCmd(WINDOW);
void DoKeyStroke(WINDOW, int, PARAM);
int ScrollingKey(WINDOW, int, PARAM);
int GetTextMsg(WINDOW, PARAM, PARAM);
#define zCurrChar(wnd) (TextLine(wnd, (unsigned int)(wnd->CurrLine))+(unsigned int)(wnd->CurrCol))
#define TextLine(wnd, sel) \
      (wnd->text + *((wnd->TextPointers) + sel))
#define CurrPos(wnd) (*((wnd->TextPointers) + (unsigned int)(wnd->CurrLine))+(unsigned int)(wnd->CurrCol))

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
