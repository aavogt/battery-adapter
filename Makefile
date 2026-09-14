# https://github.com/aavogt/OCCT_XCAF_FacePicker
VIEWER = OCCT_XCAF_FacePicker
# VIEWER = f3d --watch

SHELL = /bin/bash
OUT = $(shell basename `pwd`)
watch:
	ulimit -v 1000000
	set -m
	trap 'pkill -P $$$$' EXIT INT TERM
	pgrep $(word 1, VIEWER) || $(VIEWER) $(OUT).step &
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
		pgrep $(word 1, VIEWER) || $(VIEWER) $(OUT).step &
		gcodeviewer $(OUT).gcode

clean:
	rm -rf $(OUT).{cabal,step,gcode} dist-newstyle/ cabal.project.local*

DEST := /run/media/aavogt/e5s1

GIT_FIRST_WORD = $(shell git log -1 --pretty=%s | cut -d' ' -f1)

sdcard: $(OUT).gcode
	# prompt to git commit -a -m ??
	[ -e $(DEST) ] && cp $(OUT).gcode $(DEST)/$(GIT_FIRST_WORD).gcode && udiskie-umount $(DEST)
