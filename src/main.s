; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass:

        SID_LOAD = $1000
        SID_INIT = $1000
        SID_PLAY = $1003
        SID_NAME = "Beatbassie.sid"


        * = $0801

        .word (+), 2019
        .null $9e, format("%d", start)
+       .word 0

start
        jsr $fda3
        jsr $fd15
        jsr $ff5b
        jsr setup
        lda #0
        jsr $1000
        sei
        lda #$35
        sta $01
        lda #$7f
        sta $dc0d
        sta $dd0d
        ldx #0
        stx $dc0e
        stx $dd0e
        stx $3fff
        inx
        stx $d01a

        lda #$2c
        ldx #<irq1
        ldy #>irq1
        sta $d012
        stx $fffe
        sty $ffff

        lda #<nmi
        ldx #>nmi
        sta $fffa
        stx $fffb
        sta $fffc
        stx $fffd

        bit $dc0d
        bit $dd0d
        inc $d019

        lda #$1b
        sta $d011

        cli
        jmp *

irq1
        ; stabalize raster
        pha
        txa
        pha
        tya
        pha

        lda #$2d
        ldx #<irq2
        ldy #>irq2
        sta $d012
        stx $fffe
        sty $ffff
        nop
        inc $d019
        tsx
        cli
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
irq2
        txs
        ldx #8
-       dex
        bne -
        bit $ea
        lda $d012
        cmp $d012
        beq +
+
        jsr set_upper_sprites

        ldx #5
-       dex
        bpl -
        bit $ea
        jsr open_border

        dec $d020
        jsr SID_PLAY
        inc $d020

        lda #$fa
        ldx #<irq3
        ldy #>irq3
do_irq
        sta $d012
        stx $fffe
        sty $ffff
        inc $d019
        pla
        tay
        pla
        tax
        pla
nmi     rti


irq3
        pha
        txa
        pha
        tya
        pha
        inc $d020
        lda #$13
        sta $d011
        ldx #$50
-       dex
        bpl -
        dec $d020
        lda #$1b
        sta $d011

        lda #$2c
        ldx #<irq1
        ldy #>irq1
        jmp do_irq


set_upper_sprites
        lda #$31
        sta $d009
        sta $d00b
        sta $d00d
        sta $d00f

        lda #$18
        sta $d008
        lda #$30
        sta $d00a
        lda #$48
        sta $d00c
        lda #$60
        sta $d00e

        lda #($0340/64)
        sta $07fc
        nop
        sta $07fd
        nop
        sta $07fe
        nop
        sta $07ff
        lda #$f0
        sta $d015
        rts

setup
        ldx #$3f
        lda #$ff
-       sta $0340,x
        dex
        bpl -

        ldx #$00
-       txa
        sta $0400,x
        lda #$01
        sta $d800,x
        inx
        cpx #40*5
        bne -
        rts


        .align 256
open_border
        lda #$10
        ldx #$18
        jsr ob_normal_debug     ; not needed
        nop
        nop
        nop
        nop
        bit $ea
        jsr ob_pre_badline_debug

        jsr ob_pre_badline
        jsr ob_normal
        jsr ob_normal
        jsr ob_normal
        jsr ob_normal
        jsr ob_normal
        jsr ob_normal
        jsr ob_pre_badline
        jsr ob_normal
        jsr ob_normal
        jsr ob_normal
        jsr ob_normal
        jsr ob_normal
        jsr ob_normal
        jsr ob_pre_badline
 
        rts

ob_normal_debug
        ldy #5
-       dey
        bne -
        nop
        nop
        nop
        sta $d021
        stx $d021
        rts

ob_normal
        ; jsr = 6
        ldy #5
-       dey
        bne -
        nop
        nop
        nop
        sta $d016
        stx $d016
        rts

ob_pre_badline
        ldy #5
-       dey
        bne -
        nop
        nop
        nop
        sta $d016
        stx $d016
        sta $d016,y     ; add 1 cycle to get 9
        stx $d016
        rts

ob_pre_badline_debug
        ldy #5
-       dey
        bne -
        nop
        nop
        nop
        sta $d021
        stx $d021
        sta $d016,y     ; add 1 cycle to get 9
        stx $d016
        rts
        * = SID_LOAD
.binary format("../%s", SID_NAME), $7e



