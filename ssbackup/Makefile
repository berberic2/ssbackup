
BINDIR = $(DESTDIR)/usr/sbin
CONFIGDIR = $(DESTDIR)/etc/ssbackup
MANDIR = $(DESTDIR)/usr/share/man/man8/

all: ssbackup-batch

doc:  ssbackup.8.html ssbackup-batch.8.html

ssbackup-batch: ssbackup-batch.g
	yapps2 $^ $@
	chmod +x $@

install: ssbackup-batch
	install -d $(CONFIGDIR)
	install ssbackup $(BINDIR)
	install ssbackup-batch $(BINDIR)
	install config.template $(CONFIGDIR)
	install ssbackup.8 $(MANDIR)
	install ssbackup-batch.8 $(MANDIR)

clean:
	rm ssbackup-batch

%.8.html : %.8
	rman -f HTML -r "" ./$< > $@
#	man -t -Thtml ./$< > $@
