import serial
import time
from pathlib import Path

comport = input("Entrez le port COM (par exemple COM6 ou /dev/ttyUSB1) : ")

ser = serial.Serial(comport, 57600, timeout=1)

def send_line(line):
    print(f"Sent -> {line}")
    ser.write((line + "\r\n").encode('iso8859_15'))
    time.sleep(0.002)

def send_eot():
    time.sleep(0.01)
    ser.write(b'\x04')
    time.sleep(0.01)
    print("EOT")
    
def send_ack():
    time.sleep(0.01)
    ser.write(b'\x06')
    time.sleep(0.01)
    print("ACK")

def send_Nack():
    time.sleep(0.01)
    print("NACK")
    ser.write(b'\x15')
    time.sleep(0.01)

    
def main():

    dir = Path.cwd()
    print(dir)

    while True:
        line = ser.readline().decode('iso8859_15').strip()
        if not line:
            continue
        print(f"Received -> {line}")
        cmd, _, arg = line.partition(" ")
        arg = arg.strip()
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
            send_Nack()
#            time.sleep(0.001)
            send_line(f"Commande inconnue : {cmd}")
#        time.sleep(0.1)
        send_eot()
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
    if not arg.endswith(".bin"):
        arg=arg+".bin"
    file= Path(dir, arg)

    if not file.is_file():
        send_Nack()
        time.sleep(0.001)
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
            ser.flush()
#            if i % 2 == 0:
#                print(f"{i:04X} - {data[i]:02X}")
            time.sleep(0.002)
#        time.sleep(0.01)

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