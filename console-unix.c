/* ----------- console.c ---------- */

#include "dflat.h"
#include "termbox2.h"

extern int tb_to_dflat_key(struct tb_event *);

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
    struct tb_event ev;

    for (;;) {
        if (tb_poll_event(&ev) != TB_OK)
            continue;
        if (ev.type == TB_EVENT_KEY) {
            int k = tb_to_dflat_key(&ev);
            if (k != 0)
                return k;
        }
    }
}

void waitformouse(void)
{
    struct tb_event ev;

    for (;;) {
        if (tb_poll_event(&ev) != TB_OK)
            continue;
        if (ev.type == TB_EVENT_MOUSE) {
            if (ev.key == TB_KEY_MOUSE_RELEASE)
                return;
        }
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
