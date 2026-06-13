/* --------------------- video.c -------------------- */

#include "dflat.h"
#include "termbox2.h"
#include "unikey.h"
#include <stdint.h>

int SCREENWIDTH = 80;
int SCREENHEIGHT = 24;
BOOL ClipString;

static const uintattr_t tb_base_colors[8] = {
    TB_BLACK, TB_BLUE, TB_GREEN, TB_CYAN,
    TB_RED, TB_MAGENTA, TB_YELLOW, TB_WHITE
};

static int in_screen(int x, int y)
{
    return x >= 0 && y >= 0 && x < SCREENWIDTH && y < SCREENHEIGHT;
}

/* use videocell_t from video.h */

static uint32_t dflat_char_to_tb(videocell_t c)
{
    /* The lower 16 bits contain either CP437 code (0-255) or Unicode (>=256) */
    uint16_t ch = c & 0xffff;
    if (ch < 256)
        return kCp437[ch];
    return ch;  /* Already Unicode */
}

static uint32_t tb_char_to_dflat(uint32_t ch)
{
    /* Store Unicode codepoint directly - preserve original character */
    /* For Unicode >= 256, store as-is. For ASCII 0-255, also store as-is */
    /* since dflat_char_to_tb will handle the remapping when writing */
    return ch;
}

static uintattr_t tb_fg_from_attr(int attr)
{
    int fg = attr & 0x0f;
    uintattr_t color = tb_base_colors[fg & 7];

    if (fg & 8)
        color |= TB_BRIGHT;
    return color;
}

static uintattr_t tb_bg_from_attr(int attr)
{
    return tb_base_colors[(attr >> 4) & 7];
}

static int tb_color_to_dflat(uintattr_t attr)
{
    switch (attr & 0xff) {
    case TB_BLACK:   return BLACK;
    case TB_BLUE:    return BLUE;
    case TB_GREEN:   return GREEN;
    case TB_CYAN:    return CYAN;
    case TB_RED:     return RED;
    case TB_MAGENTA: return MAGENTA;
    case TB_YELLOW:  return BROWN;
    case TB_WHITE:   return LIGHTGRAY;
    default:         return BLACK;
    }
}

static int dflat_attr_from_tb(uintattr_t fg, uintattr_t bg)
{
    int f = tb_color_to_dflat(fg);
    int b = tb_color_to_dflat(bg);

    if (fg & TB_BRIGHT)
        f += 8;
    return (f & 0x0f) | ((b & 7) << 4);
}

static void termbox_read_cell(int x, int y, uint32_t *ch,
    uintattr_t *fg, uintattr_t *bg)
{
    struct tb_cell *cell = NULL;

    if (tb_get_cell(x, y, 1, &cell) == TB_OK && cell != NULL) {
        *ch = cell->ch;
        *fg = cell->fg;
        *bg = cell->bg;
    } else {
        *ch = ' ';
        *fg = TB_DEFAULT;
        *bg = TB_DEFAULT;
    }
}

static void termbox_write_cell(int x, int y, uint32_t ch,
    uintattr_t fg, uintattr_t bg)
{
    if (in_screen(x, y))
        tb_set_cell(x, y, ch, fg, bg);
}

static void termbox_write_dflat_cell(int x, int y, videocell_t c)
{
    uint32_t ch = dflat_char_to_tb(c);
    int attr = (c >> 16) & 0xff;

    termbox_write_cell(x, y, ch,
        tb_fg_from_attr(attr), tb_bg_from_attr(attr));
}

/* -- read a rectangle of video memory into a save buffer -- */
void getvideo(RECT rc, void far *bf)
{
    int ht = RectBottom(rc)-RectTop(rc)+1;
    int y;
    videocell_t far *p = bf;

    hide_mousecursor();
    for (y = RectTop(rc); y <= RectBottom(rc); y++) {
        int x;
        for (x = RectLeft(rc); x <= RectRight(rc); x++) {
            uint32_t ch;
            uintattr_t fg, bg;

            termbox_read_cell(x, y, &ch, &fg, &bg);
            *p++ = ((videocell_t)ch) | ((videocell_t)dflat_attr_from_tb(fg, bg) << 16);
        }
    }
    show_mousecursor();
}

/* -- write a rectangle of video memory from a save buffer -- */
void storevideo(RECT rc, void far *bf)
{
    int ht = RectBottom(rc)-RectTop(rc)+1;
    int y;
    videocell_t far *p = bf;

    hide_mousecursor();
    for (y = RectTop(rc); y <= RectBottom(rc); y++) {
        int x;
        for (x = RectLeft(rc); x <= RectRight(rc); x++) {
            termbox_write_dflat_cell(x, y, *p++);
        }
    }
    show_mousecursor();
}

/* -------- read a character of video memory ------- */
unsigned int GetVideoChar(int x, int y)
{
    uint32_t ch;
    uintattr_t fg, bg;

    hide_mousecursor();
    termbox_read_cell(x, y, &ch, &fg, &bg);
    show_mousecursor();
    return ((unsigned int)dflat_attr_from_tb(fg, bg) << 16) | (unsigned int)tb_char_to_dflat(ch);
}

/* -------- write a character of video memory ------- */
void PutVideoChar(int x, int y, int c)
{
    if (in_screen(x, y)) {
        hide_mousecursor();
        termbox_write_dflat_cell(x, y, (videocell_t)c);
        show_mousecursor();
    }
}

