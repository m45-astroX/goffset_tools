
# 2023.12.15 v1.0 by Yuma Aoki

CC = gcc
CFLAGS = -Wall -O2
OBJS = make_goffsetMap32_v1.0.o
LIBS = -lcfitsio

INCLUDE = -I $(HEADAS)/include
LDFLAGS = -L $(HEADAS)/lib

make_goffsetMap32 : $(OBJS)
	$(CC) -o $@ $(OBJS) $(LDFLAGS) $(LIBS)

.c.o :
	$(CC) $(CFLAGS) $(INCLUDE) -c $<

clean : 
	rm -f make_goffsetMap32
	rm -f $(OBJS)
