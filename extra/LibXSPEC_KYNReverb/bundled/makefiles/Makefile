OTHER_LIBS := \
		-L${LIBRARY_ROOT}
INCSFLAGS := \
		-I${INCLUDE_ROOT}/include -I${INCLUDE_ROOT}/include/XSFunctions \
			-I${INCLUDE_ROOT}/include/XSFunctions/Utilities

XSPEC := -lXSUtil -lXSFunctions -lXS

LDFLAGS := -lpthread $(OTHER_LIBS) -lcfitsio -lm -lz $(XSPEC)
CFLAGS := -Wall -fPIC

OBJS = xside.o xskynrefrev.o fft_reverberation.o xside_threads.o

kynrefrev: $(OBJS) 
		$(CC) $(CFLAGS) $(INCSFLAGS) $(OBJS) $(LDFLAGS) -shared -o $@ 

%.o: %.c
		$(CC) $(CFLAGS) $(INCSFLAGS) -c $< -o $@
