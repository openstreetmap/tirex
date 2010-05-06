build: Makefile.perl
	cd backend-mapnik; $(MAKE) $(MFLAGS)
	$(MAKE) -f Makefile.perl

Makefile.perl: Makefile.PL
	perl Makefile.PL PREFIX=/usr DESTDIR=$(DESTDIR) FIRST_MAKEFILE=Makefile.perl
	rm -f Makefile.perl.old

install: build
	install -m 755 -g root -o root -d                          $(DESTDIR)/usr/bin/
	install -m 755 -g root -o root bin/tirex-batch             $(DESTDIR)/usr/bin/
	install -m 755 -g root -o root bin/tirex-master            $(DESTDIR)/usr/bin/
	install -m 755 -g root -o root bin/tirex-backend-manager   $(DESTDIR)/usr/bin/
	install -m 755 -g root -o root bin/tirex-rendering-control $(DESTDIR)/usr/bin/
	install -m 755 -g root -o root bin/tirex-send              $(DESTDIR)/usr/bin/
	install -m 755 -g root -o root bin/tirex-status            $(DESTDIR)/usr/bin/
	install -m 755 -g root -o root bin/tirex-syncd             $(DESTDIR)/usr/bin/
	install -m 755 -g root -o root bin/tirex-tiledir-check     $(DESTDIR)/usr/bin/
	install -m 755 -g root -o root bin/tirex-tiledir-stat      $(DESTDIR)/usr/bin/

	install -m 755 -g root -o root -d                          $(DESTDIR)/usr/lib/nagios/plugins
	install -m 755 -g root -o root -d                          $(DESTDIR)/etc/nagios/nrpe.d
	install -m 755 -g root -o root nagios/tirex*               $(DESTDIR)/usr/lib/nagios/plugins
	install -m 755 -g root -o root nagios/cfg/*cfg             $(DESTDIR)/etc/nagios/nrpe.d

	install -m 755 -g root -o root -d                          $(DESTDIR)/usr/lib/tirex/backends
	install -m 755 -g root -o root backends/test               $(DESTDIR)/usr/lib/tirex/backends
	install -m 755 -g root -o root backends/wms                $(DESTDIR)/usr/lib/tirex/backends

	install -m 755 -g root -o root -d                          $(DESTDIR)/usr/share/tirex
	install -m 755 -g root -o root -d                          $(DESTDIR)/usr/share/tirex/example-map
	install -m 644 -g root -o root example-map/example.xml     $(DESTDIR)/usr/share/tirex/example-map
	install -m 644 -g root -o root example-map/ocean.*         $(DESTDIR)/usr/share/tirex/example-map
	install -m 644 -g root -o root example-map/README          $(DESTDIR)/usr/share/tirex/example-map

	install -m 755 -g root -o root -d                          $(DESTDIR)/usr/share/munin/plugins
	install -m 755 -g root -o root munin/*                     $(DESTDIR)/usr/share/munin/plugins

	mkdir -p man-generated 
	for i in bin/*; do if grep -q "=head" $$i; then pod2man $$i > man-generated/`basename $$i`.1; fi; done
	pod2man --section=5 doc/tirex.conf.pod > man-generated/tirex.conf.5

	install -m 755 -g root -o root -d                                           $(DESTDIR)/etc/tirex
	install -m 644 -g root -o root etc/tirex.conf.dist                          $(DESTDIR)/etc/tirex/tirex.conf
	install -m 755 -g root -o root -d                                           $(DESTDIR)/etc/tirex/renderer
	install -m 755 -g root -o root -d                                           $(DESTDIR)/etc/tirex/renderer/test
	install -m 644 -g root -o root etc/renderer/test.conf.dist                  $(DESTDIR)/etc/tirex/renderer/test.conf
	install -m 644 -g root -o root etc/renderer/test/checkerboard.conf.dist     $(DESTDIR)/etc/tirex/renderer/test/checkerboard.conf
	install -m 755 -g root -o root -d                                           $(DESTDIR)/etc/tirex/renderer/wms
	install -m 644 -g root -o root etc/renderer/wms.conf.dist                   $(DESTDIR)/etc/tirex/renderer/wms.conf
	install -m 644 -g root -o root etc/renderer/wms/wms-example.conf.dist       $(DESTDIR)/etc/tirex/renderer/wms/wms-example.conf
	install -m 755 -g root -o root -d                                           $(DESTDIR)/etc/tirex/renderer/mapnik
	install -m 644 -g root -o root etc/renderer/mapnik.conf.dist                $(DESTDIR)/etc/tirex/renderer/mapnik.conf
	install -m 644 -g root -o root example-map/mapnik-example.conf              $(DESTDIR)/etc/tirex/renderer/mapnik/mapnik-example.conf
	install -m 755 -g root -o root -d                                           $(DESTDIR)/etc/logrotate.d
	install -m 644 -g root -o root debian/logrotate.d-tirex-master              $(DESTDIR)/etc/logrotate.d/tirex-master
	install -m 755 -g root -o root -d                                           $(DESTDIR)/usr/share/man/man1/
	install -m 644 -g root -o root man-generated/*.1                            $(DESTDIR)/usr/share/man/man1/
	install -m 755 -g root -o root -d                                           $(DESTDIR)/usr/share/man/man5/
	install -m 644 -g root -o root man-generated/*.5                            $(DESTDIR)/usr/share/man/man5/

	cd backend-mapnik; $(MAKE) DESTDIR=$(DESTDIR) install
	$(MAKE) -f Makefile.perl install

clean: Makefile.perl
	$(MAKE) -f Makefile.perl clean
	cd backend-mapnik; $(MAKE) DESTDIR=$(DESTDIR) clean
	rm -f Makefile.perl
	rm -f Makefile.perl.old
	rm -f build-stamp
	rm -f configure-stamp
	rm -rf blib man-generated

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

