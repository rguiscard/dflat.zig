// main.c
void LoadFile(WINDOW);
char *NameComponent(char *);
void ShowPosition(WINDOW);

// fileopen.c
//int DlgFnOpen(WINDOW, MESSAGE, PARAM, PARAM);
BOOL BuildFileList(WINDOW, char *);
void BuildDirectoryList(WINDOW);
void BuildPathDisplay(WINDOW);

// message.c
void c_dispatch_message(MESSAGE ev_event, int ev_mx, int ev_my);
BOOL ProcessMessage(WINDOW, MESSAGE, PARAM, PARAM, int);

// dialbox.c
void FirstFocus(DBOX *);
void NextFocus(DBOX *db);
void PrevFocus(DBOX *db);
BOOL dbShortcutKeys(DBOX *, int);
int inFocusCommand(DBOX *);
void FixColors(WINDOW);
void SetScrollBars(WINDOW);
void CtlCloseWindowMsg(WINDOW);

// normal.c
extern struct window dwnd;
void GetVideoBuffer(WINDOW);
void PutVideoBuffer(WINDOW);
void PaintOverLappers(WINDOW);
void PaintUnderLappers(WINDOW);
void dragborder(WINDOW, int, int);
void sizeborder(WINDOW, int, int);
void RestoreBorder(RECT);
RECT PositionIcon(WINDOW);
extern int px;
extern int py;
extern int diff;

// applicat.c
void CreateStatusBar(WINDOW);
void SelectColors(WINDOW);
void SetScreenHeight(int);
void SelectLines(WINDOW);
void SelectTexture(void);
void SelectBorder(WINDOW);
void SelectTitle(WINDOW);
void SelectStatusBar(WINDOW);
void CreateMenu(WINDOW);
void ShellDOS(WINDOW);
extern DBOX Display;
extern BOOL AltDown;
void cDisplay(WINDOW, PARAM, PARAM);

// textbox.c
BOOL AddTextMsg(WINDOW, char *);
void DeleteTextMsg(WINDOW, int);
void InsertTextMsg(WINDOW, char *, int);
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
void reset_menubar(WINDOW);
void cBuildMenuMsg(WINDOW, PARAM, char**);
void cCloseWindowMsg(WINDOW);
void cPaintMsg(WINDOW);
BOOL cBuildMenu(WINDOW, char *, int, char **);
extern MENU *ActiveMenu;

// all wndproc
int cNormalProc(WINDOW, MESSAGE, PARAM, PARAM);
int cApplicationProc(WINDOW, MESSAGE, PARAM, PARAM);
int cTextBoxProc(WINDOW, MESSAGE, PARAM, PARAM);
int cListBoxProc(WINDOW, MESSAGE, PARAM, PARAM);
int cEditBoxProc(WINDOW, MESSAGE, PARAM, PARAM);
int cMenuBarProc(WINDOW, MESSAGE, PARAM, PARAM);
int cPopDownProc(WINDOW, MESSAGE, PARAM, PARAM);
int cDialogProc(WINDOW, MESSAGE, PARAM, PARAM);
int cBoxProc(WINDOW, MESSAGE, PARAM, PARAM);
int cButtonProc(WINDOW, MESSAGE, PARAM, PARAM);
// int cComboProc(WINDOW, MESSAGE, PARAM, PARAM); // not in use. port later.
int cTextProc(WINDOW, MESSAGE, PARAM, PARAM);
int cRadioButtonProc(WINDOW, MESSAGE, PARAM, PARAM);
int cCheckBoxProc(WINDOW, MESSAGE, PARAM, PARAM);
int cSpinButtonProc(WINDOW, MESSAGE, PARAM, PARAM);
int cHelpBoxProc(WINDOW, MESSAGE, PARAM, PARAM);
int cStatusBarProc(WINDOW, MESSAGE, PARAM, PARAM);
int cEditorProc(WINDOW, MESSAGE, PARAM, PARAM);

int cHelpTextProc(WINDOW, MESSAGE, PARAM, PARAM);
int cMemoPadProc(WINDOW, MESSAGE, PARAM, PARAM);
int cOurEditorProc(WINDOW, MESSAGE, PARAM, PARAM);
int cSystemMenuProc(WINDOW, MESSAGE, PARAM, PARAM);
int cWatchIconProc(WINDOW, MESSAGE, PARAM, PARAM);

int cMessageBoxProc(WINDOW, MESSAGE, PARAM, PARAM);
int cYesNoBoxProc(WINDOW, MESSAGE, PARAM, PARAM);
int cErrorBoxProc(WINDOW, MESSAGE, PARAM, PARAM);
int cCancelBoxProc(WINDOW, MESSAGE, PARAM, PARAM);
int cInputBoxProc(WINDOW, MESSAGE, PARAM, PARAM);

// dialbox.c
int cControlProc(WINDOW, MESSAGE, PARAM, PARAM);

// slidebox.c, which is not currently used.
// int cGenericProc(WINDOW, MESSAGE, PARAM, PARAM);
