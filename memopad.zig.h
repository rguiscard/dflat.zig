// window.c
WINDOW cCreateWindow(CLASS,const char *,int,int,int,int,void*,WINDOW,
       int (*)(struct window *,enum messages,PARAM,PARAM),int);

// message.c
void c_dispatch_message(MESSAGE ev_event, int ev_mx, int ev_my);
BOOL ProcessMessage(WINDOW, MESSAGE, PARAM, PARAM, int);

// normal.c
extern struct window dwnd;

// pictbox.c
typedef struct {
    enum VectTypes vt;
    RECT rc;
} VECT;


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
