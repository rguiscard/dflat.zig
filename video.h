/* ---------------- video.h ----------------- */

#ifndef VIDEO_H
#define VIDEO_H

#include "rect.h"

/* video output options */
#define VIDEO_FB    1   /* output to internal framebuffer, then translate */
#define VIDEO_EGA   0   /* direct output to hardware EGA */

#if VIDEO_FB
#define far
#define poke(a,o,w)     (*((unsigned short *)((char *)(a)+(o))) = (w))
#define peek(a,o)       (*((unsigned short *)((char *)(a)+(o))))
void convert_screen_to_ansi(void);
#endif

//#if VIDEO_EGA
//#define far             __far
//#define FP_OFF(fp)      ((unsigned)(unsigned long)(void __far *)(fp))
//#define FP_SEG(fp)      ((unsigned)((unsigned long)(void __far *)(fp) >> 16))
//#define MK_FP(seg,off)  ((void __far *)((((unsigned long)(seg)) << 16) | (off)))
//#define poke(s,o,w)     (*((unsigned short __far*)MK_FP((s),(o))) = (w))
//#define peek(s,o)       (*((unsigned short __far*)MK_FP((s),(o))))
//void   fmemcpyb(unsigned dst_off, unsigned dst_seg, unsigned src_off,
//                unsigned src_seg, unsigned count);
/*void movedata(unsigned srcseg, unsigned srcoff, unsigned dstseg, unsigned dstoff,
                unsigned n);*/
//#define movedata(ss,so,ds,do,n) fmemcpyb(do,ds,so,ss,n)
//#endif

#define near

void getvideo(RECT, void far *);
void storevideo(RECT, void far *);
//void wputch(WINDOW, int, int, int);
//unsigned int GetVideoChar(int, int);
//void PutVideoChar(int, int, int);
void get_videomode(void);
void wputs(WINDOW, void *, int, int);
void scroll_window(WINDOW, RECT, int);

#define clr(fg,bg) ((fg)|((bg)<<4))
#define vad(x,y) ((y)*(SCREENWIDTH*2)+(x)*2)
// #define videochar(x,y) (GetVideoChar(x,y) & 255)

#endif
