.SUFFIXES:	.stamp
%.pkg:	pkg.stamp
	sudo apt-get install -y $*
	@touch $@

pkg.stamp:
	[ ! -f $@ ] || sudo apt-get update
	@if [ -f /var/run/reboot-required ]; then \
		echo "# vagrant ssh -- $(MAKE) -C `pwd` -f use-groff.mk apt-upgrade" >&2; \
		echo "# vagrant reload" >&2; \
	fi
	-@[ ! -f /var/run/reboot-required ]
	touch $@
