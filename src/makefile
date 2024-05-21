
# Directory containing tcl.h
tcl_header_directory = /usr/include/tcl8.6

# Root of the source filename (no extension)
rootname = tcladu

# Output shared object (and package, and SWIG module) name (no extension)
#
# This will also be the namespace exported by the package
#
# Naming convention:
#   1. Can not start with a capital letter
#   2. Can not start or end with numbers
package_name = tcladu

# See the package man page for version number requirements:
# https://www.tcl-lang.org/man/tcl/TclCmd/package.htm
#
# Use four digits: major.minor.patch.candidate
version = 1.1.3.3

# Archive name
# {appname}-{version}-{OS}-{architecture}.{extension}
tgz_name = $(package_name)-$(version)-linux-x64.tar.gz

########################## Test parameters ###########################

# Serial numbers
adu100_sn_1 = B02597

####################### Installation settings ########################

# The directory with the rest of your Tcl packages
system_package_directory = /usr/share/tcltk

###################### Done with configuration #######################

# SWIG flags
#
# Make a tcl interface
SFLAGS = -tcl

# Provide procedures in a namespace
SFLAGS += -prefix $(package_name) -namespace

# Specify a module name
SFLAGS += -module $(package_name)

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

package_dir = ../package/$(package_name)
package_files = $(package_name).so
package_files += $(package_name).tcl
package_files += pkgIndex.tcl
package_file_paths = $(addprefix $(package_dir)/, $(package_files))

installation_directory = $(system_package_directory)/$(package_name)$(version)

usage_text_width = 20
indent_text_width = 15
target_text_width = 15

# All these printf statements look confusing, but the idea here is to
# separate the layout from the content.  Always use the same printf
# line with a continuation character at the end.  Put your content on
# the next line.

# Default target.
help:
	@echo "Makefile for $(package_name)"
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
          "(sudo) make" "install" \
          "Install package into $(installation_directory)"
	@printf "%$(indent_text_width)s %-$(target_text_width)s %s\n" \
          "make" "clean" \
          "Remove generated files"

.PHONY: all
all: shared pkgIndex.tcl $(package_file_paths) tgz

$(package_dir)/%: %
	mkdir -p $(package_dir)
	cp $< $@
	@echo "** Copied $< package version $(version) to $(package_dir)"

.PHONY: tgz
tgz: ../package/$(tgz_name)
../package/$(tgz_name): $(package_file_paths)
	cd ../package; tar -czvf $(tgz_name) $(package_name)

.PHONY: wrapper
wrapper: $(rootname)_wrap.c

objects: $(OBJ)

shared: $(package_name).so
$(package_name).so: $(OBJ)
	$(CC) -shared $^ -o $@ $(LFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -o $@ $<

# Make a wrapper from an interface description
%_wrap.c: %.i
	swig $(SFLAGS) -pkgversion $(version) -o $@ $<

.PHONY: test
test:
	tclsh ../test/test.tcl -n $(package_name) -v $(version) -sn1 $(adu100_sn_1)

.PHONY: install
# Use rsync here to avoid problems with cp not overwriting files that
# already exist.
install:
	mkdir -p $(installation_directory)
	rsync -av $(package_dir)/ $(installation_directory)

# Display compiler version information.
gccversion :
	@$(CC) --version

# Create the package script
package.tcl:
	@echo "pkg_mkIndex -verbose . $(package_name).so $(package_name).tcl" > $@

pkgIndex.tcl: $(package_name).so $(package_name).tcl package.tcl
	tclsh package.tcl

clean:
	rm -f *_wrap.c
	rm -f *.o
	rm -f *.so
	rm -f pkgIndex.tcl
	rm -f package.tcl
	rm -rf $(package_dir)
	rm -f ../package/*.tar.gz
