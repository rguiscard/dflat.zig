#-------------------------------------------------------------------
#        D - F L A T   M A K E F I L E  -  GCC
#-------------------------------------------------------------------

SMALL=
FULL=

ifeq ($(SMALL),y)
PRGS = smallpad
else
PRGS = memopad huffc fixhelp memopad.hlp
endif

LIBS = libdflat.a

all: $(LIBS) $(PRGS)

elks:
	make -f Makefile.elks

clean:
	rm -f *.o *.a memopad smallpad huffc fixhelp memopad.hlp

ifeq ($(SMALL),y)
BUILDOPTS = -DBUILD_SMALL_DFLAT
endif

ifeq ($(FULL),y)
BUILDOPTS = -DBUILD_FULL_DFLAT
endif

AR = ar
CFLAGS += $(BUILDOPTS) -DMACOS=1
CFLAGS += -g
CFLAGS += -Wno-pointer-sign
CFLAGS += -Wno-compare-distinct-pointer-types
CFLAGS += -Wno-invalid-source-encoding

OBJS = memopad.o dialogs.o menus.o
memopad: $(OBJS) $(LIBS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS) -L. -ldflat

SMALLOBJS = smallpad.o
smallpad: $(SMALLOBJS) $(LIBS)
	$(CC) $(LDFLAGS) -o $@ $(SMALLOBJS) -L. -ldflat

CONSOBJS = cons.o runes.o kcp437.o
cons: $(CONSOBJS)
	$(CC) $(LDFLAGS) -o $@ $(CONSOBJS)

TTYOBJS = ttyinfo.o runes.o unikey.o tty.o
ttyinfo: $(TTYOBJS)
	$(CC) $(LDFLAGS) -o $@ $(TTYOBJS)

MATRIXOBJS = matrix.o tty.o tty-cp437.o runes.o kcp437.o
matrix: $(MATRIXOBJS)
	$(CC) $(LDFLAGS) -o $@ $(MATRIXOBJS)

TESTOBJS = test.o
test: $(TESTOBJS)
	$(CC) $(LDFLAGS) -o $@ $(TESTOBJS)

DFLATOBJS = \
    message.o keys.o \
    config.o dfalloc.o \
    window.o rect.o lists.o \
    normal.o applicat.o textbox.o \
    menubar.o menu.o popdown.o listbox.o \
    editbox.o editor.o \
    sysmenu.o \
    statbar.o

ifneq ($(SMALL),y)
DFLATOBJS += \
    dialbox.o msgbox.o \
    box.o text.o \
    button.o radio.o checkbox.o spinbutt.o \
    combobox.o slidebox.o \
    fileopen.o direct.o \
    pictbox.o calendar.o barchart.o \
    search.o clipbord.o \
    helpbox.o decomp.o \
    log.o \
    watch.o
endif

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
