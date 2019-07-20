; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass:


        ; 0 = "world wide", 1 = "expressive"

        COLOR_LOW = $06
        COLOR_MID = $0e
        COLOR_HI  = $03

        FLIP_DELAY = $50

        TOP_RASTER = $2b

        ZP = $02

        SID_LOAD = $1000
        SID_INIT = $1000
        SID_PLAY = $1003
        SID_NAME = "Beatbassie.sid"
        ;SID_PLAY = $1006
        ;SID_NAME = "Cant_Stop.sid"

        logo_data = $2800




        * = $0801

        .word (+), 2019
        .null $9e, format("%d", start)
+       .word 0


logo_col_low    .byte $06
logo_col_mid    .byte $0e
logo_col_hi     .byte $03


start
        jsr $fda3
        jsr $fd15
        jsr $ff5b
        jsr setup
        lda #0
        jsr SID_INIT
        sei
        lda #$35
        sta $01
        lda #$7f
        sta $dc0d
        sta $dd0d
        ldx #0
        stx $dc0e
        stx $dd0e
        stx $3fff       ; Warning: store old $3fff if intro is shorter
        inx
        stx $d01a

        lda #TOP_RASTER
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

        lda logo_col_mid
        sta $d025
        lda #$00        ; bg color
        sta $d026
        lda logo_col_low
        sta $d02b
        sta $d02c
        sta $d02d
        sta $d02e
        lda #$f0
        sta $d01c

        cli
        jmp *

irq1
        ; stabalize raster
        pha
        txa
        pha
        tya
        pha

        lda #TOP_RASTER + 1
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

        ldy #10
-       dey             ; 11 *5 + 4 = 59
        bne -

        nop
        nop
        bit $ea


        lda #$18        ; 2
        sta $d018       ; 4
        lda #$18        ; 2
        sta $d016       ; 4
        lda logo_col_mid  ; 4
        sta $d022       ; 4
        lda logo_col_low  ; 4
        sta $d023       ; 4
                        ; = 24

        jsr open_border
        ;lda #$06
        ;sta $d020
       ; lda #$00
       ; sta $d021

        dec $d020
        jsr SID_PLAY
        inc $d020



        lda #$fa
        ldx #<irq3
        ldy #>irq3
        jmp do_irq

irq3
        pha
        txa
        pha
        tya
        pha
        inc $d020
        lda #$13
        sta $d011
        lda #$02
        sta $d020
        sta $d021
        lda #0
        sta $3fff
        ldx #$30
-       dex
        bpl -
        dec $d020
        lda #$1b
        sta $d011
        inc $d020
        jsr flip_logo
        inc $d020



        lda #$10
        ldx #<irq4
        ldy #>irq4
        jmp do_irq

irq4
        pha
        txa
        pha
        tya
        pha

        lda #$06
        sta $d020
        sta $d021
        lda logo_col_mid
        sta $d025
        lda #$00        ; bg color
        sta $d026
        lda logo_col_low
        sta $d02b
        sta $d02c
        sta $d02d
        sta $d02e
        lda #$f0
        sta $d01c

        jsr fade_in


        lda #TOP_RASTER
        ldx #<irq1
        ldy #>irq1
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



set_upper_sprites
        lda #$31
        sta $d009
        sta $d00b
        sta $d00d
        sta $d00f
        lda #$00
        sta $d01d
xpos0   lda #$e0
        sta $d008
xpos1   lda #$00
        sta $d00a
xpos2   lda #$58
        sta $d00c
xpos3   lda #$70
        sta $d00e

sprptr0 ldx #$c0                ; lowest sprite pointer:
                                ; $C0 = WORLD WIDE, $C8: EXPRESSIVE
        stx $07fc
        inx
        stx $07fd
        inx
        stx $07fe
        inx
        stx $07ff
        lda #$f0
        sta $d015
        lda #%11010000
        sta $d010
        rts

setup
        ldx #$3f
        lda #$00
-       sta $0340,x
        dex
        bpl -

        ldx #0
        txa
-
  .for p = 0, p < 4, p += 1
        lda #$00
        sta $0400 + p * 256,x
        lda #$08 + 6
        sta $d800 + p * 256,x
  .next
        inx
        bne -


        ldx #$00
        lda #$08
-       sta $d800,x
        inx
        cpx #40*5
        bne -

        ldx #$02
        stx $d02b
        inx
        stx $d02c
        inx
        stx $d02d
;        inx            ; 5 -> d
        ldx #$06        ; 6 -> e
        stx $d02e

        ; convert charset to logo
        jsr make_logo

        ; put 'expressive' on screen

        ldx #$00
