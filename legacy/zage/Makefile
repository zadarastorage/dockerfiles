LIB	=  -lpthread 
CFLAGS 	= -O -Wall -g -c $(INC)

CC	= g++

SRCS 	= zage.cpp 

OBJS	:= $(patsubst %.cpp,%.o,$(SRCS))

all:	zage

zage:	$(OBJS) 
	$(CC) -o zage $(OBJS) $(LIB)

clean:
	rm -rf *.o zage

.c.o:
	$(CC) $(CFLAGS) $<

.cpp.o:
	$(CC) $(CFLAGS) $<


# DO NOT DELETE
