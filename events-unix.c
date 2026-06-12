/* UNIX event generation using termbox2 */

#define TB_IMPL
#include "termbox2.h"

#include "dflat.h"
#include "unikey.h"

int mouse_x, mouse_y;
int mouse_button;

int tb_to_dflat_key(struct tb_event *ev)
{
    uint32_t ch = ev->ch;
    uint16_t key = ev->key;
    uint8_t mod = ev->mod;

    if (ch) {
        if ((mod & TB_MOD_CTRL) && ch >= 'a' && ch <= 'z')
            return CTRL_A + (ch - 'a');
        if ((mod & TB_MOD_ALT)) {
            if (ch >= 'a' && ch <= 'z')
                return kAltA + (ch - 'a');
            if (ch >= 'A' && ch <= 'Z')
                return kAltA + (ch - 'A');
            if (ch >= '0' && ch <= '9')
                return kAlt0 + (ch - '0');
            if (ch == '-')
                return kAltA + ('z' - 'a' + 1);
        }
        if (ch >= ' ' && ch <= 0x7e)
            return (int)ch;
        if (ch == '\r')
            return '\r';
        if (ch <= 0x7f)
            return (int)ch;
        return 0;
    }
    switch (key) {
        case TB_KEY_BACKSPACE:
        case TB_KEY_BACKSPACE2: return kBackSpace;
        case TB_KEY_TAB: return kTab;
        case TB_KEY_ESC: return kEscKey;
        case TB_KEY_ENTER: return '\r';
        case TB_KEY_DELETE: return kDelete;
        case TB_KEY_HOME: return kHome;
        case TB_KEY_END: return kEnd;
        case TB_KEY_PGUP: return kPageUp;
        case TB_KEY_PGDN: return kPageDown;
        case TB_KEY_ARROW_LEFT: return kLeftArrow;
        case TB_KEY_ARROW_RIGHT: return kRightArrow;
        case TB_KEY_ARROW_UP: return kUpArrow;
        case TB_KEY_ARROW_DOWN: return kDownArrow;
        case TB_KEY_INSERT: return kInsert;
    }
    if (key >= TB_KEY_F1 && key <= TB_KEY_F1 + 11)
        return kF1 + (key - TB_KEY_F1);
    return 0;
}

/* ------ collect mouse, clock, and keyboard events ----- */
void collect_events(void)
{
    struct tb_event ev;

    while (tb_peek_event(&ev, 30) == TB_OK) {
        switch (ev.type) {
            case TB_EVENT_KEY:
                if (ev.ch == 0 && ev.key == 0)
                    break;
                {
                    int k = tb_to_dflat_key(&ev);
                    if (k != 0)
                        PostEvent(KEYBOARD, k, 0);
                }
                break;
            case TB_EVENT_MOUSE:
                switch (ev.key) {
                    case TB_KEY_MOUSE_LEFT:
                        if (ev.x < SCREENWIDTH && ev.y < SCREENHEIGHT - 1) {
                            PostEvent(LEFT_BUTTON, ev.x, ev.y);
                            mouse_x = ev.x;
                            mouse_y = ev.y;
                            mouse_button = 1;
                        }
                        break;
                    case TB_KEY_MOUSE_RELEASE:
                        PostEvent(BUTTON_RELEASED, ev.x, ev.y);
                        mouse_button = 0;
                        break;
                    case TB_KEY_MOUSE_RIGHT:
                        if (ev.x < SCREENWIDTH && ev.y < SCREENHEIGHT - 1)
                            PostEvent(RIGHT_BUTTON, ev.x, ev.y);
                        break;
                    case TB_KEY_MOUSE_WHEEL_UP:
                        PostEvent(KEYBOARD, UP, 0);
                        break;
                    case TB_KEY_MOUSE_WHEEL_DOWN:
                        PostEvent(KEYBOARD, DN, 0);
                        break;
                    default:
                        if (ev.x < SCREENWIDTH && ev.y < SCREENHEIGHT - 1)
                            PostEvent(MOUSE_MOVED, ev.x, ev.y);
                        mouse_x = ev.x;
                        mouse_y = ev.y;
                        break;
                }
                break;
            case TB_EVENT_RESIZE:
                if (tb_width() > 2 && tb_height() > 2) {
                    SCREENWIDTH = min(tb_width(), MAXCOLS - 1);
                    SCREENHEIGHT = tb_height() - 1;
                }
                break;
        }
    }
}
