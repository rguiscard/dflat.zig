/* ------------- textbox.c ------------ */

#include "dflat.h"

/* ------- write a line of text to a textbox window ------- */
void cWriteTextLine(int wleft, int left, int right, int l, char *src, char *line)
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
    for (i = 0; i < wleft+3; i++)    {
        if (*(lp+i) == '\0')
            break;
        if (*(unsigned char *)(lp + i) == RESETCOLOR)
            break;
    }
    if (*(lp+i) && i < wleft+3)    {
        if (wleft+4 > lnlen)
            trunc = TRUE;
        else 
            lp += 4;
    }
    else     {
        /* --- it does, shift the color change over --- */
        for (i = 0; i < wleft; i++)    {
            if (*(lp+i) == '\0')
                break;
            if (*(unsigned char *)(lp + i) == CHANGECOLOR)    {
                *(lp+wleft+2) = *(lp+i+2);
                *(lp+wleft+1) = *(lp+i+1);
                *(lp+wleft) = *(lp+i);
                break;
            }
        }
    }
    /* ------ build the line to display -------- */
    if (!trunc)    {
        if (lnlen < wleft)
            lnlen = 0;
        else
            lp += wleft;
        if (lnlen > left)    {
            /* ---- the line exceeds the rectangle ---- */
            int ct = left;
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
            if (left)    {
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
            len = min(lnlen, (right-left+1));
            dif = strlen(lp) - lnlen;
            len += dif;
            if (len > 0)
                strncpy(line, lp, len);
        }
    }
    /* -------- pad the line --------- */
    while (len < (right-left+1)+dif)
        line[len++] = ' ';
    line[len] = '\0';
}
