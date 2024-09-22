%.git:	git.pkg
	@if [ ! -d $($*.dir) ]; then \
		echo git clone $($@) $($*.dir); \
		git clone $($@) $($*.dir); \
	fi
	@touch $@
