
# 2024.08.02 v1.0 by Yuma Aoki (Kindai Univ.)

CC = gcc
CFLAGS = -Wall -O2
LIBS = -lcfitsio
OBJS = mkSpec_PHASSUM_GOODGRADE.o

ifeq ($(ENV), Linux)
	INCLUDE = -I /usr/local/adsoft/cfitsio/3.420/include
	LDFLAGS = -L /usr/local/adsoft/cfitsio/3.420/lib
else
	INCLUDE = -I $(HEADAS)/include
	LDFLAGS = -L $(HEADAS)/lib -Wl,-rpath,$(HEADAS)/lib
endif

mkSpec_PHASSUM_GOODGRADE : $(OBJS)
	$(CC) -o $@ $(OBJS) $(LDFLAGS) $(LIBS)

.c.o :
	$(CC) $(CFLAGS) $(INCLUDE) -c $<

clean : 
	rm -f mkSpec_PHASSUM_GOODGRADE
	rm -f $(OBJS)
