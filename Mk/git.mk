%.git:	git.pkg
	[ -d $($*.dir) ] || git clone $($@) $($*.dir)
	touch $@
