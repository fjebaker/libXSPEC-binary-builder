CFLAGS ?= -Wall -O3 -std=c99 -fPIC
CXXFLAGS ?= -Wall -O3 -std=c++17 -fPIC

INCFLAGS = -I${INCLUDE_ROOT}/include
LDFLAGS = -L${LIBRARY_ROOT} \
		  -lfftw3 -lcfitsio -lstdc++

OBJS :=  IonGradient.o LocalModel.o ModelParams.o Relbase.o Relcache.o \
	Rellp.o Relmodels.o Relprofile.o Relreturn_BlackBody.o Relreturn_Corona.o \
	Relxill.o Xillspec.o donthcomp.o relphysics.o relreturn_datastruct.o \
	relreturn_table.o reltable.o relutility.o writeOutfiles.o xilltable.o \
	xspec_wrapper_lmodels.o

relxill: $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(INCFLAGS) $(OBJS) -shared -o $@

%.o: %.c
	$(CC) $(CFLAGS) $(INCFLAGS) -c $< -o $@
	
%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCFLAGS) -c $< -o $@

.PHONY: clean
clean:
	rm -f $(OBJS)

