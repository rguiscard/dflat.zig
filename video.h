/* ---------------- video.h ----------------- */

#ifndef VIDEO_H
#define VIDEO_H

#include "rect.h"
#include <stdint.h>

/* video output: framebuffer only (termbox2) */
#define far
#define poke(a,o,w)     (*((unsigned long *)((char *)(a)+(o))) = (w))
#define peek(a,o)       (*((unsigned long *)((char *)(a)+(o))))
void convert_screen_to_ansi(void);

/* Define uintattr_t to match termbox's type (16-bit width by default) */
typedef uint16_t uintattr_t;

/* Define videocell_t with same layout as termbox's tb_cell for compatibility.
 * This is the "screen buffer" that dflat uses for save/restore operations.
 * It stores: Unicode char (32-bit) + fg attr (16-bit) + bg attr (16-bit) = 8 bytes */
typedef struct videocell {
    uint32_t ch;   /* Unicode codepoint or CP437 mapped to Unicode */
    uintattr_t fg; /* foreground attributes (TB_* color constants) */
    uintattr_t bg; /* background attributes (TB_* color constants) */
} videocell_t;

#define near

void getvideo(RECT, void far *);
void storevideo(RECT, void far *);
void wputch(WINDOW, int, int, int);
videocell_t GetVideoChar(int, int);
void PutVideoChar(int, int, videocell_t);
void get_videomode(void);
void wputs(WINDOW, void *, int, int);
void wputuline(WINDOW, uint32_t *, int, int, int);
void wputuchline(WINDOW, uint32_t, int, int, int);
void scroll_window(WINDOW, RECT, int);

/* Color conversion functions - used by callers that need to construct cell values */
uintattr_t tb_fg_from_attr(int attr);
uintattr_t tb_bg_from_attr(int attr);

#define clr(fg,bg) ((fg)|((bg)<<4))
#define vad(x,y) ((y)*(SCREENWIDTH*4)+(x)*4)
#define videochar(x,y) (GetVideoChar(x,y).ch)

#endif
