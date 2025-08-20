#-------------------------------------------------------------------
#        D - F L A T   M A K E F I L E  -  GCC
#-------------------------------------------------------------------

SMALL=
FULL=y

ifeq ($(SMALL),y)
PRGS = smallpad
else
PRGS = memopad huffc fixhelp memopad.hlp
endif

CC = zig cc
DFLAT_LIB = ./zig-out/lib/

LIBS = libdflat.a

all: $(PRGS)

elks:
	make -f Makefile.elks

clean:
	rm -f *.o *.a memopad smallpad huffc fixhelp memopad.hlp
	rm -f memopad.com smallpad.com huffc.com fixhelp.com

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
ifneq ($(COSMO),)
CFLAGS += -DCOSMO=1
endif

OBJS = memopad.o dialogs.o menus.o
memopad: $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS) -L${DFLAT_LIB} -ldflat
ifneq ($(COSMO),)
	$(OBJCOPY) -S -O binary $@ $@.com
endif

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

huffc: huffc.o htree.o
	$(CC) $(LDFLAGS) -o $@ $^
ifneq ($(COSMO),)
	$(OBJCOPY) -S -O binary $@ $@.com
endif

fixhelp: fixhelp.o decomp.o
	$(CC) $(LDFLAGS) -o $@ $^
ifneq ($(COSMO),)
	$(OBJCOPY) -S -O binary $@ $@.com
endif

memopad.hlp: memopad.txt huffc fixhelp
ifeq ($(COSMO),)
	./huffc memopad.txt memopad.hlp
	./fixhelp memopad
else
	./huffc.com memopad.txt memopad.hlp
	./fixhelp.com memopad
endif
