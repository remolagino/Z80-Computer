import serial
import time
import sys  # Importer sys pour récupérer les arguments

# Vérifier si un argument est fourni
if len(sys.argv) < 2:
    print("Usage: python uploadrom.py <nom_du_fichier>")
    sys.exit(1)
    
filename = sys.argv[1]  # Récupérer le nom du fichier

print(f"Chargement du fichier : {filename}")

    
# Open serial port (adjust COM port for Windows or /dev/ttyUSBx for Linux/Mac)
#ser = serial.Serial('COM3', 115200, timeout=1)  # Change COM3 to your port
#ser = serial.Serial('/dev/ttyACM0', 115200, timeout=1)  # Change COM3 to your port
ser = serial.Serial('com9', 115200, timeout=1)  # Change COM3 to your port
time.sleep(2)  # Wait for the Arduino to reset

def read_arduino_feedback():
    """Lit et affiche les messages envoyés par l'Arduino"""
    while ser.in_waiting > 0:  # Vérifie s'il y a des données à lire
        line = ser.readline().decode('utf-8').strip()
        if line:
            print(f"Arduino-> {line}")


  
# Open the file in binary mode
with open(filename, "rb") as f:
    data = f.read()

# Convertir la taille en hexadécimal
hex_size = f"{len(data):X}"  # Taille en HEX sans préfixe 0x
hex_size_bytes = (hex_size + "\n").encode()  # Convertir en bytes
print(f"Taille du fichier : {hex_size} - " + str(len(data)))

print("Effaçage de la ROM" )
ser.write(b'e')
ser.write(b'\n')

time.sleep(0.5)
read_arduino_feedback()  # Lire les messages avant l'envoi du fichier
ser.write(b'h')
ser.write(b'\n')
# Attendre la réponse de l'Arduino avant d'envoyer les données
time.sleep(0.5)

# Send file size first
ser.write(b't')
ser.write(hex_size_bytes)  # Send  bytes for file size
#ser.write(b'\n')

# Attendre la réponse de l'Arduino avant d'envoyer les données
time.sleep(0.05)
read_arduino_feedback()  # Lire les messages avant l'envoi du fichier

# Send the file in chunks
chunk_size = 128  # Adjust depending on buffer size
for i in range(0, len(data), chunk_size):
    ser.write(data[i:i+chunk_size])
    time.sleep(0.05)  # Give Arduino time to process
    print(f"0x{i:04x} - ", end='')
    read_arduino_feedback()  # Lire les messages au fur et à mesure
print("File sent successfully!")
read_arduino_feedback()  # Lire dernier message
time.sleep(0.1)  # Pause pour laisser l'Arduino préparer les données

print("Vérification du contenu de la ROM")

# Envoi de la commande pour lire la ROM
ser.write(b'b')  # Commande pour recevoir tout le contenu de la ROM
ser.write(hex_size_bytes)  # Envoi de la taille du fichier
time.sleep(0.05)  # Pause pour laisser l'Arduino préparer les données
print("->")
# Lire la ROM en plusieurs morceaux
rom_data = bytearray()
while len(rom_data) < len(data):
    print(f" - {len(rom_data)}", end="")
    chunk = ser.read(16)  # Lire ce qui reste à lire
#    chunk = ser.read(len(data) - len(rom_data))  # Lire ce qui reste à lire
    if not chunk:  # Si rien n'est reçu, sortie de boucle (timeout atteint)
        break
    rom_data.extend(chunk)

print()
print(f"Nombre de bytes lu : {len(rom_data)}")
# Vérification des différences
errors = 0
for i in range(len(rom_data)):
    if data[i] != rom_data[i]:
        print(f"Erreur à l'adresse {i:04X} : attendu {data[i]:02X}, lu {rom_data[i]:02X}")
        errors += 1
    if errors>10:break

# Résumé des erreurs
if errors == 0:
    print("✅ Vérification réussie : La ROM est correctement programmée !")
else:
    print(f"❌ Vérification échouée : {errors} erreurs détectées.")
    
    
ser.close()