/* ----------- console.c ---------- */

#include "dflat.h"
#include "unikey.h"

extern char *video_address;

//static int near cursorpos[MAXSAVES];
//static int near cursorshape[MAXSAVES];
//static int cs;

int cx, cy = -1;

#if 0
/* clear line y from x1 up to and including x2 to attribute attr */
static void clear_line(int x1, int x2, int y, int attr)
{
    int x;

    for (x = x1; x <= x2; x++) {
        *(unsigned short *)&video_address[(y * SCREENWIDTH + x) * 2] = ' ' | (attr << 8);
    }
}

/* scroll video RAM up from line y1 up to and including line y2 */
static void scrollup(int y1, int x1, int y2, int x2, int attr)
{
    int pitch = SCREENWIDTH * 2;
    int width = (x2 - x1 + 1) * 2;
    unsigned char *vid = video_address + y1 * pitch + x1 * 2;
    int y = y1;

    while (++y <= y2) {
        memcpy (vid, vid + pitch, width);
        vid += pitch;
    }
    clear_line (x1, x2, y2, attr);
}


/* scroll video RAM down from line y1 up to and including line y2 */
static void scrolldn(int y1, int x1, int y2, int x2, int attr)
{
    int pitch = SCREENWIDTH * 2;
    int width = (x2 - x1 + 1) * 2;
    unsigned char *vid = video_address + y2 * pitch + x1 * 2;
    int y = y2;

    while (--y >= y1) {
        memcpy (vid, vid - pitch, width);
        vid -= pitch;
    }
    clear_line (x1, x2, y1, attr);
}

static void scroll_video(int up, int n, int at, int y1, int x1, int y2, int x2)
{
    if (n == 0 || n >= SCREENHEIGHT)
        clear_line(x1, x2, y1, at);
    else if (y1 != y2) {
        while (--n >= 0) {
            if (up)
                scrollup(y1, x1, y2, x2, at);
            else scrolldn(y1, x1, y2, x2, at);
        }
    }
}

/* --------- scroll the window. d: 1 = up, 0 = dn ---------- */
void scroll_window(WINDOW wnd, RECT rc, int d)
{
	if (RectTop(rc) != RectBottom(rc))	{
		hide_mousecursor();
        scroll_video(d, 1, clr(c_WndForeground(wnd),c_WndBackground(wnd)),
            RectTop(rc), RectLeft(rc), RectBottom(rc), RectRight(rc));
		show_mousecursor();
	}
}
#endif
