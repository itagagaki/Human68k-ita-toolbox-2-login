# Makefile for ITA TOOLBOX #2 LOGIN

AS	= HAS.X -i $(INCLUDE)
LK	= hlk.x -x
CV      = -CV.X -r
CP      = cp
RM      = -rm -f

INCLUDE = $(HOME)/fish/include

DESTDIR   = A:/bin
BACKUPDIR = B:/login/0.6
RELEASE_ARCHIVE = LOGIN06
RELEASE_FILES = MANIFEST README ../NOTICE CHANGES login.1 login.x forever.1 forever.x passwd.5

EXTLIB = $(HOME)/fish/lib/ita.l

###

PROGRAM = login.x forever.x

###

.PHONY: all clean clobber install release backup

.TERMINAL: *.h *.s

%.r : %.x	; $(CV) $<
%.x : %.o	; $(LK) $< $(EXTLIB)
%.o : %.s	; $(AS) $<

###

all:: $(PROGRAM)

clean::

clobber:: clean
	$(RM) *.bak *.$$* *.o *.x

###

$(PROGRAM) : $(INCLUDE)/doscall.h $(INCLUDE)/chrcode.h $(EXTLIB)

include ../Makefile.sub

###
