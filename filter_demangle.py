import sys
import demangler
demangler.dem_nvidia = True

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
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <collision_file> hash:prefix:suffix")
        return

    hash_in, prefix, suffix = sys.argv[2].strip().split(":")
    goal_hash = int(hash_in, 16)

    col_file = sys.argv[1].strip()

    results = list()

    with open(col_file, "r") as f:
        while True:
            line = f.readline().strip()
            if line == "":
                break
            if hash(demangler.demangle(prefix + line + suffix)) == goal_hash:
                results.append(prefix + line + suffix)

    with open(col_file + ".filtered", "w") as f:
        f.write("\n".join(results))

if __name__ == "__main__":
    main()