INSTALLOPTS=-g root -o root
CFLAGS +=   -Wall -Wextra -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -I /usr/include/freetype2/ -DBOOST_FILESYSTEM_VERSION=2
CXXFLAGS = $(CFLAGS) 
LDFLAGS=-lmapnik -lboost_filesystem -licuuc -lboost_regex -lboost_system 

backend-mapnik: renderd.o metatilehandler.o networklistener.o networkmessage.o networkrequest.o networkresponse.o debuggable.o requesthandler.o
	$(CXX) -o $@ $^ $(LDFLAGS) 

clean: 
	rm -f backend-mapnik *.o 

install:
	install -m 755 ${INSTALLOPTS} -d             $(DESTDIR)/usr/lib/tirex/backends/
	install -m 755 ${INSTALLOPTS} backend-mapnik $(DESTDIR)/usr/lib/tirex/backends/mapnik
