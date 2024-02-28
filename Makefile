INSTALLOPTS=-g root -o root
build: Makefile.perl
	cd backend-mapnik; $(MAKE) $(MFLAGS)
	$(MAKE) -f Makefile.perl

Makefile.perl: Makefile.PL
	perl Makefile.PL PREFIX=/usr DESTDIR=$(DESTDIR) FIRST_MAKEFILE=Makefile.perl
	rm -f Makefile.perl.old

install-all: install install-example-map install-munin install-nagios

install-example-map:
	install -m 755 ${INSTALLOPTS} -d                              $(DESTDIR)/usr/share/tirex
	install -m 755 ${INSTALLOPTS} -d                              $(DESTDIR)/usr/share/tirex/example-map
	install -m 644 ${INSTALLOPTS} example-map/example.xml         $(DESTDIR)/usr/share/tirex/example-map
	install -m 644 ${INSTALLOPTS} example-map/ocean.*             $(DESTDIR)/usr/share/tirex/example-map
	install -m 644 ${INSTALLOPTS} example-map/README              $(DESTDIR)/usr/share/tirex/example-map
	install -m 755 ${INSTALLOPTS} -d                              $(DESTDIR)/etc/tirex/renderer/mapnik
	install -m 644 ${INSTALLOPTS} example-map/mapnik-example.conf $(DESTDIR)/etc/tirex/renderer/mapnik/example.conf

