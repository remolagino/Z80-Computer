import serial
import time
import sys  # Importer sys pour récupérer les arguments

# Vérifier si un argument est fourni
if len(sys.argv) < 2:
    print("Usage: python uploadFile.py <nom_du_fichier>")
    sys.exit(1)
    
filename = sys.argv[1]  # Récupérer le nom du fichier

print(f"Chargement du fichier : {filename}")


def read_z80_feedback():
    """Lit et affiche les messages envoyés par l'Arduino"""
    while ser.in_waiting > 0:  # Vérifie s'il y a des données à lire
        line = ser.read().decode('utf-8').strip()
        if line:
            print(line,end='')


  
# Open the file in binary mode
with open(filename, "rb") as f:
    data = f.read()

# Convertir la taille en hexadécimal
hex_size = f"{len(data):X}"  # Taille en HEX sans préfixe 0x
#hex_size_bytes = (hex_size + "\n").encode()  # Convertir en bytes
print(f"Taille du fichier : 0x{hex_size} - " + str(len(data)) + " bytes")

print("Confirmer l'envoi du fichier ? (O/N)")
while True:
    confirmation = input().strip().upper()
    if confirmation == 'O':
        print("Envoi du fichier...")
        break
    elif confirmation == 'N':
        print("Annulation de l'envoi.")
        sys.exit(0)
    else:
        print("Veuillez entrer 'O' pour confirmer ou 'N' pour annuler.")

# Open serial port (adjust COM port for Windows or /dev/ttyUSBx for Linux/Mac)
ser = serial.Serial('COM6', 115200, timeout=1)  # Com4 FTDI adapter for Z80
time.sleep(0.1)  # Wait for the Arduino to reset

#read_z80_feedback()  # Lire les messages avant l'envoi du fichier

# Send the file in chunks
chunk_size = 1  # Adjust depending on buffer size
for i in range(0, len(data), chunk_size):
    ser.write(data[i:i+chunk_size])
#    time.sleep(0.005)  # Give Arduino time to process
    read_z80_feedback()  # Lire les messages au fur et à mesure

print()
print("File sent successfully!")
read_z80_feedback()  # Lire dernier message
time.sleep(0.1)  # Pause pour laisser le Z80 préparer les données


# File upload fini

print("✅ File Upload réussie : Le fichier est envoyé !")

    
ser.close()