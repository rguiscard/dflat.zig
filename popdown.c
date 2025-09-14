/* ------------- popdown.c ----------- */

#include "dflat.h"

int SelectionWidth(struct PopDown *);
//static int py = -1;
//int CurrentMenuSelection;

void cPaintPopDownSelection(WINDOW wnd, struct PopDown *pd1, char* sel, int sel_wd, int m_wd) {
            int len;
//            memset(sel, '\0', sizeof sel);
            memset(sel, '\0', MAXPOPWIDTH);
            if (pd1->Attrib & INACTIVE)
                /* ------ inactive menu selection ----- */
                sprintf(sel, "%c%c%c",
                    CHANGECOLOR,
                    wnd->WindowColors [HILITE_COLOR] [FG]|0x80,
                    wnd->WindowColors [STD_COLOR] [BG]|0x80);
            strcat(sel, " ");
            if (pd1->Attrib & CHECKED)
                /* ---- paint the toggle checkmark ---- */
                sel[strlen(sel)-1] = CHECKMARK;
            len=CopyCommand(sel+strlen(sel),pd1->SelectionTitle,
                    pd1->Attrib & INACTIVE,
                    wnd->WindowColors [STD_COLOR] [BG]);
            if (pd1->Accelerator)    {
                /* ---- paint accelerator key ---- */
                int i;
                int wd1 = 2+sel_wd - strlen(pd1->SelectionTitle);
				int key = pd1->Accelerator;
				if (key > 0 && key < 27)	{
					/* --- CTRL+ key --- */
                    while (wd1--)
                        strcat(sel, " ");
                   	sprintf(sel+strlen(sel), "[Ctrl+%c]", key-1+'A');
				}
				else	{
                	for (i = 0; keys[i].keylabel; i++)    {
                    	if (keys[i].keycode == key)   {
                        	while (wd1--)
                            	strcat(sel, " ");
                        	sprintf(sel+strlen(sel), "[%s]",
                            	keys[i].keylabel);
                        	break;
                    	}
					}
                }
            }
            if (pd1->Attrib & CASCADED)    {
                /* ---- paint cascaded menu token ---- */
                if (!pd1->Accelerator)    {
                    int wd = m_wd-len+1;
                    while (wd--)
                        strcat(sel, " ");
                }
                sel[strlen(sel)-1] = CASCADEPOINTER;
            }
            else
                strcat(sel, " ");
            strcat(sel, " ");
            sel[strlen(sel)-1] = RESETCOLOR;
}

/* --------- compute menu height -------- */
/*
int MenuHeight(struct PopDown *pd)
{
    int ht = 0;
    while (pd[ht].SelectionTitle != NULL)
        ht++;
    return ht+2;
}
*/

/* --------- compute menu width -------- */
/*
int MenuWidth(struct PopDown *pd)
{
    int wd = 0, i;
    int len = 0;

    wd = SelectionWidth(pd);
    while (pd->SelectionTitle != NULL)    {
        if (pd->Accelerator)    {
            for (i = 0; keys[i].keylabel; i++)
                if (keys[i].keycode == pd->Accelerator)    {
                    len = max(len, 2+strlen(keys[i].keylabel));
                    break;
                }
        }
        if (pd->Attrib & CASCADED)
            len = max(len, 2);
        pd++;
    }
    return wd+5+len;
}
*/

/* ---- compute the maximum selection width in a menu ---- */
/*
int SelectionWidth(struct PopDown *pd)
{
    int wd = 0;
    while (pd->SelectionTitle != NULL)    {
        int len = strlen(pd->SelectionTitle)-1;
        wd = max(wd, len);
        pd++;
    }
    return wd;
}
*/

/* ----- copy a menu command to a display buffer ---- */
int CopyCommand(unsigned char *dest, unsigned char *src,
                                        int skipcolor, int bg)
{
    unsigned char *d = dest;
    while (*src && *src != '\n')    {
        if (*src == SHORTCUTCHAR)    {
            src++;
            if (!skipcolor)    {
                *dest++ = CHANGECOLOR;
                *dest++ = cfg.clr[POPDOWNMENU]
                            [HILITE_COLOR] [BG] | 0x80;
                *dest++ = bg | 0x80;
                *dest++ = *src++;
                *dest++ = RESETCOLOR;
            }
        }
        else
            *dest++ = *src++;
    }
    return (int) (dest - d);
}
