CXX ?= g++
CXXFLAGS ?= -O3 -Wall -Wextra -fPIC -shared
DESTDIR ?=
PREFIX ?= /usr
LIBDIR ?= $(PREFIX)/lib/aarch64-linux-gnu

WAYFIRE_CFLAGS := $(shell pkg-config --cflags wayfire glesv2)
WAYFIRE_LIBS := $(shell pkg-config --libs wayfire glesv2) -lz -pthread

TARGET = libgta8-screenshot.so
SRCS = gta8-screenshot-plugin.cpp

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CXX) $(CXXFLAGS) $(WAYFIRE_CFLAGS) -I../../ -I/usr/include $(SRCS) -o $(TARGET) $(WAYFIRE_LIBS)

install: $(TARGET)
	install -d $(DESTDIR)$(LIBDIR)/wayfire
	install -m 755 $(TARGET) $(DESTDIR)$(LIBDIR)/wayfire/$(TARGET)

clean:
	rm -f $(TARGET)

.PHONY: all install clean