-
  .for row = 0, row < 5, row += 1
        lda logo_data + row * 128 + 4,x
        sta $0400 + row * $28,x
  .next
        inx
        cpx #$28
        bne -


        rts


        .align 256
open_border
;         jsr ob_normal_debug     ; not needed
        ; waste 54 cycles
        ldy #12 ; 2

-       dey     ; 2
        bne -   ; 3 / 2 last iter

        ;nop
        ;bit $ea
        ;jsr ob_pre_badline_debug        ; 55 cycles + 6 for JSR
        ldy #8 ;2
-       dey
        bne -   ; 11 * 5 + 4

        nop
        nop

        lda #$18      ; 2
        sta $d016       ; 4


        lda #$ff
        sta $3fff
        lda #$00
        sta $d020


        lda #$10
        ldx #$18

        ;jsr ob_pre_badline

        lda logo_col_hi
        nop
        ldy #5
-       dey
        bne -
        sta $d021
        lda #$10
        sta $d016
        stx $d016
        sta $d016,y     ; add 1 cycle to get 9
        stx $d016
        nop
        nop
        nop

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

        lda #$31 + 21   ; 2
        sta $d009       ; 4
        sta $d00b       ; 4
        sta $d00d       ; 4
        sta $d00f       ; 4
                        ; = 18

        ldy #1
        lda #$10
        jsr ob_normal+2

        jsr ob_normal

        ; -JSR = -6

        ; 6*4  = +24

sprptr1 ldy #$c4
        sty $07fc
        iny
        sty $07fd
        iny
        sty $07fe
        iny
        sty $07ff

        nop     ; +6 for JSR
        nop
        nop

        nop
        nop
        nop
        nop
        sta $d016
        stx $d016
        sty $3fff
        nop     ; +6 for RTS


        jsr ob_normal
        ;jsr ob_normal
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

        jsr ob_normal
        jsr ob_normal
        jsr ob_normal
        jsr ob_normal
        jsr ob_normal
        jsr ob_normal
        ;jsr ob_normal

        lda #$06
        sta $d021
        sta $d020
        ldy #5
-       dey
        bne -
        lda #$10
        sta $d016
        stx $d016
        lda #$06
        lda $d021
        rts



.align $40
ob_normal_debug
        ldy #5          ; 2
-       dey             ; 2
        bne -           ; 3 (2 on last iter)
                        ; ---
                        ; 26
        nop             ; 2
        nop             ; 2
        nop             ; 2
        sta $d013       ; 4
        stx $d013       ; 4
        rts             ; 6
                        ;----
                        ; 46
.align $40
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

ob_pre_badline_debug    ; fix this
        ldy #5          ; 2
-       dey
        bne -           ; 4 * 5 + 4
                        ; = 26

        nop             ; 2
        nop             ; 2
        nop             ; 2
        sta $d021       ; 4
        stx $d021       ; 4
        sta $d021,y     ; 5
        stx $d021       ; 4
        rts             ; 6
                        ; = 


make_logo .proc
        letter = ZP     ; index in the 'world wide expressive' "string"
        screen = ZP + 1 ; offset in 'screen'
        offset = ZP + 2 ; offset in source
        width = ZP + 3  ; width of letter
        tmp = ZP + 4    ; tmp width or so
        row = ZP + 5    ; row index
        letter_index = ZP + 6


        lda #0
        sta letter
        sta offset
        sta row

more
        ; get letter data
        lda letter
        asl
        tax
        lda letter_offsets,x
        sta letter_index
        lda letter_offsets + 1,x
        ; sta screen
        tay

        ; handle letter index
        lda letter_index
        asl
        tax
;        lda letter_data,x
;        sta offset
        lda letter_data + 1,x
        sta width
        lda letter_data,x
        tax

        ; copy to dest
        ; ldy screen
        ; ldx offset
-
  .for rw = 0, rw < 5, rw += 1
        lda screen_data + rw * 54,x
        sta logo_data + rw * 128,y
  .next
        inx
        iny
        dec width
        bne -

        sty screen

        inc letter

        lda letter
        cmp #((letter_offsets_end - letter_offsets) / 2)
        bcc more
        rts
.pend

make_logo_low .proc
        letter = ZP     ; index in the 'world wide expressive' "string"
        screen = ZP + 1 ; offset in 'screen'
        offset = ZP + 2 ; offset in source
        width = ZP + 3  ; width of letter
        tmp = ZP + 4    ; tmp width or so
        row = ZP + 5    ; row index
        letter_index = ZP + 6


        lda #9
        sta letter
        lda #0
        sta offset
        sta row

more
        ; get letter data
        lda letter
        asl
        tax
        lda letter_offsets,x
        sta letter_index
        lda letter_offsets + 1,x
        ; sta screen
        tay

        ; handle letter index
        lda letter_index
        asl
        tax
