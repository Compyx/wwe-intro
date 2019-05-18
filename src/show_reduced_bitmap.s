; vim: set et ts=8 sw=8 sts=8 sw=8 syntax=64tass:

; WARNING: Extremely shitty code ahead!


        ZP = $02

        DISP_ROW = 12

        * = $0801

        .word (+), 2019
        .null $9e, format("%d", start)
+       .word 0

start
        lda #$3b
        sta $d011
        lda #$18
        sta $d018
        lda #$18
        sta $d016
        lda #$00
        sta $d020
        sta $d021
        ldx #0
-       lda #$6e
        sta $0400,x
        sta $0500,x
        sta $0600,x
        sta $06e8,x
        lda #$03
        sta $d800,x
        sta $d900,x
        sta $da00,x
        sta $dae8,x
        inx
        bne -

        ; display result somewhat more readable

        ; first row: 'deilorsv'

        lda #$00
        ldx #$20
        sta ZP
        stx ZP + 1
        lda #<($2000 + DISP_ROW * $140)
        ldx #>($2000 + DISP_ROW * $140)
        sta ZP + 2
        stx ZP + 3

        lda #5
        sta ZP + 4
-
        ldx #40
-
        ldy #7
-       lda (ZP),y
        sta (ZP + 2),y
        dey
        bpl -

        lda ZP
        clc
        adc #8
        sta ZP
        bcc +
        inc ZP + 1
+
        lda ZP + 2
        clc
        adc #8
        sta ZP + 2
        bcc +
        inc ZP + 3
+
        dex
        bne --

        ; add extra to src
        lda ZP
        clc
        adc #($1b0-$0140)
        sta ZP
        bcc +
        inc ZP + 1
+
        dec ZP+4
        bne ---

        ; second row: 'w' + 'x'
        lda #$40
        ldx #$21
        sta ZP
        stx ZP + 1
        lda #<($2000 + (DISP_ROW + 5) * $140)
        ldx #>($2000 + (DISP_ROW + 5) * $140)
        sta ZP + 2
        stx ZP + 3

        lda #5
        sta ZP + 4
-
        ldx #8+6        ; 'w' + 'x'
-
        ldy #7
-       lda (ZP),y
        sta (ZP + 2),y
        dey
        bpl -

        lda ZP
        clc
        adc #8
        sta ZP
        bcc +
        inc ZP + 1
+
        lda ZP + 2
        clc
        adc #8
        sta ZP + 2
        bcc +
        inc ZP + 3
+
        dex
        bne --

        ; add extra to src due to not using all 40 columns
        lda ZP
        clc
        adc #<($1b0 - 14 * 8)
        sta ZP
        lda ZP + 1
        adc #>($1b0 - 14 * 8)
        sta ZP + 1

        ; also add extra to dest
        lda ZP + 2
        clc
        adc #(40 - 14) * 8
        sta ZP + 2
        bcc +
        inc ZP + 3
+
        dec ZP+4

        bne ---


        ; fuck it, use other colors
        ldy #9
-
        ldx #39
-
        lda #$9c
  .for row = 0, row < 10, row += 1
        sta $0400 + DISP_ROW * 40 + row * 40,x
  .next
        lda #$07
  .for row = 0, row < 10, row += 1
        sta $d800 + DISP_ROW * 40 + row * 40,x
  .next
        dex
        bpl -
        dey
        bpl --


        jmp *


        ; Link reduced bitmap

        * = $2000

.binary "../data/nw-wwe-font.bmp.prg", 2

        ; clear rest of bitmap
        .fill $4000 - *, 0
