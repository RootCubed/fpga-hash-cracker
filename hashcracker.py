import sys
import serial

full_charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVXYZ0123456789_"
alpha = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
lower = "abcdefghijklmnopqrstuvwxyz"
charset = full_charset

num_mod_chars = 8 # number of configurable charsets
num_extra_chars = 3 # number of extra hashing steps running in parallel

def hash(str, seed = 0x1505):
    hash = seed
    for c in str:
        hash = ((hash * 33) ^ ord(c)) & 0xFFFF_FFFF
    return hash

def undo_char(hsh, char):
    return ((hsh ^ ord(char)) * 1041204193) & 0xFFFF_FFFF

def undo_str(hsh, s):
    for char in reversed(s):
        hsh = undo_char(hsh, char)
    return hsh

def main():
    if len(sys.argv) != 2 and len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} hash:prefix:suffix:guesslen [seed]")
        return

    hash_in, prefix, suffix, guesslen_str = sys.argv[1].strip().split(":")
    guesslen = int(guesslen_str)

    seed_in = 0x1505
    if len(sys.argv) == 3:
        seed_in = int(sys.argv[2], 16)

    fpga_part_strings = list()

    if (guesslen > num_mod_chars + num_extra_chars) or (guesslen < 4):
        print(guesslen)
        print(f"Guess length must be between 4 and {num_mod_chars + num_extra_chars}")
        return

    ser = serial.Serial("COM4", 115200, timeout=1)
    ser.set_buffer_size(rx_size = 2**15, tx_size = 2**15)
    print("Connected to hash device.")

    charsextra = num_mod_chars + num_extra_chars - guesslen
    guesslenworkaround = "A" * charsextra

    for _ in range(charsextra):
        print("A")
        ser.write(("A\n").encode("UTF-8"))
    for _ in range(num_mod_chars - charsextra):
        print(charset)
        ser.write((charset + "\n").encode("UTF-8"))

    seed = undo_str(hash(prefix, seed_in), guesslenworkaround)
    goal = undo_str(int(hash_in, 16), suffix)

    print(hex(seed) + " " + hex(goal))

    ser.write([((seed >> i) & 0xFF) for i in range(0, 32, 8)])
    ser.write([((goal >> i) & 0xFF) for i in range(0, 32, 8)])

    line = ser.readline()
    if "START" not in line.decode("UTF-8"):
        print("Error starting hash device.")
        print("Reset it and try again.")
        sys.exit()

    print("Started hash device.")

    count = 0
    while True:
        try:
            line = ser.readline()
            line = line.decode("UTF-8").strip()
            count += 1
            if line == "" or line in fpga_part_strings:
                continue
        except Exception as e:
            print(e)
            break
        if line == "RESET":
            with open("part_strings.txt", "w") as f:
                f.write("\n".join(fpga_part_strings))
            print("debug: " + str(count - 1))
            print(f"Search space exhausted. {len(fpga_part_strings)} collisions found.")
            print(f"Run ./complete_collisions {hex(seed)} {hex(goal)} {charsextra} to conclude the search.")
            break

        fpga_part_strings.append(line)
        if (len(fpga_part_strings) % 500 == 0):
            print(f"Progress: {len(fpga_part_strings)} collisions found | latest collision: {line}")
    ser.close()

    with open("collisions.txt", "w") as f:
        f.write("\n".join(fpga_part_strings))

if __name__ == "__main__":
    main()