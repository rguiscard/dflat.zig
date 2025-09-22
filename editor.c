/* ------------- editor.c ------------ */
#include "dflat.h"

#define pTab ('\t' + 0x80)
#define sTab ('\f' + 0x80)

/* ---------- SETTEXT Message ------------ */
#if 0
int cSetTextMsg(WINDOW wnd, char *Buf)
{
   	unsigned char *tp, *ep, *ttp;
   	int x = 0;
   	int sz = 0;
	int rtn;

	tp = Buf;
    /* --- compute the buffer size based on tabs in the text --- */
    while (*tp)    {
        if (*tp == '\t')    {
            /* --- tab, adjust the buffer length --- */
            int sps = cfg.Tabs - (x % cfg.Tabs);
            sz += sps;
            x += sps;
        }
        else    {
            /* --- not a tab, count the character --- */
            sz++;
            x++;
        }
        if (*tp == '\n')
            x = 0;    /* newline, reset x --- */
        tp++;
    }
    /* --- allocate a buffer --- */
    ep = DFcalloc(1, sz+1);
    /* --- detab the input file --- */
    tp = Buf;
    ttp = ep;
    x = 0;
    while (*tp)    {
        /* --- put the character (\t, too) into the buffer --- */
        x++;
        /* --- expand tab into subst tab (\f + 0x80)
						and expansions (\t + 0x80) --- */
        if (*tp == '\t')	{
	        *ttp++ = sTab;	/* --- substitute tab character --- */
            while ((x % cfg.Tabs) != 0)
                *ttp++ = pTab, x++;
		}
		else	{
	        *ttp++ = *tp;
        	if (*tp == '\n')
            	x = 0;
		}
        tp++;
    }
    *ttp = '\0';
	rtn = BaseWndProc(EDITOR, wnd, SETTEXT, (PARAM) ep, 0);
    free(ep);
	return rtn;
}
#endif

#if 0
void CollapseTabs(WINDOW wnd)
{
	unsigned char *cp = wnd->text, *cp2;
	while (*cp)	{
		if (*cp == sTab)	{
			*cp = '\t';
			cp2 = cp;
			while (*++cp2 == pTab)
				;
			memmove(cp+1, cp2, strlen(cp2)+1);
		}
		cp++;
	}
}

void ExpandTabs(WINDOW wnd)
{
	int Holdwtop = wnd->wtop;
	int Holdwleft = wnd->wleft;
	int HoldRow = wnd->CurrLine;
	int HoldCol = wnd->CurrCol;
	int HoldwRow = wnd->WndRow;
	SendMessage(wnd, SETTEXT, (PARAM) wnd->text, 0);
	wnd->wtop = Holdwtop;
	wnd->wleft = Holdwleft;
	wnd->CurrLine = HoldRow;
	wnd->CurrCol = HoldCol;
	wnd->WndRow = HoldwRow;
	SendMessage(wnd, PAINT, 0, 0);
	SendMessage(wnd, KEYBOARD_CURSOR, 0, wnd->WndRow);
}
#endif

/* --- When inserting or deleting, adjust next following tab, same line --- */
#if 0
void AdjustTab(WINDOW wnd)
{
    /* ---- test if there is a tab beyond this character ---- */
	int col = wnd->CurrCol;
    while (*CurrChar && *CurrChar != '\n')    {
		if (*CurrChar == sTab)	{
			int exp = (cfg.Tabs - 1) - (wnd->CurrCol % cfg.Tabs);
	        wnd->CurrCol++;
			while (*CurrChar == pTab)
				BaseWndProc(EDITOR, wnd, KEYBOARD, DEL, 0);
			while (exp--)
				BaseWndProc(EDITOR, wnd, KEYBOARD, pTab, 0);
			break;
		}
        wnd->CurrCol++;
    }

	wnd->CurrCol = col;
}
#endif
