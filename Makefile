PREFIX?=/opt/circonus
MAN=$(PREFIX)/man/man8
SBIN=$(PREFIX)/sbin
CONF=$(PREFIX)/etc/node-agent.d
MODULES=$(PREFIX)/lib/node_modules
MANIFEST_DIR=/var/svc/manifest/network/circonus
METHOD_DIR=/var/svc/method
MAKE?=make

all:

install:	install-nad install-man install-plugins install-modules

install-dirs:
	./mkinstalldirs $(DESTDIR)$(MAN)
	./mkinstalldirs $(DESTDIR)$(SBIN)
	./mkinstalldirs $(DESTDIR)$(CONF)
	./mkinstalldirs $(DESTDIR)$(MODULES)

install-nad:	install-dirs
	./install-sh -c -m 0755 nad $(DESTDIR)$(SBIN)/nad

install-man:	install-dirs
	./install-sh -c -m 0644 nad.8 $(DESTDIR)$(MAN)/nad.8

install-plugins:	install-dirs
	rsync -a plugins/ $(DESTDIR)$(CONF)/

install-modules:
	rsync -a node_modules/ $(DESTDIR)$(MODULES)/

install-illumos:	install
	/bin/sed \
		-e "s#@@PREFIX@@#$(PREFIX)#g" \
		-e "s#@@METHOD_DIR@@#$(METHOD_DIR)#g" \
		-e "s#@@CONF@@#$(CONF)#g" \
		smf/nad.xml > smf/nad.xml.out
	/bin/sed \
		-e "s#@@PREFIX@@#$(PREFIX)#g" \
		-e "s#@@CONF@@#$(CONF)#g" \
		smf/circonus-nad > smf/circonus-nad.out
	mkdir -p $(DESTDIR)$(MANIFEST_DIR)
	mkdir -p $(DESTDIR)$(METHOD_DIR)
	./install-sh -c -m 0644 smf/nad.xml.out $(DESTDIR)$(MANIFEST_DIR)/nad.xml
	./install-sh -c -m 0755 smf/circonus-nad.out $(DESTDIR)$(METHOD_DIR)/circonus-nad
	cd $(DESTDIR)$(CONF)/illumos ; $(MAKE)
	cd $(DESTDIR)$(CONF) ; for f in aggcpu.elf cpu.elf fs.elf zpoolio.elf if.sh sdinfo.sh smf.sh tcp.sh udp.sh vminfo.sh vnic.sh zfsinfo.sh zone_vfs.sh; do /bin/ln -sf illumos/$$f ; done

install-linux:	install
	/bin/sed -e "s#@@CONF@@#$(CONF)#g" linux-init/defaults > linux-init/defaults.out
	cd $(DESTDIR)$(CONF)/linux ; $(MAKE)
	cd $(DESTDIR)$(CONF) ; for f in cpu.sh disk.sh fs.elf if.sh vm.sh ; do /bin/ln -sf linux/$$f ; done

install-ubuntu:	install-linux
	/bin/sed -e "s#@@PREFIX@@#$(PREFIX)#g" linux-init/ubuntu-init > linux-init/ubuntu-init.out
	./install-sh -c -m 0644 linux-init/defaults.out $(DESTDIR)/etc/default/nad
	./install-sh -c -m 0755 linux-init/ubuntu-init.out $(DESTDIR)/etc/init.d/nad

install-rhel:	install-linux
	/bin/sed -e "s#@@PREFIX@@#$(PREFIX)#g" linux-init/rhel-init > linux-init/rhel-init.out
	./install-sh -c -m 0644 linux-init/defaults.out $(DESTDIR)/etc/sysconfig/nad
	./install-sh -c -m 0755 linux-init/rhel-init.out $(DESTDIR)/etc/init.d/nad

clean:
	rm -f linux-init/*.out smf/*.out
