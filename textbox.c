/* ------------- textbox.c ------------ */

#include "dflat.h"

/* ------- write a line of text to a textbox window ------- */
void cWriteTextLine(WINDOW wnd, RECT rc, int l, char *src, char *line)
{
    int len = 0;
    int dif = 0;
    unsigned char *lp; //, *svlp;
    int lnlen = l;
    int i;
    BOOL trunc = FALSE;

    /* --- get the text and length of the text line --- */
    lp = src;

    /* - make sure left margin doesn't overlap color change - */
    for (i = 0; i < wnd->wleft+3; i++)    {
        if (*(lp+i) == '\0')
            break;
        if (*(unsigned char *)(lp + i) == RESETCOLOR)
            break;
    }
    if (*(lp+i) && i < wnd->wleft+3)    {
        if (wnd->wleft+4 > lnlen)
            trunc = TRUE;
        else 
            lp += 4;
    }
    else     {
        /* --- it does, shift the color change over --- */
        for (i = 0; i < wnd->wleft; i++)    {
            if (*(lp+i) == '\0')
                break;
            if (*(unsigned char *)(lp + i) == CHANGECOLOR)    {
                *(lp+wnd->wleft+2) = *(lp+i+2);
                *(lp+wnd->wleft+1) = *(lp+i+1);
                *(lp+wnd->wleft) = *(lp+i);
                break;
            }
        }
    }
    /* ------ build the line to display -------- */
    if (!trunc)    {
        if (lnlen < wnd->wleft)
            lnlen = 0;
        else
            lp += wnd->wleft;
        if (lnlen > RectLeft(rc))    {
            /* ---- the line exceeds the rectangle ---- */
            int ct = RectLeft(rc);
            char *initlp = lp;
            /* --- point to end of clipped line --- */
            while (ct)    {
                if (*(unsigned char *)lp == CHANGECOLOR)
                    lp += 3;
                else if (*(unsigned char *)lp == RESETCOLOR)
                    lp++;
                else
                    lp++, --ct;
            }
            if (RectLeft(rc))    {
                char *lpp = lp;
                while (*lpp)    {
                    if (*(unsigned char*)lpp==CHANGECOLOR)
                        break;
                    if (*(unsigned char*)lpp==RESETCOLOR) {
                        lpp = lp;
                        while (lpp >= initlp)    {
                            if (*(unsigned char *)lpp ==
                                            CHANGECOLOR) {
                                lp -= 3;
                                memmove(lp,lpp,3);
                                break;
                            }
                            --lpp;
                        }
                        break;
                    }
                    lpp++;
                }
            }
            lnlen = LineLength(lp);
            len = min(lnlen, RectWidth(rc));
            dif = strlen(lp) - lnlen;
            len += dif;
            if (len > 0)
                strncpy(line, lp, len);
        }
    }
    /* -------- pad the line --------- */
    while (len < RectWidth(rc)+dif)
        line[len++] = ' ';
    line[len] = '\0';
}
