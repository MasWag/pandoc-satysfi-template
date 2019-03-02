README.pdf: README.saty
	satysfi $<
README.saty: README.md ./satysfi.lua ./template.satysfi Makefile
	cat $<  | sed 's/SATySFi/\\\\SATySFi;/g' | pandoc -o $@ -t ./satysfi.lua  -s --template ./template.satysfi -V show-title
