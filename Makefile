#-------------------------------------------------------------------
#        D - F L A T   M A K E F I L E  -  GCC
#-------------------------------------------------------------------

PRGS = huffc fixhelp memopad.hlp

CC = zig cc

all: $(PRGS)

clean:
	rm -f *.o *.a memopad smallpad huffc fixhelp memopad.hlp
	rm -f memopad.com smallpad.com huffc.com fixhelp.com

BUILDOPTS = -DBUILD_FULL_DFLAT

AR = ar
CFLAGS += $(BUILDOPTS) -DMACOS=1
CFLAGS += -g
CFLAGS += -Wno-pointer-sign
CFLAGS += -Wno-compare-distinct-pointer-types
CFLAGS += -Wno-invalid-source-encoding

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

fixhelp: fixhelp.o decomp.o
	$(CC) $(LDFLAGS) -o $@ $^

memopad.hlp: memopad.txt huffc fixhelp
	./huffc memopad.txt memopad.hlp
	./fixhelp memopad
