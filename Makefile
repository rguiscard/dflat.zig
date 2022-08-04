#-------------------------------------------------------------------
#        D - F L A T   M A K E F I L E  -  GCC
#-------------------------------------------------------------------

AR = ar

PRGS = memopad huffc fixhelp memopad.hlp
LIBS = libdflat.a

all: $(LIBS) $(PRGS)

elks:
	make -f Makefile.elks

clean:
	rm -f *.o *.a memopad huffc fixhelp memopad.hlp

#  This macro builds the full D-Flat system with all options enabled.
#  Comment it out for a minimum system or selectively
#  comment out the #defines at the top of dflat.h.
FULL = -DBUILD_FULL_DFLAT

#------------------------------------------------
CFLAGS += $(FULL) -DMACOS=1 -c -g
CFLAGS += -Wno-pointer-sign
CFLAGS += -Wno-compare-distinct-pointer-types
CFLAGS += -Wno-invalid-source-encoding
#------------------------------------------------

OBJS = memopad.o dialogs.o menus.o

memopad: $(OBJS) $(LIBS)
	$(CC) $(LDFLAGS) -o memopad $(OBJS) -L. -ldflat

CONSOBJS = cons.o runes.o kcp437.o
cons: $(CONSOBJS)
	$(CC) $(LDFLAGS) -o cons $(CONSOBJS)

TTYOBJS = ttyinfo.o runes.o unikey.o tty.o
ttyinfo: $(TTYOBJS)
	$(CC) $(LDFLAGS) -o ttyinfo $(TTYOBJS)

MATRIXOBJS = matrix.o tty.o tty-cp437.o runes.o kcp437.o
matrix: $(MATRIXOBJS)
	$(CC) $(LDFLAGS) -o $@ $(MATRIXOBJS)

DFLATOBJS = \
TESTOBJS = test.o
test: $(TESTOBJS)
	$(CC) $(LDFLAGS) -o test $(TESTOBJS)

DFLATOBJS = \
    window.o textbox.o listbox.o                    \
    normal.o config.o menu.o menubar.o popdown.o    \
    rect.o applicat.o keys.o sysmenu.o editbox.o    \
    dialbox.o button.o fileopen.o msgbox.o          \
    helpbox.o log.o lists.o statbar.o decomp.o      \
    combobox.o pictbox.o calendar.o barchart.o      \
    clipbord.o search.o dfalloc.o checkbox.o        \
    text.o radio.o box.o spinbutt.o  watch.o        \
    slidebox.o direct.o editor.o message.o

DFLATOBJS += \
    video.o events-unix.o mouse-ansi.o console-unix.o \
    kcp437.o runes.o unikey.o tty.o tty-cp437.o runshell.o

$(LIBS): $(DFLATOBJS)
	$(AR) rcs $(LIBS) $(DFLATOBJS)

HUFFOBJS = huffc.o htree.o
huffc: $(HUFFOBJS)
	$(CC) $(LDFLAGS) -o $@ $(HUFFOBJS)

FIXHOBJS = fixhelp.o decomp.o
fixhelp: $(FIXHOBJS)
	$(CC) $(LDFLAGS) -o $@ $(FIXHOBJS)

memopad.hlp: memopad.txt huffc fixhelp
	./huffc memopad.txt memopad.hlp
	./fixhelp memopad
