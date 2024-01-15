
# Directory containing tcl.h
tcl_header_directory = /usr/include/tcl8.6

# Root of the source filename (no extension)
rootname = adutcl

version = 1.0

###################### Done with configuration #######################

# SWIG flags
#
# Make a tcl interface
SFLAGS = -tcl

# Provide procedures in a namespace
SFLAGS += -prefix adu -namespace

# C compiler
CC = gcc

# -fpic -- Make position-independent code for shared libraries
CFLAGS = -fpic

# -c -- Produce compiled code only -- no linking
CFLAGS += -c

# Include the directory containing tcl.h
CFLAGS += -I$(tcl_header_directory)

CFLAGS += -O2 -std=c99 -Wall -lusb-1.0

# Specify the path to the libusb-1.0 shared object library
LFLAGS = -L/usr/lib/x86_64-linux-gnu -lusb-1.0

# Instruct the linker to use a specific shared library location
#
# https://gcc.gnu.org/onlinedocs/gcc-3.2/gcc/Link-Options.html#Link%20Options
LFLAGS +=  -Xlinker -rpath /usr/lib/x86_64-linux-gnu

OBJ = $(rootname).o
OBJ += $(rootname)_wrap.o

package_dir = ../package/$(rootname)
package_files = $(rootname).so
package_files += pkgIndex.tcl
package_file_paths = $(addprefix $(package_dir)/, $(package_files))

usage_text_width = 20
indent_text_width = 7
target_text_width = 15

# All these printf statements look confusing, but the idea here is to
# separate the layout from the content.  Always use the same printf
# line with a continuation character at the end.  Put your content on
# the next line.

# Default target.
help:
	@echo "Makefile for $(rootname)"
	@printf "%$(indent_text_width)s %-$(target_text_width)s %s\n" \
          "make" "gccversion" \
          "Show the gcc version"
	@printf "%$(indent_text_width)s %-$(target_text_width)s %s\n" \
          "make" "wrapper" \
          "Make the wrapper with SWIG"
	@printf "%$(indent_text_width)s %-$(target_text_width)s %s\n" \
          "make" "objects" \
          "Make object files"
	@printf "%$(indent_text_width)s %-$(target_text_width)s %s\n" \
          "make" "shared" \
          "Make shared object files"
	@printf "%$(indent_text_width)s %-$(target_text_width)s %s\n" \
          "make" "all" \
          "Make everything"
	@printf "%$(indent_text_width)s %-$(target_text_width)s %s\n" \
          "make" "test" \
          "Test package"
	@printf "%$(indent_text_width)s %-$(target_text_width)s %s\n" \
          "make" "clean" \
          "Remove generated files"

.PHONY: all
all: shared pkgIndex.tcl $(package_file_paths)

$(package_dir)/%: %
	mkdir -p $(package_dir)
	cp $< $@

.PHONY: wrapper
wrapper: $(rootname)_wrap.c

objects: $(OBJ)

shared: $(rootname).so
$(rootname).so: $(OBJ)
	$(CC) -shared $^ -o $@ $(LFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -o $@ $<

# Make a wrapper from an interface description
%_wrap.c: %.i
	swig $(SFLAGS) -pkgversion $(version) -o $@ $<

.PHONY: test
test:
	tclsh ../test/test.tcl -v $(version)

# Display compiler version information.
gccversion :
	@$(CC) --version

pkgIndex.tcl: $(rootname).so
	tclsh package.tcl

clean:
	rm -f *_wrap.c
	rm -f *.o
	rm -f *.so
	rm -f pkgIndex.tcl
	rm -rf $(package_dir)
