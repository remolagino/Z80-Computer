import serial
import time
from pathlib import Path

comport = input("Entrez le port COM (par exemple COM6 ou /dev/ttyUSB1) : ")

ser = serial.Serial(comport, 115200, timeout=1)

def send_line(line):
    print(f"Sent -> {line}")
    ser.write((line + "\r\n").encode('iso8859_15'))

def send_ack():
    ser.write(b'\x06')
    print("ACK")

def send_Nack():
    print("NACK")
    ser.write(b'\x15')

    
def main():

    dir = Path.cwd()
    print(dir)

    while True:
        line = ser.readline().decode('iso8859_15').strip()
        if not line:
            continue
        print(f"Received -> {line}")
        cmd, _, arg = line.partition(" ")
        if cmd == "ls":
            ls(dir, arg)
        elif cmd == "cd":
            dir = cd (dir, arg)
        elif cmd == "cat":
            cat (dir, arg)
        elif cmd == "run":
            run (dir, arg)
        elif cmd == "cwd":
            send_line(f"Répertoire courant : {dir.as_posix()}")
        else:
            send_line(f"Commande inconnue : {cmd}")
        time.sleep(0.1)
        send_ack()
        # Ajoute "load", "save", etc. ici

def cat(dir, arg):
    file = Path(dir, arg)
    print(f"Dir : {dir} - Arg : {arg}")
    if not file.is_file():
        send_line(f"{arg} n'est pas un fichier")
        return
    with open(file, "rb") as f:
        data = f.read()
        chunk_size = 1  # Adjust depending on buffer size
        for i in range(0, len(data), chunk_size):
            ser.write(data[i:i+chunk_size])

def run(dir,arg):
    file= Path(dir, arg)
    if not file.is_file():
        send_Nack()
        send_line(f"{arg} n'est pas un fichier")
        return
    send_ack()
    size = file.stat().st_size
    print(f"Dir : {dir} - Arg : {arg} - Size : {size:04X}")
    ser.write(size.to_bytes(2, 'big'))
    with open(file, "rb") as f:
        data = f.read()
        print(f"Data size: {len(data):04X} bytes")
        chunk_size = 1  # Adjust depending on buffer size
        for i in range(0, len(data)): #, chunk_size):
            ser.write(data[i:i+chunk_size])
            if i % 1 == 0:
#                print(f"{i:04X} - {data[i]:02X}")
                time.sleep(0.001)

def cd(dir, arg):
    tmpDir = Path(dir, arg)
    if not tmpDir.is_dir():
        send_line("Chemin Introuvable")
        return dir
    send_line(tmpDir.resolve().as_posix())
    return tmpDir.resolve()

def ls(dir, arg):
    tmpDir = Path(dir, arg)
    if not tmpDir.is_dir():
        send_line("Not a directory")
        return
    dir = tmpDir
    send_line(f"Répertoire de {dir.as_posix()}")
    for entry in dir.iterdir():
        if entry.is_dir():
            send_line(f"<DIR>\t\t{entry.name}")
        elif entry.is_file():
            send_line(f"{entry.stat().st_size:>12}\t{entry.name}")
        else:
            send_line(f"<OTH>\t\t{entry.name}")
    return

if __name__ == "__main__":
    main()