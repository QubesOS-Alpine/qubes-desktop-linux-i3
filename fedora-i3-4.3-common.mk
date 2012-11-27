UNAME=$(shell uname)
DEBUG=1
COVERAGE=0
INSTALL=install
FLEX=flex
BISON=bison
# Fedora changes begin
PREFIX=PUTINPREFIXHERE
SYSCONFDIR=PUTINSYSCONFDIRHERE
# Fedora changes end

# The escaping is absurd, but we need to escape for shell, sed, make, define
GIT_VERSION:="4.3 (2012-09-19, branch \\\"release-4.3\\\")"
VERSION:=4.3-1


MAJOR_VERSION := $(shell echo ${VERSION} | cut -d '.' -f 1)
MINOR_VERSION := $(shell echo ${VERSION} | cut -d '.' -f 2)
PATCH_VERSION := $(shell echo ${VERSION} | cut -d '-' -f 2)

ifeq ($(shell which pkg-config 2>/dev/null 1>/dev/null || echo 1),1)
$(error "pkg-config was not found")
endif

# An easier way to get CFLAGS and LDFLAGS falling back in case there's
# no pkg-config support for certain libraries.
#
# NOTE that you must not use a blank after comma when calling this:
#     $(call ldflags_for_lib name, fallback) # bad
#     $(call ldflags_for_lib name,fallback) # good
# Otherwise, the compiler will get -l foo instead of -lfoo
#
# We redirect stderr to /dev/null because pkg-config prints an error if support
# for gnome-config was enabled but gnome-config is not actually installed.
cflags_for_lib = $(shell pkg-config --silence-errors --cflags $(1) 2>/dev/null)
ldflags_for_lib = $(shell pkg-config --exists 2>/dev/null $(1) && pkg-config --libs $(1) 2>/dev/null || echo -l$(2))

# Fedora changes begin
CFLAGS += PUTINOPTFLAGSHERE -std=c99 -std=gnu99
CFLAGS += -IPUTININCLUDEDIRHERE
CFLAGS += -IPUTININCLUDEDIRHERE/libev
# Fedora changes end

# unused-function, unused-label, unused-variable are turned on by -Wall
# We don’t want unused-parameter because of the use of many callbacks
CFLAGS += -Wunused-value
CFLAGS += -Iinclude
CFLAGS += $(call cflags_for_lib, xcb-keysyms)
ifeq ($(shell pkg-config --exists xcb-util 2>/dev/null || echo 1),1)
CPPFLAGS += -DXCB_COMPAT
CFLAGS += $(call cflags_for_lib, xcb-atom)
CFLAGS += $(call cflags_for_lib, xcb-aux)
else
CFLAGS += $(call cflags_for_lib, xcb-util)
endif
CFLAGS += $(call cflags_for_lib, xcb-icccm)
CFLAGS += $(call cflags_for_lib, xcb-xinerama)
CFLAGS += $(call cflags_for_lib, xcb-randr)
CFLAGS += $(call cflags_for_lib, xcb)
CFLAGS += $(call cflags_for_lib, xcursor)
CFLAGS += $(call cflags_for_lib, x11)
CFLAGS += $(call cflags_for_lib, yajl)
CFLAGS += $(call cflags_for_lib, libev)
CFLAGS += $(call cflags_for_lib, libpcre)
CFLAGS += $(call cflags_for_lib, libstartup-notification-1.0)
CFLAGS += $(call cflags_for_lib, cairo)
CFLAGS += $(call cflags_for_lib, pango)

CPPFLAGS += -DI3_VERSION=\"${GIT_VERSION}\"
CPPFLAGS += -DMAJOR_VERSION=${MAJOR_VERSION}
CPPFLAGS += -DMINOR_VERSION=${MINOR_VERSION}
CPPFLAGS += -DPATCH_VERSION=${PATCH_VERSION}
CPPFLAGS += -DSYSCONFDIR=\"${SYSCONFDIR}\"
CPPFLAGS += -DPANGO_SUPPORT=1

ifeq ($(shell pkg-config --atleast-version=8.10 libpcre 2>/dev/null && echo 1),1)
CPPFLAGS += -DPCRE_HAS_UCP=1
endif

LIBS += -lm
LIBS += -lrt
LIBS += -L $(TOPDIR) -li3
LIBS += $(call ldflags_for_lib, xcb-event,xcb-event)
LIBS += $(call ldflags_for_lib, xcb-keysyms,xcb-keysyms)
ifeq ($(shell pkg-config --exists xcb-util 2>/dev/null || echo 1),1)
LIBS += $(call ldflags_for_lib, xcb-atom,xcb-atom)
LIBS += $(call ldflags_for_lib, xcb-aux,xcb-aux)
else
LIBS += $(call ldflags_for_lib, xcb-util)
endif
LIBS += $(call ldflags_for_lib, xcb-icccm,xcb-icccm)
LIBS += $(call ldflags_for_lib, xcb-xinerama,xcb-xinerama)
LIBS += $(call ldflags_for_lib, xcb-randr,xcb-randr)
LIBS += $(call ldflags_for_lib, xcb,xcb)
LIBS += $(call ldflags_for_lib, xcursor,Xcursor)
LIBS += $(call ldflags_for_lib, x11,X11)
LIBS += $(call ldflags_for_lib, yajl,yajl)
LIBS += $(call ldflags_for_lib, libev,ev)
LIBS += $(call ldflags_for_lib, libpcre,pcre)
LIBS += $(call ldflags_for_lib, libstartup-notification-1.0,startup-notification-1)
LIBS += $(call ldflags_for_lib, cairo)
LIBS += $(call ldflags_for_lib, pango)
LIBS += $(call ldflags_for_lib, pangocairo)


# Please test if -Wl,--as-needed works on your platform and send me a patch.
# it is known not to work on Darwin (Mac OS X)
ifneq (,$(filter Linux GNU GNU/%, $(UNAME)))
LDFLAGS += -Wl,--as-needed
endif

ifeq ($(UNAME),NetBSD)
# We need -idirafter instead of -I to prefer the system’s iconv over GNU libiconv
CFLAGS += -idirafter /usr/pkg/include
LDFLAGS += -Wl,-rpath,/usr/local/lib -Wl,-rpath,/usr/pkg/lib
endif

ifeq ($(UNAME),OpenBSD)
CFLAGS += -I${X11BASE}/include
LIBS += -liconv
LDFLAGS += -L${X11BASE}/lib
endif

ifeq ($(UNAME),FreeBSD)
LIBS += -liconv
endif

ifeq ($(UNAME),Darwin)
LIBS += -liconv
endif

# Fallback for libyajl 1 which did not include yajl_version.h. We need
# YAJL_MAJOR from that file to decide which code path should be used.
CFLAGS += -idirafter $(TOPDIR)/yajl-fallback

ifneq (,$(filter Linux GNU GNU/%, $(UNAME)))
CPPFLAGS += -D_GNU_SOURCE
endif

# Fedora changes - removed DEBUG and COVERAGE

# Don’t print command lines which are run
.SILENT:

# Always remake the following targets
.PHONY: install clean dist distclean


