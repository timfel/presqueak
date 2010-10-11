APP := PreSqueak
EXEC := pre-squeak
SRC := pre-squeak.c
LIBS := -lSDL -lGLESv2 -lpdl -lm -lpthread
OUTFILE := pre-squeak

# Set the device specific compiler options. By default, a binary that
# will run on both Pre and Pixi will be built. These option only need to be
# set for a particular device if more performance is necessary.
ifdef PALMDEVICE
	ifeq ($(PALMDEVICE),pre)
		DEVICEOPTS="-mcpu=cortex-a8 -mfpu=neon -mfloat-abi=softfp"
	else
		DEVICEOPTS="-mcpu=arm1136jf-s -mfpu=vfp -mfloat-abi=softfp"
	endif
endif

BUILDDIR := org.bithug.palm.squeak

CC := gcc
INCLUDEDIR := /usr/local/include
CPPFLAGS := -I$(INCLUDEDIR) -I$(INCLUDEDIR)/SDL -I/usr/include
LDFLAGS := -L/usr/local/lib -L/usr/lib -Wl,--allow-shlib-undefined
SRCDIR := src
###################################

default: all

$(BUILDDIR):
	@mkdir -p $(BUILDDIR)

$(BUILDDIR)/squeakvm: $(BUILDDIR) $(SRCDIR)/squeakvm
	mkdir $(SRCDIR)/squeakvm/bld
	cd $(SRCDIR)/squeakvm/bld;                            \
		../platforms/unix/cmake/configure --prefix=$(BUILDDIR); \
		make install
	mv $(SRCDIR)/squeakvm/bld/* $(BUILDDIR)

$(BUILDDIR)/sdlvnc: $(BUILDDIR) $(SRCDIR)/sdlvnc/autogen.sh
	cd $(SRCDIR)/sdlvnc;  \
		./autogen.sh;     \
		./configure;      \
		make
	cp $(SRCDIR)/sdlvnc/sdlvnc $(BUILDDIR)/sdlvnc

$(BUILDDIR)/$(OUTFILE): $(BUILDDIR) $(SRCDIR)/$(SRC)
	$(CC) $(DEVICEOPTS) $(CPPFLAGS) $(LDFLAGS) $(LIBS) -o $(BUILDDIR)/$(OUTFILE) $(SRCDIR)/$(SRC)

all: $(BUILDDIR) $(BUILDDIR)/sdlvnc $(BUILDDIR)/squeakvm $(BUILDDIR)/$(OUTFILE)
	$(CC) $(DEVICEOPTS) $(CPPFLAGS) $(LDFLAGS) $(LIBS) -o $(BUILDDIR)/$(OUTFILE) $(SRCDIR)/$(SRC)

clean:
	rm -rf $(BUILDDIR)
	rm -rf $(SRCDIR)/squeakvm/bld

package: all
	cp $(SRCDIR)/appinfo.json $(BUILDDIR)/
	cp $(SRCDIR)/squeak.bmp $(BUILDDIR)/
	echo "filemode.755=$(OUTFILE)" > $(BUILDDIR)/package.properties
	echo "filemode.755=squeak" > $(BUILDDIR)/package.properties
	echo "filemode.755=squeakvm" > $(BUILDDIR)/package.properties
	echo "filemode.755=squeak.sh" > $(BUILDDIR)/package.properties
	echo "filemode.755=sdlvnc" > $(BUILDDIR)/package.properties
	palm-package $(BUILDDIR)

