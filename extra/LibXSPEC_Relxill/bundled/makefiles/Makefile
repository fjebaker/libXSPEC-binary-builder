CFLAGS ?= -Wall -O3 -std=c99 -fPIC
CXXFLAGS ?= -Wall -O3 -std=c++17 -fPIC

INCFLAGS = -I../destdir/include
LDFLAGS = -L../destdir/lib/ -lfftw3 -lcfitsio -lstdc++

OBJS := IonGradient.o LocalModel.o ModelDefinition.o PrimarySource.o Relbase.o \
	Relcache.o Rellp.o Relphysics.o Relprofile.o Relreturn_BlackBody.o \
	Relreturn_Corona.o Relreturn_Datastruct.o Relreturn_Table.o Relxill.o \
	Xillspec.o xspec_wrapper_lmodels.o donthcomp.o reltable.o relutility.o \
	writeOutfiles.o xilltable.o

relxill: $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(INCFLAGS) $(OBJS) -shared -o $@

%.o: %.c
	$(CC) $(CFLAGS) $(INCFLAGS) -c $< -o $@

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCFLAGS) -c $< -o $@

.PHONY: clean
clean:
	rm -f $(OBJS)

