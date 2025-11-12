/* ---------------- video.h ----------------- */

#ifndef VIDEO_H
#define VIDEO_H

//#include "rect.h"

/* video output options */
//#define VIDEO_FB    1   /* output to internal framebuffer, then translate */
//#define VIDEO_EGA   0   /* direct output to hardware EGA */

//#if VIDEO_FB
//#define far
void convert_screen_to_ansi(void);
//#endif

//#define near

//#define clr(fg,bg) ((fg)|((bg)<<4))

#endif
