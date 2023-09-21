#! A:/bin/MAKE.X -f
# Makefile for LOGIN

AS	= \usr\pds\HAS.X -l -i $(INCLUDE)
LK	= \usr\pds\hlk.x -x
CV      = -\bin\CV.X -r
INSTALL = copy
BACKUP  = A:\bin\COPYALL.X -t
CP      = copy
RM      = -\usr\local\bin\rm -f

INCLUDE = ../fish/include

DESTDIR   = A:\bin
BACKUPDIR = B:\login\0.4

EXTLIB = $(HOME)/fish/lib/ita.l

###

PROGRAMS = login.x forever.x

###

.PHONY: all clean clobber install backup

.TERMINAL: *.h *.s

%.r : %.x	; $(CV) $<
%.x : %.o	; $(LK) $< $(EXTLIB)
%.o : %.s	; $(AS) $<

###

all:: $(PROGRAMS)

clean::

clobber:: clean
	$(RM) *.bak *.$$* *.o *.x

###

$(PROGRAMS) : $(INCLUDE)/doscall.h $(INCLUDE)/chrcode.h $(EXTLIB)

install::
	$(INSTALL) login.x $(DESTDIR)

backup::
	$(BACKUP) *.* $(BACKUPDIR)

clean::
	$(RM) $(PROGRAMS)

###
