SHELL = /bin/bash
OUT = $(shell basename `pwd`)
watch:
	ulimit -v 1000000
	set -m
	trap 'pkill -P $$$$' EXIT
	pgrep f3d || f3d --watch $(OUT).step &
	ls Makefile config.ini $(OUT)*.step | entr make $(OUT).gcode &
	ghcid -r &
	gcodeviewer $(OUT).gcode

$(OUT).gcode: $(OUT).step config.ini Makefile
	prusa-slicer -g --load config.ini --duplicate 1 --output $(OUT).gcode -m $(OUT)*.step

$(OUT).cabal: package.yaml
	(which hpack || cabal install hpack) && hpack
	touch $@

$(OUT).step: main.hs $(OUT).cabal
	cabal run

.PHONY: preview sdcard watch clean

view: $(OUT).step $(OUT).gcode
		pgrep f3d || f3d --watch $(OUT).step &
		gcodeviewer $(OUT).gcode

clean:
	rm -rf $(OUT).{cabal,step,gcode} dist-newstyle/ cabal.project.local*

DEST := /run/media/aavogt/E5S1

sdcard: $(OUT).gcode
		[ -e $(DEST) ] && cp $(OUT).gcode $(DEST)/ && udiskie-umount $(DEST)
