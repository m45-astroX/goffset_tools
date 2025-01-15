
CC = gcc
CFLAGS = -Wall -O2
OBJS_CC = calcChiSq4GoffsetPG.o
OBJS_MCD = merge_g0_g6_chisq.o
LIBS = -lm

all : CALC_CHISQ_4_GOFFSETPG MERGE_G0_G6_CHISQ_DATA_4_GOFFSETPG

CALC_CHISQ_4_GOFFSETPG : $(OBJS_CC)
	$(CC) -o $@ $^ $(LIBS)

MERGE_G0_G6_CHISQ_DATA_4_GOFFSETPG : $(OBJS_MCD)
	$(CC) -o $@ $^ $(LIBS)

.c.o :
	$(CC) $(CFLAGS) -c $<

clean :
	rm -f $(OBJS_CC)
	rm -f $(OBJS_MCD)
	rm -f CALC_CHISQ_4_GOFFSETPG
	rm -f MERGE_G0_G6_CHISQ_DATA_4_GOFFSETPG
