import sys
import os

def txt_to_bin(txt_filename, bin_filename):
    """Convertit un fichier TXT SimulIDE en fichier binaire .bin"""
    with open(txt_filename, 'r') as txt_file, open(bin_filename, 'wb') as bin_file:
        for line in txt_file:
            bytes_list = [int(value) for value in line.strip().split(',') if value]
            bin_file.write(bytearray(bytes_list))

def bin_to_txt(bin_filename, txt_filename):
    """Convertit un fichier binaire .bin en fichier TXT compatible SimulIDE"""
    with open(bin_filename, 'rb') as bin_file, open(txt_filename, 'w') as txt_file:
        data = bin_file.read()
        for i in range(0, len(data), 16):
            line = ', '.join(f"{byte:3d}" for byte in data[i:i+16])
            txt_file.write(line + '\n')

def main():
    """Détecte automatiquement le type du fichier et effectue la conversion"""
    if len(sys.argv) != 2:
        print("Utilisation : python conversion.py <fichier.data> ou <fichier.bin>")
        sys.exit(1)

    input_file = sys.argv[1]
    if not os.path.isfile(input_file):
        print(f"Erreur : Le fichier '{input_file}' n'existe pas.")
        sys.exit(1)

    filename, ext = os.path.splitext(input_file)

    if ext.lower() == ".data":
        output_file = filename + ".bin"
        txt_to_bin(input_file, output_file)
        print(f"Conversion réussie : '{input_file}' → '{output_file}'")
    elif ext.lower() == ".bin":
        output_file = filename + ".data"
        bin_to_txt(input_file, output_file)
        print(f"Conversion réussie : '{input_file}' → '{output_file}'")
    else:
        print("Erreur : Extension non reconnue. Utilisez un fichier .data ou .bin")
        sys.exit(1)

if __name__ == "__main__":
    main()
