
CC = gcc
CFLAGS = -Wall -O2
OBJS = calcElectronCloudDiffusion_v0.1.cpp
LIBS = -lcfitsio

INCLUDE = -I $(HEADAS)/include
LDFLAGS = -L $(HEADAS)/lib

calElectDif : $(OBJS)
	$(CC) -o $@ $(CFLAGS) $(INCLUDE) $(LDFLAGS) $(LIBS) $(OBJS)
