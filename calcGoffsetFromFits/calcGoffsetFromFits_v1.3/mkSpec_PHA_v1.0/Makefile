
# 2024.08.02 v1.0 by Yuma Aoki (Kindai Univ.)

CC = gcc
CFLAGS = -Wall -O2
LIBS = -lcfitsio
OBJS = mkSpec_PHA.o

ifeq ($(ENV), Linux)
	INCLUDE = -I /usr/local/adsoft/cfitsio/3.420/include
	LDFLAGS = -L /usr/local/adsoft/cfitsio/3.420/lib
else
	INCLUDE = -I $(HEADAS)/include
	LDFLAGS = -L $(HEADAS)/lib -Wl,-rpath,$(HEADAS)/lib
endif

mkSpec_PHA : $(OBJS)
	$(CC) -o $@ $(OBJS) $(LDFLAGS) $(LIBS)

.c.o :
	$(CC) $(CFLAGS) $(INCLUDE) -c $<

clean : 
	rm -f mkSpec_PHA
	rm -f $(OBJS)
