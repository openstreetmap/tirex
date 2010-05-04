CFLAGS += -g -O2 -Wall -Wextra -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -I /usr/include/freetype2/ 
CXXFLAGS = $(CFLAGS) 
LDFLAGS=-lmapnik

backend-mapnik: renderd.o metatilehandler.o networklistener.o networkmessage.o networkrequest.o networkresponse.o debuggable.o requesthandler.o
	$(CXX) -o $@ $^ $(LDFLAGS) 

clean: 
	rm -f backend-mapnik *.o 

install:
	install -m 755 -g root -o root -d             $(DESTDIR)/usr/lib/tirex/backends/
	install -m 755 -g root -o root backend-mapnik $(DESTDIR)/usr/lib/tirex/backends/mapnik
