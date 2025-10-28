/* --------------------- video.c -------------------- */

#include "dflat.h"
#include <stdint.h>

int SCREENWIDTH = 80;
int SCREENHEIGHT = 24;
BOOL ClipString;

char *video_address;
int foreground, background;   /* current video colors */

//static void movetoscreen(void far *bf, int offset, int len);

//BOOL c_isVisible(WINDOW);

/* ------- write a string to a window ---------- */
//void c_wputs(WINDOW wnd, int len, unsigned short *ln, int x1, int y1, int off)
//{
//    int off = 0;
//    if (!ClipString && !c_TestAttribute(wnd, NOCLIP)) {
//        /* -- clip the line to within ancestor windows -- */
//        RECT rc = WindowRect(wnd);
//        WINDOW nwnd = GetParent(wnd);
//        while (len > 0 && nwnd != NULL) {
//            if (!c_isVisible(nwnd))	{
//                len = 0;
//                break;
//            }
//            rc = subRectangle(rc, ClientRect(nwnd));
//            nwnd = GetParent(nwnd);
//        }
//        while (len > 0 && !InsideRect(x1+off,y1,rc)) {
//            off++;
//            --len;
//        }
//        if (len > 0) {
//            x2 = x1+len-1;
//            while (len && !InsideRect(x2,y1,rc)) {
//                --x2;
//                --len;
//            }
//        }
//    }
//    if (len > 0) {
//        hide_mousecursor();
//        movetoscreen(ln+off, vad(x1+off,y1), len*2);
//        show_mousecursor();
//    }
//}

void convert_screen_to_ansi()
{
    extern int cx, cy;

    tty_output_screen(0);
    if (cy >= 0)
        printf("\E[%d;%dH\e[?25h", cy+1, cx+1); /* restore cursor pos, cursor on */
    fflush(stdout);
}

//static void movetoscreen(void far *bf, int offset, int len)
//{
//    memcpy(video_address + offset, bf, len);
//}
