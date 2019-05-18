; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass:

        SCRLSB = $0c00
        SCRMSB = $1000
        BITMAP = $1400
        ZP = $02

        * = $0801

        .word (+), 2019
        .null $9e, format("%d", start)
+       .word 0

start
        lda #$18        ; $2000 = bitmap, $0400 = vidram
        sta $d018
        lda #$18
        sta $d016
        lda #$3b
        sta $d011
        lda #$03
        sta $dd00
        lda #$00
        sta $d020
        sta $d021

        ; set colors
        ldx #$00
-
        lda #$6e
        sta $0400,x
        sta $0500,x
        sta $0600,x
        sta $06e8,x

        ; also store for Koala format
        sta $3f40,x
        sta $4040,x
        sta $4140,x
        sta $4228,x

        lda #$03
        sta $d800,x
        sta $d900,x
        sta $da00,x
        sta $dae8,x

        sta $4328,x
        sta $4428,x
        sta $4528,x
        sta $4610,x
        inx
        bne -

        lda #$00
        sta $4700

        jsr render

        jmp *


render .proc

        bmp_dst = ZP
        bmp_src = ZP + 2
        scr_lsb = ZP + 4
        scr_msb = ZP + 6
        num = ZP + 8

        lda #0
        sta num
        sta num + 1

        lda #<$2000
        ldx #>$2000
        sta bmp_dst
        stx bmp_dst + 1

        lda #<SCRLSB
        ldx #>SCRLSB
        sta scr_lsb
        stx scr_lsb + 1
        lda #<SCRMSB
        ldx #>SCRMSB
        sta scr_msb
        stx scr_msb + 1

more

        ; get source bitmap pointer
        ldy #0
        lda (scr_lsb),y
        sta bmp_src
        lda (scr_msb),y
        sec
        sbc #$0c        ; orignal table used $2000+
        sta bmp_src + 1
        ldy #7
-       lda (bmp_src),y
        sta (bmp_dst),y
        dey
        bpl -

        inc scr_lsb
        bne +
        inc scr_lsb + 1
+
        inc scr_msb
        bne +
        inc scr_msb + 1
+
        lda bmp_dst
        clc
        adc #8
        sta bmp_dst
        bcc +
        inc bmp_dst + 1
+
        ; are we done?
        inc num
        bne +
        inc num + 1
+
        lda num + 1
        cmp #>1000
        bne more
        lda num
        cmp #<1000
        bne more


        rts
.pend


.cerror * >= SCRLSB, format("Too much data: PC = %x", *)


        * = SCRLSB
        .binary "../data/nw-mc-font.lsb", 2

        * = SCRMSB
        .binary "../data/nw-mc-font.msb", 2

        * =  BITMAP
        .binary "../data/nw-mc-font.bmp", 2



