#!/usr/bin/env python3

import sys


class LogoConverter(object):
    """
    Convert the 'Flashing bitmap' 3-color font from 'Not Worthy' to a charset
    and sprites.
    """

    # source bitmap file, contains the entire font from the demo
    SRC_BITMAP_FILE = 'data/nw-font-bitmap.prg'

    # destination bitmap file, a tempory file for checking intermediate
    # conversion result
    DST_BITMAP_FILE = 'data/nw-wwe-font.bmp.prg'

    # width of all WWE letters on one line
    DST_WIDTH_CHARS = 54

    # height of the letters in the font in char rows
    DST_HEIGHT_CHARS = 5

    # width/size of a row in the converted bitmap
    DST_WIDTH_BITMAP = DST_WIDTH_CHARS * 8

    DST_CHARSET_FILE = 'data/nw-wwe-font.charset.prg'
    DST_SCREEN_FILE = 'data/nw-wwe-font.screen.prg'
    DST_SPRITES = 'data/nw-wwe-font.sprites.prg'

    SPR_Y_OFFSET = 1

    # letters in the font used for the WWE charset/sprites
    #
    # each tuple contains (row, column, width) in the source bitmap (in chars)
    LETTERS = { 'd': (0, 15, 5),
                'e': (0, 20, 4),
                'i': (0, 38, 2),
                'l': (5, 10, 4),
                'o': (5, 27, 5),
                'p': (5, 32, 5),
                'r': (10, 5, 5),
                's': (10, 10, 5),
                'v': (10, 24, 5),
                'w': (10, 29, 8),
                'x': (15, 0, 6)
    }

    SPR_XPOS = [0x00, 0x01, 0x02, 0x40, 0x41, 0x42, 0x80, 0x81, 0x82,
                0xc0, 0xc1, 0xc2
    ]


    def __init__(self, debug=True):
        """
        Initialize data and read the source bitmap.


        :param debug: output debugging info on stdout
        :type debug: boolean
        """
        self.debug = debug

        self.dst_bitmap = bytearray(self.DST_WIDTH_BITMAP * self.DST_HEIGHT_CHARS)
        self.dst_charset = bytearray(0x800)
        self.dst_screen = bytearray(0x3e8)
        self.dst_sprites = bytearray([0xff] * (4 * 2 * 64))

        if self.debug:
            print("Converting 'Not Worthy' font:")
            print("  Reading source bitmap '{}' ... ".format(
                self.SRC_BITMAP_FILE),
                end="")
        with open(self.SRC_BITMAP_FILE, "rb") as infile:
            # strip off load address
            self.src_bitmap = infile.read()[2:]
        if self.debug:
            print("OK: {} bytes.".format(len(self.src_bitmap)))


    def write_prg_file(self, name, data, load):
        """
        Write data as a PRG file

        :param name: filename
        :param data: data to write
        :type data: iterable containing bytes
        :param load: load address
        :type load: integer in the range 0-65535
        """
        if self.debug:
            print("  Writing PRG file '{}', size: ${:04x}, load: ${:04x} ... ".format(
                name, len(data), load), end="")

        with open(name, "wb") as outfile:
            # write load address
            outfile.write(bytes([load & 0xff, (load >> 8) & 0xff]))
            # write data
            outfile.write(data)
        if self.debug:
            print("OK.")


    def copy_bitmap_letter(self, src_row, src_col, dst_col, width):
        """
        Copy a single letter from source bitmap to intermediate bitmap

        :param src_row: source row
        :param src_col: source column
        :param dst_col: destination row
        :param width:   width in chars
        """

        src_offset = src_row * 0x140 + src_col * 8
        dst_offset = dst_col * 8

        for row in range(self.DST_HEIGHT_CHARS):
            src = src_offset + 0x140 * row
            dst = dst_offset + self.DST_WIDTH_BITMAP * row
            self.dst_bitmap[dst:dst + width * 8] = self.src_bitmap[src:src + width * 8]


    def reduce_bitmap(self):
        """
        Reduce bitmap to used letters
        """
        if self.debug:
            print("  Reducing bitmap:")

        offset = 0

        for letter in sorted(self.LETTERS.keys()):
            (row, col, width) = self.LETTERS[letter]
            self.copy_bitmap_letter(row, col, offset, width)
            offset += width

        self.write_prg_file(self.DST_BITMAP_FILE, self.dst_bitmap, 0x2000)


    def create_charset(self):
        """
        Convert reduced bitmap to a charset + screen
        """

        total = 1   # make $00/'@' empty
        self.dst_charset[0:8] = [0xff] * 8

        for ch in range(self.DST_WIDTH_CHARS * self.DST_HEIGHT_CHARS):
            if self.debug:
                print("  Trying char ${:02x} ... ".format(ch), end = "")

            # get current 'char' to look up
            curr = self.dst_bitmap[ch * 8:ch * 8 + 8]

            # try to locate in current charset
            found = False
            for idx in range(total):
                if curr == self.dst_charset[idx * 8:idx * 8 + 8]:
                    if self.debug:
                        print("got existing char ${:02x}".format(idx))
                    self.dst_screen[ch] = idx
                    found = True
                    break

            if not found:
                if self.debug:
                    print("adding new char ${:02x}".format(total))
                self.dst_charset[total * 8: total * 8 + 8] = curr
                self.dst_screen[ch] = total
                total += 1

        if self.debug:
            print("  got {} chars, ${:04x} bytes.".format(total, total *8))
            print("  writing charset and screen")
        self.write_prg_file(self.DST_CHARSET_FILE, self.dst_charset, 0x2000)
        self.write_prg_file(self.DST_SCREEN_FILE, self.dst_screen, 0x1c00)


    def copy_sprite_column(self, src_col, dst_col):
        """
        Copy char row from bitmap into sprite
        """

        # column
        src = src_col * 8

        for y in range(40):

            offset = (int)(y / 8) * self.DST_WIDTH_CHARS * 8 + (y & 0x07)

            if y < 20:
                dst = self.SPR_XPOS[dst_col] + y * 3
            else:
                dst = self.SPR_XPOS[dst_col] + 0x100 + ((y - 21) * 3)

            print("y: {}, dst = {}, src = {}, src-offset = {}".format(
                y, dst, src, offset))
            print("${:04x} = ${:04x}: {:02x}".format(dst, src+offset,
                self.dst_bitmap[src + offset]))
            self.dst_sprites[dst + 3] = self.dst_bitmap[src + offset]



    def create_sprites(self):
        """
        Generate sprites:

        1 char of 'w', 3 chars of 'w' for the left border, 3 chars of 'e' amd
        1 char of 'e' for the right border for 'world wide'.
        """

        for s, d in [(40, 2), (41, 3), (42,4), (43, 5),
                     (5, 6), (6, 7), (7, 8), (8, 9)]:
            self.copy_sprite_column(s, d)

        self.write_prg_file('data/nw-wwe-sprites.prg', self.dst_sprites, 0x2000)

    def invert_bitmap(self):
        self.src_bitmap = [b ^ 0xff for b in self.src_bitmap]


    def convert(self):
        """
        Run all conversion steps
        """
        self.invert_bitmap()
        self.reduce_bitmap()
        self.create_charset()
        self.create_sprites()




def main():
    """
    Driver: convert bitmap to charset
    """
    converter = LogoConverter()
    converter.convert()


if __name__ == '__main__':
    main()

