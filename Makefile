# vim: set noet ts=8 sw=8 sts=8:

ASM = 64tass
ASM_FLAGS = -C --ascii

TEST_PRGS = show_reduced_bitmap.prg show_final_charset.prg


all: $(TEST_PRGS) intro.prg


data/nw-wwe-font.bmp.prg: make-logo.py
	python3 ./make-logo.py


show_reduced_bitmap.prg: src/show_reduced_bitmap.s \
	data/nw-wwe-font.bmp.prg
	$(ASM) $(ASM_FLAGS) $< -o $@


show_final_charset.prg: src/show_final_charset.s \
	data/nw-wwe-font.screen.prg \
	data/nw-wwe-font.charset.prg
	$(ASM) $(ASM_FLAGS) $< -o $@


logo: data/nw-font-bitmap.prg
	python3 ./make-logo.py

intro.prg: src/main.s data/nw-wwe-sprites.prg
	$(ASM) $(ASM_FLAGS) $< -o $@


.PHONY: clean
clean:
	rm -f data/nw-wwe-font.bmp.prg
	rm -f data/nw-wwe-font.charset.prg
	rm -f data/nw-wwe-font.screen.prg
	rm -f show_reduced_bitmap.prg
	rm -f show_final_charset.prg
