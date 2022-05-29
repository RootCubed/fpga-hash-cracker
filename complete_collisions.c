#include <stdio.h>
#include <stdint.h>
#include <io.h>
#include <stdlib.h>
#include <string.h>

uint32_t hash(uint32_t seed, char *str) {
    int pos = 0;
    while (str[pos] != 0) {
        seed = (seed * 33) ^ str[pos++];
    }
    return seed;
}

const char charset[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVXYZ0123456789_";
const int charsetSize = 62;

int main(int argc, char **argv) {
    if (argc != 4) {
        printf("Usage: complete_collisions <seed> <goal> <number of extra chars>\n");
        return -1;
    }
    FILE *fp, *fp_out;

    fp = fopen("collisions.txt", "r");
    if (fp == NULL)
        return -1;
        
    fp_out = fopen("collisions_full.txt", "w");

    char * line = NULL;
    size_t len = 0;
    size_t read;

    uint32_t seed = strtoul(argv[1], NULL, 16);
    uint32_t goalHash = strtoul(argv[2], NULL, 16);
    int numAs = strtoul(argv[3], NULL, 10);
    char strBuf[12];

    while ((read = getline(&line, &len, fp)) != -1) {
        strcpy(strBuf, line);
        strBuf[10] = '\0';
        for (int i = 0; i < charsetSize; i++) {
            for (int j = 0; j < charsetSize; j++) {
                strBuf[8] = charset[i];
                strBuf[9] = charset[j];
                strBuf[10] = '\0';
                uint32_t itmHash = hash(seed, strBuf) * 33;
                if ((goalHash ^ itmHash) > 0xFF) continue;
                char remChar = (char) (goalHash ^ itmHash);
                for (int k = 0; k < charsetSize; k++) {
                    if (charset[k] == remChar) {
                        strBuf[10] = remChar;
                        strBuf[11] = '\n';
                        strBuf[12] = '\0';
                        fwrite(strBuf + numAs, 12 - numAs, 1, fp_out);
                    }
                }
            }
        }
    }

    fclose(fp_out);
    fclose(fp);
}