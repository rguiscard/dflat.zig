// message.c
extern BOOL AllocTesting;
extern jmp_buf AllocError;

// applicat.c
extern BOOL AltDown;

// textbox.c
void cWriteTextLine(int, RECT, int, char*, char*);

// editbox.c
void TextBlockToN(char *, char *);

// helpbox.c
struct helps *FindHelp(char *Help);
extern struct helps *FirstHelp;
extern struct helps *ThisHelp;
extern int HelpCount;
extern char HelpFileName[9];

extern FILE *helpfp;
extern BOOL Helping;

#define MAXHELPSTACK 100
extern int HelpStack[MAXHELPSTACK];
extern int stacked;

FILE *OpenHelpFile(const char *fn, const char *md);
//void ReadHelp(WINDOW);

// decomp.c
void SeekHelpLine(long, int);
void *GetHelpLine(char *);

// video.c
extern char *video_address;

// console-unix.c
extern int mouse_button;
extern int cx;
extern int cy;

// mouse-ansi.c
extern int mouse_x;        /* set in events-unix.c */
extern int mouse_y;
extern int mouse_button;
