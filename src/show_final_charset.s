; vim: set et ts=8 sw=8 sts=8 sw=8 syntax=64tass:

; WARNING: Extremely shitty code ahead!


        ZP = $02

        * = $0801

        .word (+), 2019
        .null $9e, format("%d", start)
+       .word 0

start
        jsr $fda3
        jsr $ff15
        jsr $e544
        jsr make_logo
        lda #0
        jsr $1000
        sei
        lda #$7f
        sta $dc0d
        bit $dc0d
        ldx #0
        stx $dc0e
        inx
        stx $d01a
        lsr $d019

        lda #<irq1
        ldx #>irq1
        ldy #$30
        sta $0314
        stx $0315
        sty $d012

        lda #$1b
        sta $d011

        ldx #0
        lda #$09
-       sta $d800,x
        inx
        bne -

        ldx #0
-       lda info_text,x
        beq +
        sta $0540,x
        lda #$01
        sta $d940,x
        inx
        bne -
+
        cli
getkey
        jsr $ffe4
        beq getkey

        cmp #$9d
        bne +

        lda xpos
        beq getkey
        dec xpos
        jmp getkey
+       cmp #$1d
        lda xpos
        cmp #$38
        bcs getkey
        inc xpos
        jmp getkey


xpos    .byte 0


irq1
        lda #$18
        sta $d016
        sta $d018
        lda #$0c
        sta $d022
        lda #$0f
        sta $d023
        lda #$0b
        sta $d021
        lda #$00
        sta $d020
        dec $d020
        jsr $1006
        inc $d020

        lda #<irq2
        ldx #>irq2
        ldy #$72
do_irq
        sta $0314
        stx $0315
        sty $d012
        inc $d019
        jmp $ea81

irq2
        lda #08
        sta $d016
        lda #$16
        sta $d018
        lda #$0c
        sta $d021
        dec $d020
        jsr render_logo
        inc $d020

        lda #<irq1
        ldx #>irq1
        ldy #$30
        sta $0314
        stx $0315
        sty $d012
        inc $d019
        jmp $ea31

info_text
        .enc "screen"
        .text "Move logo with CRSR left/right", 0

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

render_logo .proc
        ldx xpos
        ldy #0
-
  .for row = 0, row < 5 , row += 1
        lda logo_data + row * 128,x
        sta $0400 + row * 40,y
  .next
        inx
        iny
        cpy #40
        bne -
        rts
.pend

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


        * = $1000
.binary "../Cant_Stop.sid", $7e

        * = $1c00
screen_data
.binary "../data/nw-wwe-font.screen.prg", 2

        * = $2000
.binary "../data/nw-wwe-font.charset.prg", 2


        * = $2800
logo_data
        .fill 128 * 5, 0
