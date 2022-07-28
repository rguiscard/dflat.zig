/* ------------- mouse-ansi.c ------------- */

#include "dflat.h"
#include "unikey.h"

extern int mouse_x;        /* set in events-unix.c */
extern int mouse_y;
extern int mouse_button;

/* ---------- reset the mouse ---------- */
void resetmouse(void)
{
}

/* ----- test to see if the mouse driver is installed ----- */
BOOL mouse_installed(void)
{
    return 1;
}

/* ------ return true if mouse buttons are pressed ------- */
int mousebuttons(void)
{
    return mouse_button;
}

/* ---------- return mouse coordinates ---------- */
void get_mouseposition(int *x, int *y)
{
    *x = mouse_x;
    *y = mouse_y;
}

/* -------- position the mouse cursor -------- */
void set_mouseposition(int x, int y)
{
    //char buf[32];
    //mouse_x = x;
    //mouse_y = y;
    //sprintf(buf, "\e[%d;%dH", y+1, x+1);
    //write(1, buf, strlen(buf));
}

/* --------- display the mouse cursor -------- */
void show_mousecursor(void)
{
    //const char *p = "\e[?25h";
    //write(1, p, strlen(p));
}

/* --------- hide the mouse cursor ------- */
void hide_mousecursor(void)
{
    //const char *p = "\e[?25l";
    //write(1, p, strlen(p));
}

/* --- return true if a mouse button has been released --- */
int button_releases(void)
{
	return (mouse_button == kMouseLeftUp || mouse_button == kMouseRightUp);
}

/* ----- set mouse travel limits ------- */
void set_mousetravel(int minx, int maxx, int miny, int maxy)
{
}
