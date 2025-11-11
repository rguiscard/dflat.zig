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
//void set_mouseposition(int x, int y);
void show_mousecursor(void);
void hide_mousecursor(void);
int button_releases(void);
void resetmouse(void);
//void set_mousetravel(int, int, int, int);
void waitformouse(void);
/* ------------ timer macros -------------- */
#define timed_out(timer)         (timer==0)
#define set_timer(timer, secs)     timer=(secs)*182/10+1
#define disable_timer(timer)     timer = -1
#define timer_running(timer)     (timer > 0)
#define countdown(timer)         --timer
#define timer_disabled(timer)     (timer == -1)

int runshell(void);

typedef enum messages {
	#undef DFlatMsg
	#define DFlatMsg(m) m,
	#include "dflatmsg.h"
	MESSAGECOUNT
} MESSAGE;

#endif
