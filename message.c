/* --------- message.c ---------- */

#include "dflat.h"

/*
static int px = -1, py = -1;
static int pmx = -1, pmy = -1;
static int mx, my;
*/
//static int handshaking = 0;
BOOL AllocTesting = FALSE;
jmp_buf AllocError;
BOOL AltDown = FALSE;

//static int lagdelay = FIRSTDELAY;

static volatile int keyportvalue;	/* for watching for key release */

//WINDOW CaptureMouse;
//WINDOW CaptureKeyboard;
//BOOL NoChildCaptureMouse; // should be private
//BOOL NoChildCaptureKeyboard; // should be private

//static volatile int delaytimer  = -1;
//static volatile int clocktimer  = -1;
char time_string[] = "         ";

//static WINDOW Cwnd;

//BOOL cProcessMessage(WINDOW, MESSAGE, PARAM, PARAM);

/* ------------ initialize the message system --------- */
/*
BOOL init_messages(void)
{
    NoChildCaptureMouse = FALSE;
    NoChildCaptureKeyboard = FALSE;
    PostMessage(NULL,START,0,0);
    lagdelay = FIRSTDELAY;
    return TRUE;
}
*/

BOOL cProcessMessage(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2)
{
    int rtn = TRUE, x, y;

        /* --------- process messages that a window sends to the
            system itself ---------- */
        switch (msg)    {
/*
            case STOP:
				StopMsg();
                break;
*/
            /* ------- clock messages --------- */
		/*
            case CAPTURE_CLOCK:
				if (Cwnd == NULL)
	                set_timer(clocktimer, 0);
				wnd->PrevClock = Cwnd;
                Cwnd = wnd;
                break;
            case RELEASE_CLOCK:
                Cwnd = wnd->PrevClock;
				if (Cwnd == NULL)
	                disable_timer(clocktimer);
                break;
		*/
            /* -------- keyboard messages ------- */
		/*
            case KEYBOARD_CURSOR:
                if (wnd == NULL)
                    cursor((int)p1, (int)p2);
                else if (wnd == inFocus)
                    cursor(GetClientLeft(wnd)+(int)p1,
                                GetClientTop(wnd)+(int)p2);
                break;
		*/
		/*
            case CAPTURE_KEYBOARD:
                if (p2)
                    ((WINDOW)p2)->PrevKeyboard=CaptureKeyboard;
                else
                    wnd->PrevKeyboard = CaptureKeyboard;
                CaptureKeyboard = wnd;
                NoChildCaptureKeyboard = (int)p1;
                break;
            case RELEASE_KEYBOARD:
				if (wnd != NULL)	{
					if (CaptureKeyboard == wnd || (int)p1)
	                	CaptureKeyboard = wnd->PrevKeyboard;
					else	{
						WINDOW twnd = CaptureKeyboard;
						while (twnd != NULL)	{
							if (twnd->PrevKeyboard == wnd)	{
								twnd->PrevKeyboard = wnd->PrevKeyboard;
								break;
							}
							twnd = twnd->PrevKeyboard;
						}
						if (twnd == NULL)
							CaptureKeyboard = NULL;
					}
                	wnd->PrevKeyboard = NULL;
				}
				else
					CaptureKeyboard = NULL;
                NoChildCaptureKeyboard = FALSE;
                break;
		*/
		/*
            case CURRENT_KEYBOARD_CURSOR:
                curr_cursor(&x, &y);
                *(int*)p1 = x;
                *(int*)p2 = y;
                break;
            case SAVE_CURSOR:
                savecursor();
                break;
            case RESTORE_CURSOR:
                restorecursor();
                break;
            case HIDE_CURSOR:
                normalcursor();
                hidecursor();
                break;
            case SHOW_CURSOR:
                if (p1)
                    set_cursor_type(0x0106);
                else
                    set_cursor_type(0x0607);
                unhidecursor();
                break;
			case WAITKEYBOARD:
				waitforkeyboard();
				break;
				*/
            /* -------- mouse messages -------- */
		/*
			case RESET_MOUSE:
				resetmouse();
				set_mousetravel(0, SCREENWIDTH-1, 0, SCREENHEIGHT-1);
				break;
				*/
		/*
            case MOUSE_INSTALLED:
                rtn = mouse_installed();
                break;
			case MOUSE_TRAVEL:	{
				RECT rc;
				if (!p1)	{
        			rc.lf = rc.tp = 0;
        			rc.rt = SCREENWIDTH-1;
        			rc.bt = SCREENHEIGHT-1;
				}
				else 
					rc = *(RECT *)p1;
				set_mousetravel(rc.lf, rc.rt, rc.tp, rc.bt);
				break;
			}
            case SHOW_MOUSE:
                show_mousecursor();
                break;
            case HIDE_MOUSE:
                hide_mousecursor();
                break;
		*/
		/*
            case MOUSE_CURSOR:
                set_mouseposition((int)p1, (int)p2);
                break;
            case CURRENT_MOUSE_CURSOR:
                get_mouseposition((int*)p1,(int*)p2);
                break;
            case WAITMOUSE:
                waitformouse();
                break;
            case TESTMOUSE:
                rtn = mousebuttons();
                break;
		*/
		/*
            case CAPTURE_MOUSE:
                if (p2)
                    ((WINDOW)p2)->PrevMouse = CaptureMouse;
                else
                    wnd->PrevMouse = CaptureMouse;
                CaptureMouse = wnd;
                NoChildCaptureMouse = (int)p1;
                break;
            case RELEASE_MOUSE:
				if (wnd != NULL)	{
					if (CaptureMouse == wnd || (int)p1)
	                	CaptureMouse = wnd->PrevMouse;
					else	{
						WINDOW twnd = CaptureMouse;
						while (twnd != NULL)	{
							if (twnd->PrevMouse == wnd)	{
								twnd->PrevMouse = wnd->PrevMouse;
								break;
							}
							twnd = twnd->PrevMouse;
						}
						if (twnd == NULL)
							CaptureMouse = NULL;
					}
                	wnd->PrevMouse = NULL;
				}
				else
					CaptureMouse = NULL;
                NoChildCaptureMouse = FALSE;
                break;
		*/
            default:
                break;
        }

    return rtn;
}

