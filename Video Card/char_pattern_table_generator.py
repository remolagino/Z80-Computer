import sys
import argparse
from PIL import Image, ImageDraw, ImageFont

#!/usr/bin/env python3
"""
char_pattern_table_generator.py

"""

def printChar(char_data):
        for byte in char_data:
                line = ""
                for i in range(8):
                        if byte & (1 << (7 - i)):
                                line += "#"
                        else:
                                line += "."
                print(line)

def createLine(index, charData):
        line = "    DB "
        for val in charData:
                line += "0x%02X, " % val
        line = line[:-2]  # Remove last comma and space
        try:
            ch = chr(index)
            if ch.isprintable():
                safe = ch.replace("'", "\\'")
                line += " ; Char 0x%02X '%s'" % (index, safe)
            else:
                line += " ; Char 0x%02X" % index
        except Exception:
            line += " ; Char 0x%02X" % index
        return line
 
def getCharFromImg(img, x, y):
        char_data = []
        for j in range(8):
                byte = 0
                for i in range(8):
                        pixel = img.getpixel((x + 2*i, y + 2*j))
                        if pixel == (255, 255, 255,255):  # Assuming white is background
                                byte |= (1 << (7 - i))
                char_data.append(byte)
        return char_data

def main():
        img = Image.open("msx-charset.png")
        print(img.format, img.size, img.mode)
        charList = []
        for j in range(12,13):
            for i in range(0,32):
                charByteMap = getCharFromImg(img, 64+16*i, 48+16*j)
                print(charByteMap)
                printChar(charByteMap)
                base_index = 0 + 32*j + i
                prompt = "Confirm index 0x%02X (press Enter to keep, or enter new hex value): " % base_index
                user_in = input(prompt).strip()
                if user_in == "":
                    index = base_index
                else:
                    try:
                        # allow formats like "1A" or "0x1A"
                        index = int(user_in, 16)
#                        if not (0 <= index <= 0xFF):
                        if  (index<0 ):
                            print("Index out of byte range (0x00-0xFF), using default 0x%02X" % base_index)
                            index = base_index
                    except ValueError:
                        print("Invalid hex input, using default 0x%02X" % base_index)
                        index = base_index
                line = createLine(index, charByteMap)
                charList.append( (index, line) )
                print(line)
        charList.sort(key=lambda x: x[0])
        with open("char_pattern_table_Box.asm", "w") as f:
                f.write("; Pattern Generator Table\n")
                f.write(";  v9938 Text Mode 1\n")
                f.write("; Characters in 6*8, based on ISO 8859-15\n\n")
                f.write("Pattern_Generator_Table:\n")
                for index, line in charList:
                        f.write(line + "\n")            

if __name__ == "__main__":
        main()