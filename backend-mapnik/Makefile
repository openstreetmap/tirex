INSTALLOPTS=-g root -o root
CFLAGS += -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64
CXXFLAGS = $(CFLAGS) `mapnik-config --cflags`
CXXFLAGS += -Wall -Wextra -pedantic -Wredundant-decls -Wdisabled-optimization -Wctor-dtor-privacy -Wnon-virtual-dtor -Woverloaded-virtual -Wsign-promo -Wold-style-cast
LDFLAGS= `mapnik-config --libs --ldflags --dep-libs`

backend-mapnik: renderd.o metatilehandler.o networklistener.o networkmessage.o networkrequest.o networkresponse.o debuggable.o requesthandler.o
	$(CXX) -o $@ $^ $(LDFLAGS)

clean:
	rm -f backend-mapnik *.o

install:
	install -m 755 ${INSTALLOPTS} -d             $(DESTDIR)/usr/lib/tirex/backends/
	install -m 755 ${INSTALLOPTS} backend-mapnik $(DESTDIR)/usr/lib/tirex/backends/mapnik