/*
static RECT VisibleRect(WINDOW wnd)
{
	RECT rc = WindowRect(wnd);
	if (!TestAttribute(wnd, NOCLIP))	{
		WINDOW pwnd = GetParent(wnd);
		if (!pwnd)
			return rc;
		RECT prc;
		prc = ClientRect(pwnd);
		while (pwnd != NULL)	{
			if (TestAttribute(pwnd, NOCLIP))
				break;
			rc = subRectangle(rc, prc);
			if (!ValidRect(rc))
				break;
			if ((pwnd = GetParent(pwnd)) != NULL)
				prc = ClientRect(pwnd);
		}
	}
	return rc;
}
*/

/* ----- find window that mouse coordinates are in --- */
/*
static WINDOW inWindow(WINDOW wnd, int x, int y)
{
	WINDOW Hit = NULL;
	while (wnd != NULL)	{
		if (isVisible(wnd))	{
			WINDOW wnd1;
			RECT rc = VisibleRect(wnd);
			if (InsideRect(x, y, rc))
				Hit = wnd;
			if ((wnd1 = inWindow(LastWindow(wnd), x, y)) != NULL)
				Hit = wnd1;
			if (Hit != NULL)
				break;
		}
		wnd = PrevWindow(wnd);
	}
	return Hit;
}
*/

/*
static WINDOW MouseWindow(int x, int y)
{
    // ------ get the window in which a
                    mouse event occurred ------ 
    WINDOW Mwnd = inWindow(ApplicationWindow, x, y);
    // ---- process mouse captures ----- 
    if (CaptureMouse != NULL)	{
        if (NoChildCaptureMouse ||
				Mwnd == NULL 	||
					!isAncestor(Mwnd, CaptureMouse))
            Mwnd = CaptureMouse;
	}
	return Mwnd;
}
*/

/*
void handshake(void)
{
#if MSDOS
	handshaking++;
	dispatch_message();
	--handshaking;
#endif
}
*/

/* ---- dispatch messages to the message proc function ---- */
/*
void c_dispatch_message(MESSAGE ev_event, int ev_mx, int ev_my)
{
    WINDOW Mwnd, Kwnd;
        // ------ get the window in which a
                        keyboard event occurred ------ 
        Kwnd = inFocus;

        // ---- process keyboard captures ----- 
        if (CaptureKeyboard != NULL)
            if (Kwnd == NULL ||
                    NoChildCaptureKeyboard ||
						!isAncestor(Kwnd, CaptureKeyboard))
                Kwnd = CaptureKeyboard;

        // -------- send mouse and keyboard messages to the
            window that should get them -------- 
        switch (ev_event)    {
            case SHIFT_CHANGED:
            case KEYBOARD:
//              if (!handshaking)
	                SendMessage(Kwnd, ev_event, ev_mx, ev_my);
                break;
            case LEFT_BUTTON:
//              if (!handshaking)	{
                    Mwnd = MouseWindow(ev_mx, ev_my);
                	if (!CaptureMouse ||
                        	(!NoChildCaptureMouse &&
								isAncestor(Mwnd, CaptureMouse)))
                    	if (Mwnd != inFocus)
                        	SendMessage(Mwnd, SETFOCUS, TRUE, 0);
                	SendMessage(Mwnd, LEFT_BUTTON, ev_mx, ev_my);
//				}
                break;
            case BUTTON_RELEASED:
            case DOUBLE_CLICK:
            case RIGHT_BUTTON:
//				if (handshaking)
//					break;
            case MOUSE_MOVED:
		        Mwnd = MouseWindow(ev_mx, ev_my);
                SendMessage(Mwnd, ev_event, ev_mx, ev_my);
                break;
#if MSDOS	// FIXME add MK_FP
            case CLOCKTICK:
                SendMessage(Cwnd, ev_event,
                    (PARAM) MK_FP(ev_mx, ev_my), 0);
				break;
#endif
            default:
                break;
        }
}
*/
