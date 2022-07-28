/* ----------- keys.h ------------ */

#ifndef KEYS_H
#define KEYS_H

#include "unikey.h"
#define RUBOUT        8
#define BELL          7
#define ESC          27

#define F1          kF1
#define F2          kF2
#define F3          kF3
#define F4          kF4
#define F10         kF10

#define HOME        kHome
#define UP          kUpArrow
#define PGUP        kPageUp
#define BS          kLeftArrow
#define FWD         kRightArrow
#define END         kEnd
#define DN          kDownArrow
#define PGDN        kPageDown
#define INS         kInsert
//#define DEL         kDelete
#define DEL         127

#define ALT_A       kAltA
#define ALT_B       kAltB
#define ALT_C       kAltC
#define ALT_D       kAltD
#define ALT_E       kAltE
#define ALT_F       kAltF
#define ALT_G       kAltG
#define ALT_H       kAltH
#define ALT_I       kAltI
#define ALT_J       kAltJ
#define ALT_K       kAltK
#define ALT_L       kAltL
#define ALT_M       kAltM
#define ALT_N       kAltN
#define ALT_O       kAltO
#define ALT_P       kAltP
#define ALT_Q       kAltQ
#define ALT_R       kAltR
#define ALT_S       kAltS
#define ALT_T       kAltT
#define ALT_U       kAltU
#define ALT_V       kAltV
#define ALT_W       kAltW
#define ALT_X       kAltX
#define ALT_Y       kAltY
#define ALT_Z       kAltZ

#define ALT_F4      kAltF4
#define ALT_F6      kAltF6

#define F5          kF5
#define F6          kF6
#define F7          kF7
#define F8          kF8
#define F9          kF9
#define F10         kF10

/* map unused keys outside our private use range starting at 0xF200 FIXME */
#define CTRL_INS    0xF200
#define CTRL_HOME   0xF201
#define CTRL_END    0xF202
#define CTRL_PGUP   0xF203
#define CTRL_PGDN   0xF204
#define CTRL_FWD    0xF205
#define CTRL_BS     0xF206
#define CTRL_FIVE   0xF207
#define CTRL_F4     0xF208

#define SHIFT_DEL   0xF210
#define SHIFT_INS   0xF211
#define SHIFT_HT    0xF212
#define SHIFT_F8    0xF213

#define ALT_HYPHEN  0xF220
#define ALT_BS      0xF221

#if 0
#define ALT_BS      (197+OFFSET)
#define ALT_DEL     (184+OFFSET)
#define SHIFT_DEL   (198+OFFSET)
#define CTRL_INS    (186+OFFSET)
#define SHIFT_INS   (185+OFFSET)
#define CTRL_F1     (222+OFFSET)
#define CTRL_F2     (223+OFFSET)
#define CTRL_F3     (224+OFFSET)
#define CTRL_F5     (226+OFFSET)
#define CTRL_F6     (227+OFFSET)
#define CTRL_F7     (228+OFFSET)
#define CTRL_F8     (229+OFFSET)
#define CTRL_F9     (230+OFFSET)
#define CTRL_F10    (231+OFFSET)
#define ALT_F1      (232+OFFSET)
#define ALT_F2      (233+OFFSET)
#define ALT_F3      (234+OFFSET)
#define ALT_F5      (236+OFFSET)
#define ALT_F7      (238+OFFSET)
#define ALT_F8      (239+OFFSET)
#define ALT_F9      (240+OFFSET)
#define ALT_F10     (241+OFFSET)
#define ALT_1      (0xf8+OFFSET)
#define ALT_2      (0xf9+OFFSET)
#define ALT_3      (0xfa+OFFSET)
#define ALT_4      (0xfb+OFFSET)
#define ALT_5      (0xfc+OFFSET)
#define ALT_6      (0xfd+OFFSET)
#define ALT_7      (0xfe +OFFSET)
#define ALT_8      (0xff+OFFSET)
#define ALT_9      (0x80+OFFSET)
#define ALT_0      (0x81+OFFSET)
#endif

#define RIGHTSHIFT 0x01     //FIXME not implemented
#define LEFTSHIFT  0x02
#define CTRLKEY    0x04
#define ALTKEY     0x08
#define SCROLLLOCK 0x10
#define NUMLOCK    0x20
#define CAPSLOCK   0x40
#define INSERTKEY  0x80

#define CTRL_A 1
#define CTRL_B 2
#define CTRL_C 3
#define CTRL_D 4
#define CTRL_E 5
#define CTRL_F 6
#define CTRL_G 7
#define CTRL_H 8
#define CTRL_I 9
#define CTRL_J 10
#define CTRL_K 11
#define CTRL_L 12
#define CTRL_M 13
#define CTRL_N 14
#define CTRL_O 15
#define CTRL_P 16
#define CTRL_Q 17
#define CTRL_R 18
#define CTRL_S 19
#define CTRL_T 20
#define CTRL_U 21
#define CTRL_V 22
#define CTRL_W 23
#define CTRL_X 24
#define CTRL_Y 25
#define CTRL_Z 26

struct keys {
    int keycode;
    char *keylabel;
};
extern struct keys keys[];

#endif
