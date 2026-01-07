
CC = gcc
CFLAGS = -Wall -O2
OBJS = calcChiSq4GoffsetPG.o
LIBS = -lm

CALC_CHISQ_4_GOFFSETPG : $(OBJS)
	$(CC) -o $@ $^ $(LIBS)

.c.o :
	$(CC) $(CFLAGS) -c $<

clean :
	rm -f $(OBJS)
	rm -f CALC_CHISQ_4_GOFFSETPG
