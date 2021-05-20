all: doc/README.pdf test/example.pdf

%.pdf: %.saty
	satysfi $<
%.saty: %.md ./satysfi.lua ./template.satysfi Makefile
	pandoc -o $@ -t ./satysfi.lua  -s --template ./template.satysfi -V show-title < $< 
