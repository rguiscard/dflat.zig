/* ---------------- video.h ----------------- */

#ifndef VIDEO_H
#define VIDEO_H

#include "rect.h"

/* video output options */
#define VIDEO_FB    1   /* output to internal framebuffer, then translate */
#define VIDEO_EGA   0   /* direct output to hardware EGA */

#if VIDEO_FB
#define far
//#define poke(a,o,w)     (*((unsigned short *)((char *)(a)+(o))) = (w))
//#define peek(a,o)       (*((unsigned short *)((char *)(a)+(o))))
void convert_screen_to_ansi(void);
#endif

#define near

void getvideo(RECT, void far *);
void storevideo(RECT, void far *);
void get_videomode(void);
void wputs(WINDOW, void *, int, int);
void scroll_window(WINDOW, RECT, int);

#define clr(fg,bg) ((fg)|((bg)<<4))
//#define vad(x,y) ((y)*(SCREENWIDTH*2)+(x)*2)

#endif
