build:
	zig build

install: build
	cp ./zig-out/bin/zigxd ~/bin/zigxd