install-munin:
	install -m 755 ${INSTALLOPTS} -d                              $(DESTDIR)/usr/share/munin/plugins
	install -m 755 ${INSTALLOPTS} munin/*                         $(DESTDIR)/usr/share/munin/plugins

install-nagios:
	install -m 755 ${INSTALLOPTS} -d                              $(DESTDIR)/usr/lib/nagios/plugins
	install -m 755 ${INSTALLOPTS} -d                              $(DESTDIR)/etc/nagios/nrpe.d
	install -m 755 ${INSTALLOPTS} nagios/tirex*                   $(DESTDIR)/usr/lib/nagios/plugins
	install -m 644 ${INSTALLOPTS} nagios/cfg/*.cfg                $(DESTDIR)/etc/nagios/nrpe.d

install: build
	install -m 755 ${INSTALLOPTS} -d $(DESTDIR)/usr/bin/
	for program in bin/*; do \
	    install -m 755 ${INSTALLOPTS} $$program $(DESTDIR)/usr/bin/; \
    done
	install -m 755 ${INSTALLOPTS} -d                                       $(DESTDIR)/usr/libexec
	install -m 755 ${INSTALLOPTS} backends/test                            $(DESTDIR)/usr/libexec/tirex-backend-test
	install -m 755 ${INSTALLOPTS} backends/wms                             $(DESTDIR)/usr/libexec/tirex-backend-wms
	install -m 755 ${INSTALLOPTS} backends/tms                             $(DESTDIR)/usr/libexec/tirex-backend-tms
	install -m 755 ${INSTALLOPTS} backends/mapserver                       $(DESTDIR)/usr/libexec/tirex-backend-mapserver
	install -m 755 ${INSTALLOPTS} backends/openseamap                      $(DESTDIR)/usr/libexec/tirex-backend-openseamap
	install -m 755 ${INSTALLOPTS} -d                                       $(DESTDIR)/etc/tirex
	install -m 644 ${INSTALLOPTS} etc/tirex.conf.dist                      $(DESTDIR)/etc/tirex/tirex.conf
	install -m 755 ${INSTALLOPTS} -d                                       $(DESTDIR)/etc/tirex/renderer
	install -m 755 ${INSTALLOPTS} -d                                       $(DESTDIR)/etc/tirex/renderer/test
	install -m 644 ${INSTALLOPTS} etc/renderer/test.conf.dist              $(DESTDIR)/etc/tirex/renderer/test.conf
	install -m 644 ${INSTALLOPTS} etc/renderer/test/checkerboard.conf.dist $(DESTDIR)/etc/tirex/renderer/test/checkerboard.conf
	install -m 755 ${INSTALLOPTS} -d                                       $(DESTDIR)/etc/tirex/renderer/wms
	install -m 755 ${INSTALLOPTS} -d                                       $(DESTDIR)/etc/tirex/renderer/tms
	install -m 755 ${INSTALLOPTS} -d                                       $(DESTDIR)/etc/tirex/renderer/openseamap
	install -m 755 ${INSTALLOPTS} -d                                       $(DESTDIR)/etc/tirex/renderer/mapserver
	install -m 644 ${INSTALLOPTS} etc/renderer/wms.conf.dist               $(DESTDIR)/etc/tirex/renderer/wms.conf
	install -m 644 ${INSTALLOPTS} etc/renderer/tms.conf.dist               $(DESTDIR)/etc/tirex/renderer/tms.conf
	install -m 644 ${INSTALLOPTS} etc/renderer/openseamap.conf.dist        $(DESTDIR)/etc/tirex/renderer/openseamap.conf
	install -m 644 ${INSTALLOPTS} etc/renderer/mapserver.conf.dist         $(DESTDIR)/etc/tirex/renderer/mapserver.conf
	install -m 644 ${INSTALLOPTS} etc/renderer/wms/demowms.conf.dist       $(DESTDIR)/etc/tirex/renderer/wms/demowms.conf
	install -m 644 ${INSTALLOPTS} etc/renderer/tms/demotms.conf.dist       $(DESTDIR)/etc/tirex/renderer/tms/demotms.conf
	install -m 644 ${INSTALLOPTS} etc/renderer/openseamap/openseamap.conf.dist $(DESTDIR)/etc/tirex/renderer/openseamap/openseamap.conf
	install -m 644 ${INSTALLOPTS} etc/renderer/mapserver/msdemo.conf.dist  $(DESTDIR)/etc/tirex/renderer/mapserver/msdemo.conf
	install -m 644 ${INSTALLOPTS} etc/renderer/mapserver/msdemo.map        $(DESTDIR)/etc/tirex/renderer/mapserver/msdemo.map
	install -m 644 ${INSTALLOPTS} etc/renderer/mapserver/fonts.lst         $(DESTDIR)/etc/tirex/renderer/mapserver/fonts.lst
	install -m 755 ${INSTALLOPTS} -d                                       $(DESTDIR)/etc/tirex/renderer/mapnik
	install -m 644 ${INSTALLOPTS} etc/renderer/mapnik.conf.dist            $(DESTDIR)/etc/tirex/renderer/mapnik.conf
	install -m 755 ${INSTALLOPTS} -d                                       $(DESTDIR)/usr/share/man/man1/
	for program in bin/*; do \
        if grep -q "=head" $$program; then \
            pod2man $$program > $(DESTDIR)/usr/share/man/man1/`basename $$program`.1; \
        fi; \
    done
	cd backend-mapnik; $(MAKE) DESTDIR=$(DESTDIR) "INSTALLOPTS=${INSTALLOPTS}" install
	$(MAKE) -f Makefile.perl install

clean: Makefile.perl
	$(MAKE) -f Makefile.perl clean
	cd backend-mapnik; $(MAKE) DESTDIR=$(DESTDIR) clean
	rm -f Makefile.perl
	rm -f Makefile.perl.old
	rm -f build-stamp
	rm -f configure-stamp
	rm -rf blib

deb:
	debuild -I -us -uc

deb-clean:
	debuild clean

check:
	podchecker bin/*
	find lib -type f -name \*.pm | sort | xargs podchecker

htmldoc:
	rm -fr htmldoc
	mkdir -p htmldoc
	for pod in `find bin -type f | grep -v '\.'`; do \
        mkdir -p htmldoc/`dirname $$pod` ;\
	    pod2html --css=foo.css --htmldir=htmldoc --podpath=lib:bin:doc --infile=$$pod --outfile=htmldoc/$$pod.html; \
	done
	for pod in `find lib -name \*.pm`; do \
        mkdir -p htmldoc/`dirname $$pod` ;\
	    pod2html --htmldir=htmldoc --podpath=lib:bin:doc --infile=$$pod --outfile=htmldoc/$${pod%.pm}.html; \
	done
