build: Makefile.perl
	cd backend-mapnik; $(MAKE) $(MFLAGS)
	$(MAKE) -f Makefile.perl

Makefile.perl: Makefile.PL
	perl Makefile.PL PREFIX=/usr DESTDIR=$(DESTDIR) FIRST_MAKEFILE=Makefile.perl
	rm -f Makefile.perl.old

install-all: install install-example-map install-munin install-nagios

install-example-map:
	install -m 755 -g root -o root -d                              $(DESTDIR)/usr/share/tirex
	install -m 755 -g root -o root -d                              $(DESTDIR)/usr/share/tirex/example-map
	install -m 644 -g root -o root example-map/example.xml         $(DESTDIR)/usr/share/tirex/example-map
	install -m 644 -g root -o root example-map/ocean.*             $(DESTDIR)/usr/share/tirex/example-map
	install -m 644 -g root -o root example-map/README              $(DESTDIR)/usr/share/tirex/example-map
	install -m 755 -g root -o root -d                              $(DESTDIR)/etc/tirex/renderer/mapnik
	install -m 644 -g root -o root example-map/mapnik-example.conf $(DESTDIR)/etc/tirex/renderer/mapnik/example.conf

install-munin:
	install -m 755 -g root -o root -d                              $(DESTDIR)/usr/share/munin/plugins
	install -m 755 -g root -o root munin/*                         $(DESTDIR)/usr/share/munin/plugins

install-nagios:
	install -m 755 -g root -o root -d                              $(DESTDIR)/usr/lib/nagios/plugins
	install -m 755 -g root -o root -d                              $(DESTDIR)/etc/nagios/nrpe.d
	install -m 755 -g root -o root nagios/tirex*                   $(DESTDIR)/usr/lib/nagios/plugins
	install -m 644 -g root -o root nagios/cfg/*.cfg                $(DESTDIR)/etc/nagios/nrpe.d

install: build
	install -m 755 -g root -o root -d $(DESTDIR)/usr/bin/
	for program in bin/*; do \
	    install -m 755 -g root -o root $$program $(DESTDIR)/usr/bin/; \
    done
	install -m 755 -g root -o root -d                                       $(DESTDIR)/usr/lib/tirex/backends
	install -m 755 -g root -o root backends/test                            $(DESTDIR)/usr/lib/tirex/backends
	install -m 755 -g root -o root backends/wms                             $(DESTDIR)/usr/lib/tirex/backends
	install -m 755 -g root -o root -d                                       $(DESTDIR)/etc/tirex
	install -m 644 -g root -o root etc/tirex.conf.dist                      $(DESTDIR)/etc/tirex/tirex.conf
	install -m 755 -g root -o root -d                                       $(DESTDIR)/etc/tirex/renderer
	install -m 755 -g root -o root -d                                       $(DESTDIR)/etc/tirex/renderer/test
	install -m 644 -g root -o root etc/renderer/test.conf.dist              $(DESTDIR)/etc/tirex/renderer/test.conf
	install -m 644 -g root -o root etc/renderer/test/checkerboard.conf.dist $(DESTDIR)/etc/tirex/renderer/test/checkerboard.conf
	install -m 755 -g root -o root -d                                       $(DESTDIR)/etc/tirex/renderer/wms
	install -m 644 -g root -o root etc/renderer/wms.conf.dist               $(DESTDIR)/etc/tirex/renderer/wms.conf
	install -m 644 -g root -o root etc/renderer/wms/wms-example.conf.dist   $(DESTDIR)/etc/tirex/renderer/wms/wms-example.conf
	install -m 755 -g root -o root -d                                       $(DESTDIR)/etc/tirex/renderer/mapnik
	install -m 644 -g root -o root etc/renderer/mapnik.conf.dist            $(DESTDIR)/etc/tirex/renderer/mapnik.conf
	install -m 755 -g root -o root -d                                       $(DESTDIR)/etc/logrotate.d
	install -m 644 -g root -o root debian/logrotate.d-tirex-master          $(DESTDIR)/etc/logrotate.d/tirex-master
	install -m 755 -g root -o root -d                                       $(DESTDIR)/usr/share/man/man1/
	install -m 755 -g root -o root -d                                       $(DESTDIR)/usr/share/man/man5/
	for program in bin/*; do \
        if grep -q "=head" $$program; then \
            pod2man $$program > $(DESTDIR)/usr/share/man/man1/`basename $$program`.1; \
        fi; \
    done
	pod2man --section=5 doc/tirex.conf.pod > $(DESTDIR)/usr/share/man/man5/tirex.conf.5
	cd backend-mapnik; $(MAKE) DESTDIR=$(DESTDIR) install
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

