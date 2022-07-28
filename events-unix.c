/* UNIX event generation */

#include <signal.h>
#include <termios.h>
#include <sys/select.h>
#include "dflat.h"
#include "unikey.h"

int mouse_x, mouse_y;
int mouse_button;

/* ------ collect mouse, clock, and keyboard events ----- */
void collect_events(void)
{
    fd_set fdset;
    struct timeval tv;
    int e, n;
    int mx, my, modkeys;
    char buf[32];

    FD_ZERO(&fdset);
    FD_SET(0, &fdset);
    tv.tv_sec = 0;
    tv.tv_usec = 30000;
    e = select(1, &fdset, NULL, NULL, &tv);
    if (e < 0) return;
    if (e == 0) return; //FIXME implement timeouts
    if (FD_ISSET(0, &fdset)) {
        if ((n = readansi(0, buf, sizeof(buf))) < 0)
            return;
        if ((e = ansi_to_unikey(buf, n)) != -1) {   // FIXME UTF-8 unicode != -1
            PostEvent(KEYBOARD, e, 0);    // no sk
            return;
        }
        if ((n = ansi_to_unimouse(buf, n, &mx, &my, &modkeys, &e)) != -1) {
            if (mx >= SCREENWIDTH || my >= SCREENHEIGHT-1) return;
            switch (n) {
            case kMouseLeftDown:
                PostEvent(LEFT_BUTTON, mx, my);
                break;
            case kMouseRightDown:
                PostEvent(RIGHT_BUTTON, mx, my);
                break;
            case kMouseLeftUp:
            case kMouseRightUp:
                PostEvent(BUTTON_RELEASED, mx, my);
                break;
            case kMouseMotion:          /* only returned on ANSI 1003 */
                break;
            case kMouseLeftDrag:
            case kMouseRightDrag:
                PostEvent(MOUSE_MOVED, mx, my);
                break;
            case kMouseWheelUp:
                PostEvent(KEYBOARD, (modkeys & kCtrl)? PGUP: UP, 0);
                break;
            case kMouseWheelDown:
                PostEvent(KEYBOARD, (modkeys & kCtrl)? PGDN: DN, 0);
                break;
            }
            mouse_x = mx;
            mouse_y = my;
            mouse_button = n;
            return;
        }
        printf("unknown ANSI key %s\r\n", unikeyname(n));
    }
#if 0
    /* -------- test for a clock event (one/second) ------- */
    if (timed_out(clocktimer))    {
        /* ----- get the current time ----- */
        time_t t = time(NULL);
        now = localtime(&t);
        hr = now->tm_hour > 12 ?
             now->tm_hour - 12 :
             now->tm_hour;
        if (hr == 0)
            hr = 12;
        sprintf(time_string, "%2d:%02d", hr, now->tm_min);
        strcpy(time_string+5, now->tm_hour > 11 ? "pm " : "am ");
        /* ------- blink the : at one-second intervals ----- */
        if (flipflop)
            *(time_string+2) = ' ';
        flipflop ^= TRUE;
        /* -------- reset the timer -------- */
        set_timer(clocktimer, 1);
        /* -------- post the clock event -------- */
        PostEvent(CLOCKTICK, FP_SEG(time_string), FP_OFF(time_string));
    }

    /* --------- keyboard events ---------- */
    if ((sk = getshift()) != ShiftKeys)    {
        ShiftKeys = sk;
        /* ---- the shift status changed ---- */
        PostEvent(SHIFT_CHANGED, sk, 0);
    	if (sk & ALTKEY)
			AltDown = TRUE;
    }

    /* ---- build keyboard events for key combinations that
        BIOS doesn't report --------- */
    if (sk & ALTKEY)	{
        if (keyportvalue == 14)    {
			AltDown = FALSE;
			waitforkeyboard();
            PostEvent(KEYBOARD, ALT_BS, sk);
        }
        if (keyportvalue == 83)    {
			AltDown = FALSE;
			waitforkeyboard();
            PostEvent(KEYBOARD, ALT_DEL, sk);
        }
	}
    if (sk & CTRLKEY)	{
		AltDown = FALSE;
        if (keyportvalue == 82)    {
			waitforkeyboard();
            PostEvent(KEYBOARD, CTRL_INS, sk);
        }
	}
    /* ----------- test for keystroke ------- */
    if (keyhit())    {
        static int cvt[] = {SHIFT_INS,END,DN,PGDN,BS,'5',
                        FWD,HOME,UP,PGUP};
        int c = getkey();

		AltDown = FALSE;
        /* -------- convert numeric pad keys ------- */
        if (sk & (LEFTSHIFT | RIGHTSHIFT))    {
            if (c >= '0' && c <= '9')
                c = cvt[c-'0'];
            else if (c == '.' || c == DEL)
                c = SHIFT_DEL;
            else if (c == INS)
                c = SHIFT_INS;
        }
		if (c != '\r' && (c < ' ' || c > 127))
			clearBIOSbuffer();
        /* ------ post the keyboard event ------ */
        PostEvent(KEYBOARD, c, sk);
    }

    /* ------------ test for mouse events --------- */
    if (button_releases())    {
        /* ------- the button was released -------- */
		AltDown = FALSE;
        doubletimer = DOUBLETICKS;
        PostEvent(BUTTON_RELEASED, mx, my);
        disable_timer(delaytimer);
    }
    get_mouseposition(&mx, &my);
    if (mx != px || my != py)  {
        px = mx;
        py = my;
        PostEvent(MOUSE_MOVED, mx, my);
    }
    if (rightbutton())	{
		AltDown = FALSE;
        PostEvent(RIGHT_BUTTON, mx, my);
	}
    if (leftbutton())    {
		AltDown = FALSE;
        if (mx == pmx && my == pmy)    {
            /* ---- same position as last left button ---- */
            if (timer_running(doubletimer))    {
                /* -- second click before double timeout -- */
                disable_timer(doubletimer);
                PostEvent(DOUBLE_CLICK, mx, my);
            }
            else if (!timer_running(delaytimer))    {
                /* ---- button held down a while ---- */
                delaytimer = lagdelay;
                lagdelay = DELAYTICKS;
                /* ---- post a typematic-like button ---- */
                PostEvent(LEFT_BUTTON, mx, my);
            }
        }
        else    {
            /* --------- new button press ------- */
            disable_timer(doubletimer);
            delaytimer = FIRSTDELAY;
            lagdelay = DELAYTICKS;
            PostEvent(LEFT_BUTTON, mx, my);
            pmx = mx;
            pmy = my;
        }
    }
    else
        lagdelay = FIRSTDELAY;
#endif
}
