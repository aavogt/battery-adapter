SHELL = /bin/bash
OUT = $(shell basename `pwd`)
watch:
	ulimit -v 1000000
	set -m
	trap 'pkill -P $$$$' EXIT
	ls *.hs | entr ghcid -r &
	make view_step view_gcode
	ls *.step Makefile | entr make $(OUT).gcode

$(OUT).gcode: $(OUT).step Makefile
	prusa-slicer -g --load config.ini --duplicate 8 $(OUT).step --output $(OUT).gcode

$(OUT).cabal: package.yaml
	(which hpack || cabal install hpack) && hpack
	touch $@

$(OUT).step: main.hs $(OUT).cabal
	cabal run

.PHONY: preview sdcard watch clean

view_step: $(OUT).step
		pgrep f3d || f3d --watch $< &

view_gcode: $(OUT).gcode
		gcodeviewer $<

clean:
	rm -rf $(OUT).{cabal,step,gcode} dist-newstyle/ cabal.project.local*

DEST := /run/media/aavogt/E5S1

sdcard: $(OUT).gcode
		[ -e $(DEST) ] && cp $(OUT).gcode $(DEST)/ && udiskie-umount $(DEST)