BOOL CharInView(WINDOW wnd, int x, int y)
{
	WINDOW nwnd = NextWindow(wnd);
	WINDOW pwnd;
	RECT rc;
    int x1 = GetLeft(wnd)+x;
    int y1 = GetTop(wnd)+y;

	if (!TestAttribute(wnd, VISIBLE))
		return FALSE;
    if (!TestAttribute(wnd, NOCLIP))    {
        WINDOW wnd1 = GetParent(wnd);
        while (wnd1 != NULL)    {
            /* --- clip character to parent's borders -- */
			if (!TestAttribute(wnd1, VISIBLE))
				return FALSE;
			if (!InsideRect(x1, y1, ClientRect(wnd1)))
                return FALSE;
            wnd1 = GetParent(wnd1);
        }
    }
	while (nwnd != NULL)	{
		if (!isHidden(nwnd) /* && !isAncestor(wnd, nwnd) */ )	{
			rc = WindowRect(nwnd);
    		if (TestAttribute(nwnd, SHADOW))    {
        		RectBottom(rc)++;
        		RectRight(rc)++;
    		}
			if (!TestAttribute(nwnd, NOCLIP))	{
				pwnd = nwnd;
				while (GetParent(pwnd))	{
					pwnd = GetParent(pwnd);
					rc = subRectangle(rc, ClientRect(pwnd));
				}
			}
			if (InsideRect(x1,y1,rc))
				return FALSE;
		}
		nwnd = NextWindow(nwnd);
	}
    return (x1 < SCREENWIDTH && y1 < SCREENHEIGHT);
}

/* -------- write a character to a window ------- */
void wputch(WINDOW wnd, int c, int x, int y)
{
    if (CharInView(wnd, x, y))    {
        videocell_t ch = ((videocell_t)c) | ((videocell_t)clr(foreground, background) << 16);
        int xc = GetLeft(wnd)+x;
        int yc = GetTop(wnd)+y;
        hide_mousecursor();
        termbox_write_dflat_cell(xc, yc, ch);
        show_mousecursor();
    }
}

/* ------- write a string to a window ---------- */
void wputs(WINDOW wnd, void *s, int x, int y)
{
    int x1 = GetLeft(wnd)+x;
    int x2 = x1;
    int y1 = GetTop(wnd)+y;
    if (x1 < SCREENWIDTH && y1 < SCREENHEIGHT && isVisible(wnd))	{
        videocell_t ln[MAXCOLS];
        videocell_t *cp1 = ln;
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
                *cp1 = (videocell_t)' ' | ((videocell_t)clr(foreground, background) << 16);
            else
                *cp1 = ((videocell_t)(unsigned char)*str) | ((videocell_t)clr(foreground, background) << 16);
            if (ClipString)
                if (!CharInView(wnd, x, y))
                    *cp1 = GetVideoChar(x2,y1);
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

        if (!ClipString && !TestAttribute(wnd, NOCLIP))	{
            /* -- clip the line to within ancestor windows -- */
            RECT rc = WindowRect(wnd);
            WINDOW nwnd = GetParent(wnd);
            while (len > 0 && nwnd != NULL)	{
                if (!isVisible(nwnd))	{
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
        if (len > 0) {
            int i;
            hide_mousecursor();
            for (i = 0; i < len; i++)
                termbox_write_dflat_cell(x1+off+i, y1, ln[off+i]);
            show_mousecursor();
        }
    }
}

/* --------- get the current video mode -------- */
void get_videomode(void)
{
#if VIDEO_FB
    int w = tb_width();
    int h = tb_height();

    if (w > 0 && h > 0) {
        SCREENWIDTH = min(w, MAXCOLS - 1);
        SCREENHEIGHT = h - 1;
    }
#else
#if VIDEO_BIOS
#define ismono() (video_mode == 7)
    if (ismono())
        video_address = 0xb000;
    else {
        video_address = 0xb800 + video_page;
    }
#endif
#endif
}

#if VIDEO_FB
void convert_screen_to_ansi()
{
    tb_present();
}
#endif

void scroll_window(WINDOW wnd, RECT rc, int d)
{
    int x1 = RectLeft(rc);
    int x2 = RectRight(rc);
    int y1 = RectTop(rc);
    int y2 = RectBottom(rc);
    int attr;
    int x, y;

    if (x1 < 0)
        x1 = 0;
    if (y1 < 0)
        y1 = 0;
    if (x2 >= SCREENWIDTH)
        x2 = SCREENWIDTH - 1;
    if (y2 >= SCREENHEIGHT)
        y2 = SCREENHEIGHT - 1;
    if (x1 > x2 || y1 >= y2)
        return;

    attr = clr(WndForeground(wnd), WndBackground(wnd));
    hide_mousecursor();
    if (d) {
        for (y = y1; y < y2; y++)
            for (x = x1; x <= x2; x++) {
                uint32_t ch;
                uintattr_t fg, bg;

                termbox_read_cell(x, y + 1, &ch, &fg, &bg);
                termbox_write_cell(x, y, ch, fg, bg);
            }
        for (x = x1; x <= x2; x++)
            termbox_write_dflat_cell(x, y2, (videocell_t)' ' | ((videocell_t)attr << 16));
    } else {
        for (y = y2; y > y1; y--)
            for (x = x1; x <= x2; x++) {
                uint32_t ch;
                uintattr_t fg, bg;

                termbox_read_cell(x, y - 1, &ch, &fg, &bg);
                termbox_write_cell(x, y, ch, fg, bg);
            }
        for (x = x1; x <= x2; x++)
            termbox_write_dflat_cell(x, y1, (videocell_t)' ' | ((videocell_t)attr << 16));
    }
    show_mousecursor();
}
