APP := PreSqueak
EXEC := pre-squeak
SRC := pre-squeak.c
LIBS := -lSDL -lGLESv2 -lpdl -lm -lpthread
OUTFILE := pre-squeak

ifndef PalmPDK
  PalmPDK := $(strip $(dir $(realpath $(shell which pdk-device-install))))
  PalmPDK := $(realpath $(PalmPDK)/..)
endif

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

BUILDDIR := bld

BINDIR := $(PalmPDK)/arm-gcc/bin

CC := $(BINDIR)/arm-none-linux-gnueabi-gcc
ARCH :=
SYSROOT := $(PalmPDK)/arm-gcc/sysroot
INCLUDEDIR := $(PalmPDK)/include
LIBDIR := $(PalmPDK)/device/lib
CPPFLAGS := -I$(INCLUDEDIR) -I$(INCLUDEDIR)/SDL --sysroot=$(SYSROOT)
LDFLAGS := -L$(LIBDIR) -Wl,--allow-shlib-undefined
SRCDIR := src
###################################

$(BUILDDIR):
	@mkdir -p $(BUILDDIR)

$(BUILDDIR)/squeak: $(BUILDDIR) $(SRCDIR)/squeakvm
	mkdir $(SRCDIR)/squeakvm/bld
	cd $(SRCDIR)/squeakvm/bld;                       \
		../unix/cmake/configure --prefix=$(BUILDDIR) \
		make install

$(BUILDDIR)/sdlvnc: $(BUILDDIR) $(SRCDIR)/sdlvnc/autogen.sh
	cd $(SRCDIR)/sdlvnc;  \
		./autogen.sh      \
		./configure       \
		make
		cp src/sdlvnc $(BUILDDIR)/sdlvnc

all: $(BUILDDIR) $(BUILDDIR)/sdlvnc $(BUILDDIR)/squeak $(BUILDDIR)/$(OUTFILE)
	$(CC) $(DEVICEOPTS) $(CPPFLAGS) $(LDFLAGS) $(LIBS) -o $(BUILDDIR)/$(OUTFILE) $(SRCDIR)/$(SRC)

$(BUILDDIR)/$(OUTFILE): $(BUILDDIR) $(SRCDIR)/$(SRC)
	$(CC) $(DEVICEOPTS) $(CPPFLAGS) $(LDFLAGS) $(LIBS) -o $(BUILDDIR)/$(OUTFILE) $(SRCDIR)/$(SRC)

