/* ----------- console.c ---------- */

#include "dflat.h"
#include "unikey.h"

extern char *video_address;

static int near cursorpos[MAXSAVES];
static int near cursorshape[MAXSAVES];
static int cs;

int cx, cy = -1;

void cursor(int x, int y)
{
    cx = x;
    cy = y;
}

void curr_cursor(int *x, int *y)
{
    *x = cx;
    *y = cy;
}

void hidecursor(void)
{
    cy = -1;
}

void unhidecursor(void)
{
}

void savecursor(void)
{
    if (cs < MAXSAVES)    {
        //getcursor();
        //cursorshape[cs] = regs.x.cx;
        //cursorpos[cs] = regs.x.dx;
        cs++;
    }
}

void restorecursor(void)
{
    if (cs)    {
        --cs;
        //videomode();
        //regs.x.dx = cursorpos[cs];
        //regs.h.ah = SETCURSOR;
        //regs.x.bx = video_page;
        //int86(VIDEO, &regs, &regs);
        //set_cursor_type(cursorshape[cs]);
    }
}

void normalcursor(void)
{
}

void set_cursor_type(unsigned t)
{
}

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

void SwapCursorStack(void)
{
	if (cs > 1)	{
		swap(cursorpos[cs-2], cursorpos[cs-1]);
		swap(cursorshape[cs-2], cursorshape[cs-1]);
	}
}

int AltConvert(unsigned int c)
{
    if (c >= kAltA && c <= kAltZ)
        return c - kAltA + 'a';
    if (c >= kAlt0 && c <= kAlt9)
        return c - kAlt0 + '0';
    return c;
}

/* only called from AllocationError, wait on keyboard read to exit */
int getkey(void)
{
    int n, e;
    char buf[32];

    convert_screen_to_ansi();
    for (;;) {
        if ((n = readansi(0, buf, sizeof(buf))) < 0)
            break;
        if ((e = ansi_to_unikey(buf, n)) != -1)
            return e;
        /* not keystroke, ignore mouse */
    }
    return -1;
}

void waitformouse(void)
{
    int n, e;
    int mx, my, modkeys;
    char buf[32];
    extern int mouse_button;

    if (mouse_button != kMouseLeftDown && mouse_button != kMouseLeftDoubleClick)
        return;
    for (;;) {
        if ((n = readansi(0, buf, sizeof(buf))) < 0)
            break;
        if ((n = ansi_to_unimouse(buf, n, &mx, &my, &modkeys, &e)) != -1) {
            if (n == kMouseLeftUp)
                return;
        }
        /* ignore keystrokes */
    }
}

/* ---------- read the keyboard shift status --------- */
int getshift(void)
{
    return 0;
}

void beep(void)
{
}
