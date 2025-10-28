/* --------------------- video.c -------------------- */

#include "dflat.h"
#include <stdint.h>

int SCREENWIDTH = 80;
int SCREENHEIGHT = 24;
BOOL ClipString;

char *video_address;
int foreground, background;   /* current video colors */

static void movetoscreen(void far *bf, int offset, int len);

BOOL c_isVisible(WINDOW);

/* ------- write a string to a window ---------- */
void wputs(WINDOW wnd, void *s, int x, int y)
{
	int x1 = GetLeft(wnd)+x;
	int x2 = x1;
	int y1 = GetTop(wnd)+y;
    if (x1 < SCREENWIDTH && y1 < SCREENHEIGHT && c_isVisible(wnd))	{
		short ln[MAXCOLS];
		short *cp1 = ln;
	    unsigned char *str = s;
	    int fg = foreground;
    	int bg = background;
	    int len;
		int off = 0;
        while (*str)    {
            if (*str == CHANGECOLOR)    {
                str++;
                foreground = (*str++) & 0x7f;
                background = (*str++) & 0x7f;
                continue;
            }
            if (*str == RESETCOLOR)    {
                foreground = fg & 0x7f;
                background = bg & 0x7f;
                str++;
                continue;
            }
			if (*str == ('\t' | 0x80) || *str == ('\f' | 0x80))
	   	        *cp1 = ' ' | (clr(foreground, background) << 8);
			else 
	   	        *cp1 = (*str & 255) | (clr(foreground, background) << 8);
			if (ClipString)
				if (!CharInView(wnd, x, y))
					*cp1 = peek(video_address, vad(x2,y1));
			cp1++;
			str++;
			x++;
			x2++;
        }
        foreground = fg;
        background = bg;
   		len = (int)(cp1-ln);
   		if (x1+len > SCREENWIDTH)
       		len = SCREENWIDTH-x1;

		if (!ClipString && !c_TestAttribute(wnd, NOCLIP))	{
			/* -- clip the line to within ancestor windows -- */
			RECT rc = WindowRect(wnd);
			WINDOW nwnd = GetParent(wnd);
			while (len > 0 && nwnd != NULL)	{
				if (!c_isVisible(nwnd))	{
					len = 0;
					break;
				}
				rc = subRectangle(rc, ClientRect(nwnd));
				nwnd = GetParent(nwnd);
			}
			while (len > 0 && !InsideRect(x1+off,y1,rc))	{
				off++;
				--len;
			}
			if (len > 0)	{
				x2 = x1+len-1;
				while (len && !InsideRect(x2,y1,rc))	{
					--x2;
					--len;
				}
			}
		}
		if (len > 0)	{
        	hide_mousecursor();
			movetoscreen(ln+off, vad(x1+off,y1), len*2);
        	show_mousecursor();
		}
    }
}

/* --------- get the current video mode -------- */
void get_videomode(void)
{
    if (!video_address)
        video_address = tty_allocate_screen(SCREENWIDTH, SCREENHEIGHT);
}

void convert_screen_to_ansi()
{
    extern int cx, cy;

    tty_output_screen(0);
    if (cy >= 0)
        printf("\E[%d;%dH\e[?25h", cy+1, cx+1); /* restore cursor pos, cursor on */
    fflush(stdout);
}

static void movetoscreen(void far *bf, int offset, int len)
{
    memcpy(video_address + offset, bf, len);
}
