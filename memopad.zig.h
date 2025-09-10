// direct.c
void cBuildList(WINDOW, char *, BOOL);

// message.c
void c_dispatch_message(MESSAGE ev_event, int ev_mx, int ev_my);
BOOL cProcessMessage(WINDOW, MESSAGE, PARAM, PARAM);
extern BOOL AllocTesting;
extern jmp_buf AllocError;
extern BOOL NoChildCaptureMouse; // should be private
extern BOOL NoChildCaptureKeyboard; // should be private

// dialbox.c
//void FirstFocus(DBOX *);
//void NextFocus(DBOX *db);
//void PrevFocus(DBOX *db);
//BOOL dbShortcutKeys(DBOX *, int);
//int inFocusCommand(DBOX *);
//void FixColors(WINDOW);
//void SetScrollBars(WINDOW);
//void CtlCloseWindowMsg(WINDOW);

// normal.c
extern struct window dwnd;
//void GetVideoBuffer(WINDOW);
//void PutVideoBuffer(WINDOW);
void PaintOverLappers(WINDOW);
void PaintUnderLappers(WINDOW);
void dragborder(WINDOW, int, int);
void sizeborder(WINDOW, int, int);
void SaveBorder(RECT);
void RestoreBorder(RECT);
RECT PositionIcon(WINDOW);
extern int px;
extern int py;
extern int diff;

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
extern MENU *ActiveMenu;

//listbox.c
void WriteSelection(WINDOW, int, int, RECT *);
void ChangeSelection(WINDOW, int, int);
void ListCopyText(char *, char *);

// editbox.c
void StickEnd(WINDOW);
void ExtendBlock(WINDOW, int, int);
void SetAnchor(WINDOW, int, int);
int CommandMsg(WINDOW, PARAM);
void TextBlockToN(char *, char *);
void ParagraphCmd(WINDOW);
void DoKeyStroke(WINDOW, int, PARAM);
int ScrollingKey(WINDOW, int, PARAM);
int GetTextMsg(WINDOW, PARAM, PARAM);
#define zCurrChar(wnd) (TextLine(wnd, (unsigned int)(wnd->CurrLine))+(unsigned int)(wnd->CurrCol))

// popdown.c
void PaintMsg(WINDOW);
void PaintPopDownSelection(WINDOW, struct PopDown *, char*);

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
//void BestFit(WINDOW, DIALOGWINDOW *); // private

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
