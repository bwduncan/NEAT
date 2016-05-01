#----------------------------------------------------------------
# Revised Makefile (19/02/2014 PS)
# How to call:
# calling as normal
#     > make
# will trigger the default compiler options which include optimisation.
#
# You can now also call using
#     > make CO=debug
# for extra warnings, gprof and gdb output, exception trapping
# at runtime, and bounds-checking.
# This option is slow (about 2x slower than make all)
#
#     > make CO=debug2, debug3, pedantic
# offer further levels of checks in case of problems
#
#     > make new
# simply calls clean then all to force a re-build.
#
#     > (sudo) make install
# places the files in the standard UNIX directories.
#
# I have also included similar options for ifort. Since I have
# the compiler here, and it is potentially significantly faster,
# it may be useful when it comes time to do science.
#
#----------------------------------------------------------------

FC=gfortran
LD=gfortran
PREFIX=/usr
FFLAGS+=-cpp -DPREFIX=\"${PREFIX}\"
LDFLAGS+=
MANDIR=${DESTDIR}${PREFIX}/share/man/man1

ifeq ($(FC),gfortran)
    FFLAGS += -ffree-line-length-0 -Jsource/ -fopenmp
  ifeq ($(CO),debug)
    FFLAGS += -fbounds-check -Wall -Wuninitialized -DCO=\"${CO}\" #-ffpe-trap=zero,overflow,invalid,underflow,denormal
  else ifeq ($(CO),debug2)
    FFLAGS += -g -pg -fbounds-check -Wall -Wuninitialized -DCO=\"${CO}\" #-ffpe-trap=zero,overflow,invalid,underflow,denormal
  else ifeq ($(CO),debug3)
    FFLAGS += -g -pg -fbounds-check -Wall -Wuninitialized -ffpe-trap=zero,overflow,invalid,underflow,denormal -fbacktrace -fcheck=all -DCO=\"${CO}\" -DDEBUG=\"DEBUG\"
  else ifeq ($(CO),pedantic)
    FFLAGS += -g -pg -fbounds-check -Wall -Wuninitialized -Werror -pedantic -ffpe-trap=zero,overflow,invalid,underflow,denormal -DCO=\"${CO}\" -DDEBUG=\"DEBUG\"
  else
    FFLAGS += -O3 -fno-backtrace
  endif
endif

ifeq ($(FC),ifort)
  FFLAGS += -module source/ -openmp
  LD=ifort
  ifeq ($(CO),debug)
    FFLAGS += -pg -g -check bounds -check uninit -warn all -warn nodeclarations -WB -zero -traceback -DCO=\"${CO}\" # -std
  else ifeq ($(CO),pedantic)
    FFLAGS += -pg -g -check bounds -check uninit -warn all -warn nodeclarations -WB -zero -traceback -std -DCO=\"${CO}\"
  else
    FFLAGS += -axavx -msse3 -O3 -ip -ipo # for today's CPUs
#    FFLAGS += -fast -tune pn4 # for older pentium 4
  endif
endif

.PHONY: all clean install uninstall

all: neat

new: clean all

%.o: %.f90
	$(FC) $(FFLAGS) $< -c -o $@

neat: source/types.o source/oii_diagnostics.o source/hydrogen.o source/extinction.o source/rec_lines.o source/helium.o source/equib_routines.o source/filereading.o source/abundances.o source/quicksort.o source/linefinder.o source/weights.o source/neat.o
	$(LD) $(LDFLAGS) $(FFLAGS) -o $@ $^

clean:
	rm -f neat source/*.o source/*.mod

install:
	test -e ${DESTDIR}${PREFIX}/share/neat || mkdir -p ${DESTDIR}${PREFIX}/share/neat
	test -e ${DESTDIR}${PREFIX}/share/doc/neat/examples || mkdir -p ${DESTDIR}${PREFIX}/share/doc/neat/examples
	test -e ${DESTDIR}${PREFIX}/bin || mkdir -p ${DESTDIR}${PREFIX}/bin
	test -e ${MANDIR} || mkdir -p ${MANDIR}
	install -m 644 Atomic-data/*.* ${DESTDIR}${PREFIX}/share/neat
	install -m 644 source/Ilines_levs ${DESTDIR}${PREFIX}/share/neat
	install -m 644 utilities/complete_line_list ${DESTDIR}${PREFIX}/share/neat
	install -m 644 utilities/plot.sh ${DESTDIR}${PREFIX}/share/neat
	install -m 644 config/default.cfg ${DESTDIR}${PREFIX}/share/neat
	install -m 644 example/* ${DESTDIR}${PREFIX}/share/doc/neat/examples
	install neat ${DESTDIR}${PREFIX}/bin
	install -m 644 man/neat.1 ${MANDIR}
	-test -e ${DESTDIR}${PREFIX}/share/bash-completion/completions && install -m 644 source/bashcompletion ${DESTDIR}${PREFIX}/share/bash-completion/completions/neat
	gzip -f ${MANDIR}/neat.1

uninstall:
	rm -rf ${DESTDIR}${PREFIX}/share/neat
	rm -f ${DESTDIR}${PREFIX}/bin/neat
	rm -f ${DESTDIR}${PREFIX}/share/bash-completion/completions/neat
	rm -f ${MANDIR}/neat.1.gz
