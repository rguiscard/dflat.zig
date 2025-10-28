/* --------------------- video.c -------------------- */

#include "dflat.h"
#include <stdint.h>

int SCREENWIDTH = 80;
int SCREENHEIGHT = 24;
BOOL ClipString;

char *video_address;
int foreground, background;   /* current video colors */

void convert_screen_to_ansi()
{
    extern int cx, cy;

    tty_output_screen(0);
    if (cy >= 0)
        printf("\E[%d;%dH\e[?25h", cy+1, cx+1); /* restore cursor pos, cursor on */
    fflush(stdout);
}
