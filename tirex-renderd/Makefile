CFLAGS += -g -O2 -Wall -Wextra -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -I /usr/include/freetype2/ 
CXXFLAGS = $(CFLAGS) 
LDFLAGS=-lmapnik -lboost_program_options-mt

tirex-renderd: mapnikwrapper.o renderd.o metatilehandler.o networklistener.o networkmessage.o networkrequest.o networkresponse.o debuggable.o requesthandler.o
	$(CXX) -o $@ $^ $(LDFLAGS) 

clean: 
	rm -f tirex-renderd *.o 

install:
	install -m 755 -g root -o root -d $(DESTDIR)/usr/bin/
	install -m 755 -g root -o root tirex-renderd $(DESTDIR)/usr/bin/
