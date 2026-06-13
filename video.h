/* ---------------- video.h ----------------- */

#ifndef VIDEO_H
#define VIDEO_H

#include "rect.h"

/* video output: framebuffer only (termbox2) */
#define far
#define poke(a,o,w)     (*((unsigned long *)((char *)(a)+(o))) = (w))
#define peek(a,o)       (*((unsigned long *)((char *)(a)+(o))))
void convert_screen_to_ansi(void);
typedef unsigned int videocell_t; /* 32-bit: upper 16-bit attr + lower 16-bit original CP437 or Unicode char */

#define near

void getvideo(RECT, void far *);
void storevideo(RECT, void far *);
void wputch(WINDOW, int, int, int);
unsigned int GetVideoChar(int, int);
void PutVideoChar(int, int, int);
void get_videomode(void);
void wputs(WINDOW, void *, int, int);
void scroll_window(WINDOW, RECT, int);

#define clr(fg,bg) ((fg)|((bg)<<4))
#define vad(x,y) ((y)*(SCREENWIDTH*4)+(x)*4)
#define videochar(x,y) (GetVideoChar(x,y) & 0xff)

#endif
