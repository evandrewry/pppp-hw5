X10C=${X10_HOME}/bin/x10c++

FLAGS=-VERBOSE_CHECKS=TRUE -O -NO_CHECKS -noassert -cxx-prearg -O2

TARBALL=${USER}_hw5.tar.gz

SRCS=CC.x10 ReadersWriterLock.x10 Matcher.x10
TURNIN=$(SRCS) 

EXES=$(SRCS:.x10=)

all: $(EXES)

.SUFFIXES:
.SUFFIXES: .x10

Main: CC

.x10:
		$(X10C) $(FLAGS) -o $@ $@.x10

turnin: $(TARBALL)

$(TARBALL): $(TURNIN)
		tar cvfz $(TARBALL) $(TURNIN)

clean:
		rm -f $(EXES) *.h *.cc $(TARBALL)
