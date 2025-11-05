/* ------------- dflat.h ----------- */
#ifndef DFLAT_H
#define DFLAT_H

#define INCLUDE_MULTI_WINDOWS

#ifndef BUILD_SMALL_DFLAT
#define INCLUDE_HELP
#define INCLUDE_FILEOPENSAVE
#define INCLUDE_EDITMENU
#define INCLUDE_WINDOWMENU
#define INCLUDE_WINDOWOPTIONS
#define INCLUDE_SHELLDOS
#define INCLUDE_PICTUREBOX
#endif

#ifdef BUILD_FULL_DFLAT
#define INCLUDE_LOGGING
#define INCLUDE_MINIMIZE
#define INCLUDE_MAXIMIZE
#define INCLUDE_RESTORE
#define INCLUDE_EXTENDEDSELECTIONS
#endif

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <time.h>
#include <setjmp.h>

/* max() and min() may come from <stdlib.h> */
#define max(a,b)        (((a) > (b)) ? (a) : (b))
#define min(a,b)        (((a) < (b)) ? (a) : (b))

#ifndef VERSION
#define VERSION "Version 20"
#endif

extern char **Argv;

void *DFcalloc(size_t, size_t);
void *DFmalloc(size_t);
void *DFrealloc(void *, size_t);

typedef enum {FALSE, TRUE} BOOL;

#define OFF FALSE
#define ON  TRUE

//#define MAXMESSAGES 100
#define DELAYTICKS 1
#define FIRSTDELAY 7
#define DOUBLETICKS 5

#define MAXTEXTLEN 65000U /* maximum text buffer            */
#define EDITLEN     1024  /* starting length for multiliner */
#define ENTRYLEN     256  /* starting length for one-liner  */
#define GROWLENGTH    64  /* buffers grow by this much      */

#define MAXCOLS     300   /* max columns, used in line buffers */
#define MAXPOPWIDTH 80    /* max popup width */
#define MAXPATH     80

#include "classes.h"
#include "system.h"
#include "config.h"
#include "rect.h"
#include "keys.h"
#include "helpbox.h"

/* ------ integer type for message parameters ----- */
typedef intptr_t PARAM;

#include "video.h"

#define gotoxy(w,x,y) cursor(w->rc.lf+(x)+1,w->rc.tp+(y)+1)

#define SwapVideoBuffer(wnd, ish, fh) swapvideo(wnd, wnd->videosave, ish, fh)
int LineLength(char *);

extern int foreground, background;
extern char DFlatApplication[];
extern BOOL ClipString;
/* --------- space between menubar labels --------- */
#define MSPACE 2
/* --------------- border characters ------------- */
#define FOCUS_NW      (unsigned char) '\xc9'
#define FOCUS_NE      (unsigned char) '\xbb'
#define FOCUS_SE      (unsigned char) '\xbc'
#define FOCUS_SW      (unsigned char) '\xc8'
#define FOCUS_SIDE    (unsigned char) '\xba'
#define FOCUS_LINE    (unsigned char) '\xcd'
#define NW            (unsigned char) '\xda'
#define NE            (unsigned char) '\xbf'
#define SE            (unsigned char) '\xd9'
#define SW            (unsigned char) '\xc0'
#define SIDE          (unsigned char) '\xb3'
#define LINE          (unsigned char) '\xc4'
#define LEDGE         (unsigned char) '\xc3'
#define REDGE         (unsigned char) '\xb4'
#define SIZETOKEN     (unsigned char) '\x04'
/* ------------- scroll bar characters ------------ */
#define UPSCROLLBOX    (unsigned char) '\x1e'
#define DOWNSCROLLBOX  (unsigned char) '\x1f'
#define LEFTSCROLLBOX  (unsigned char) '\x11'
#define RIGHTSCROLLBOX (unsigned char) '\x10'
#define SCROLLBARCHAR  (unsigned char) 176 
#define SCROLLBOXCHAR  (unsigned char) 178
/* ------------------ menu characters --------------------- */
#define CHECKMARK      (unsigned char) (SCREENHEIGHT==25?251:4)
#define CASCADEPOINTER (unsigned char) '\x10'
/* ----------------- title bar characters ----------------- */
#define CONTROLBOXCHAR (unsigned char) '\xf0'
#define MAXPOINTER     24      /* maximize token            */
#define MINPOINTER     25      /* minimize token            */
#define RESTOREPOINTER 18      /* restore token             */
/* --------------- text control characters ---------------- */
#define APPLCHAR     (unsigned char) 176 /* fills application window */
#define SHORTCUTCHAR '~'    /* prefix: shortcut key display */
#define CHANGECOLOR  (unsigned char) 174 /* prefix to change colors  */
#define RESETCOLOR   (unsigned char) 175 /* reset colors to default  */
#define LISTSELECTOR   4    /* selected list box entry      */
/* --------- message prototypes ----------- */
void PostEvent(MESSAGE event, int p1, int p2);
void near collect_events(void);

/* ------------- help box prototypes ------------- */
void LoadHelpFile(char *);
void UnLoadHelpFile(void);
char *HelpComment(char *);

void BuildFileName(char *path, const char *fn, const char *ext);

#endif