;        lda letter_data,x
;        sta offset
        lda letter_data + 1,x
        sta width
        lda letter_data,x
        tax

        ; copy to dest
        ; ldy screen
        ; ldx offset
-
  .for rw = 0, rw < 5, rw += 1
        lda screen_data + rw * 54,x
        sta logo_data + $0200 + rw * 128,y
  .next
        inx
        iny
        dec width
        bne -

        sty screen

        inc letter

        lda letter
        cmp #((letter_offsets_end - letter_offsets) / 2) + 12
        bcc more
        rts
.pend



        rts


letter_data     ; offset, width
        .byte 0, 5      ;  0 = d
        .byte 5, 4      ;  1 = e
        .byte 9, 2      ;  2 = i
        .byte 11, 4     ;  3 = l
        .byte 15, 5     ;  4 = o
        .byte 20, 5     ;  5 = p
        .byte 25, 5     ;  6 = r
        .byte 30, 5     ;  7 = s
        .byte 35, 5     ;  8 = v
        .byte 40, 8     ;  9 = w
        .byte 48, 6     ; 10 = x

letter_offsets  ; letter, offset
        .byte 9, 0      ; w
        .byte 4, 8      ; o
        .byte 6, 13     ; r
        .byte 3, 18     ; l
        .byte 0, 22     ; d
        ; space
        .byte 9, 29     ; w
        .byte 2, 37     ; i
        .byte 0, 39     ; d
        .byte 1, 44     ; e
        ; space
        .byte 1, 50     ; e
        .byte 10, 54    ; x
        .byte 5, 60     ; p
        .byte 6, 65     ; r
        .byte 1, 70     ; e
        .byte 7, 74     ; s
        .byte 7, 79     ; s
        .byte 2, 84     ; i
        .byte 8, 86     ; v
        .byte 1, 91     ; e
letter_offsets_end


logo_index      .byte 0

flip_logo .proc
delay   lda #FLIP_DELAY
        beq +
        dec delay + 1
        rts
+
        lda #FLIP_DELAY
        sta delay + 1

        lda logo_index
        eor #1
        sta logo_index

        ; sprite pointers
        lda logo_index
        asl
        asl
        asl
        adc #$c0
        sta sprptr0 + 1
        adc #$04
        sta sprptr1 + 1

        ; XXX: do this with $d018 switching
        lda logo_index
        bne expressive

        ldx #39
-
  .for row = 0, row < 5, row += 1
        lda logo_data + row * 128 + 4,x
        sta $0400 + row * 40,x
  .next
        dex
        bpl -

        ; set colors
        lda #$02
        ldx #$0a
        ldy #$07
        sta logo_col_low
        stx logo_col_mid
        sty logo_col_hi

        rts
expressive
        ldx #39
-
  .for row = 0, row < 5, row += 1
        lda logo_data + row * 128 + 4 +1 + 48,x
        sta $0400 + row * 40,x
  .next
        dex
        bpl -
        ; set colors
        lda #$09
        ldx #$05
        ldy #$0d
        sta logo_col_low
        stx logo_col_mid
        sty logo_col_hi
        rts

.pend



fade_in .proc
delay   lda #3
        beq ok
        dec delay + 1
        rts
ok      lda #3
        sta delay + 1

index   lda #0
        sta add_1 + 1
        clc
        asl
add_1   adc #0
        tax

        cpx #fade_in_table_end - fade_in_table
        bcc +
        ldx #0
        stx index + 1
        lda #$ff
        sta delay + 1
        rts
+

        lda fade_in_table + 0,x
        sta logo_col_low
        lda fade_in_table + 1,x
        sta logo_col_mid
        lda fade_in_table + 2,x
        sta logo_col_hi
        inc index + 1
        rts
.pend


fade_in_table
        ;blue
        .byte $00, $00, $00
        .byte $00, $00, $06
        .byte $00, $06, $04
        .byte $06, $04, $0e
        .byte $04, $0e, $03
        .byte $0e, $03, $01
        .byte $03, $01, $01
        .byte $03, $01, $01
        .byte $0e, $03, $01
        .byte $04, $0e, $03
        .byte $06, $0e, $03
        .byte $06, $04, $0e
        .byte $00, $00, $00
fade_in_table_end


        * = SID_LOAD
.binary format("../%s", SID_NAME), $7e




        * = $1c00
screen_data
.binary "../data/nw-wwe-font.screen.prg", 2

        * = $2000
.binary "../data/nw-wwe-font.charset.prg", 2


        * = $3000
.binary "../data/nw-wwe-sprites.prg", 2

