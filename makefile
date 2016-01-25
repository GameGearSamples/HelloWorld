CC = wla-z80
CFLAGS = -o
LD = wlalink
LDFLAGS = -vds

SFILES = HelloGameGear.asm
IFILES =
OFILES = HelloGameGear.o
OUT = HelloWorld.gg

all: $(OFILES) makefile
	echo [objects] > linkfile
	echo $(OFILES) >> linkfile
	$(LD) $(LDFLAGS) linkfile $(OUT)

%.o: %.asm
	$(CC) $(CFLAGS) $< $@


$(OFILES): $(HFILES)

clean:
	rm -f $(OFILES) core *~ *.sym linkfile $(OUT)
