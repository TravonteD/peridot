VPATH=src

bin/peridot: peridot.cr ui/interface.cr ui.cr mpd.cr
	shards build --release

test:
	crystal spec

run:
	crystal run src/peridot.cr

install: bin/peridot
	cp bin/peridot /usr/local/bin/peridot

uninstall:
	rm /usr/local/bin/peridot
