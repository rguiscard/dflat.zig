/* --------------- system.h -------------- */
#ifndef SYSTEM_H
#define SYSTEM_H

#define swap(a,b){int x=a;a=b;b=x;}

#define MAXSAVES 50

extern int SCREENWIDTH;
extern int SCREENHEIGHT;

#define waitforkeyboard()   // FIXME
#define clearBIOSbuffer()

/* ---------- keyboard prototypes -------- */
int AltConvert(unsigned int);
int getkey(void);
int getshift(void);
void beep(void);
/* ---------- cursor prototypes -------- */
void curr_cursor(int *x, int *y);
void cursor(int x, int y);
void hidecursor(void);
void unhidecursor(void);
void savecursor(void);
void restorecursor(void);
void normalcursor(void);
void set_cursor_type(unsigned t);
void SwapCursorStack(void);
/* --------- screen prototpyes -------- */
void clearscreen(void);
/* ---------- mouse prototypes ---------- */
BOOL mouse_installed(void);
int mousebuttons(void);
void get_mouseposition(int *x, int *y);
void set_mouseposition(int x, int y);
void show_mousecursor(void);
void hide_mousecursor(void);
int button_releases(void);
void resetmouse(void);
void set_mousetravel(int, int, int, int);
void waitformouse(void);
/* ------------ timer macros -------------- */
#define timed_out(timer)         (timer==0)
#define set_timer(timer, secs)     timer=(secs)*182/10+1
#define disable_timer(timer)     timer = -1
#define timer_running(timer)     (timer > 0)
#define countdown(timer)         --timer
#define timer_disabled(timer)     (timer == -1)

int runshell(void);

/* ============= Color Macros ============ */
#define BLACK         0
#define BLUE          1
#define GREEN         2
#define CYAN          3
#define RED           4
#define MAGENTA       5
#define BROWN         6
#define LIGHTGRAY     7
#define DARKGRAY      8
#define LIGHTBLUE     9
#define LIGHTGREEN   10
#define LIGHTCYAN    11
#define LIGHTRED     12
#define LIGHTMAGENTA 13
#define YELLOW       14
#define WHITE        15

typedef enum messages {
	#undef DFlatMsg
	#define DFlatMsg(m) m,
	#include "dflatmsg.h"
	MESSAGECOUNT
} MESSAGE;

/*
 * Incompatibility with ELKS compiler and D-Flat for CLASS enum:
 * without an enum element of -1, the enum type is optimized to be
 * unsigned char, with an allocated width of 1 byte. However, a
 * -1 base class comparison with CLASS is required.
 * Adding an enum element of -1 still allocates sizeof(char) for enum width,
 * but type is signed char, which works with -1 class comparison.
 * Another solution would be using -fno-short-enums, which uses more space,
 * as 2 bytes (and type int) would always be allocated for a CLASS enum.
 */
#if 0
typedef enum window_class    {
	FORCEINTTYPE = -1,      /* required or enum type is unsigned char */
	#define ClassDef(c,b,a) c,
	#include "classes.h"
	CLASSCOUNT
} CLASS;
#endif

#endif
