all: doc/README.pdf test/blockquote.pdf test/example.pdf test/math.pdf test/nested_brace_with_ul.pdf test/table.pdf

%.pdf: %.saty
	satysfi $<
%.saty: %.md ./satysfi.lua ./template.satysfi Makefile
	pandoc -o $@ -t ./satysfi.lua  -s --template ./template.satysfi -V show-title < $< 
