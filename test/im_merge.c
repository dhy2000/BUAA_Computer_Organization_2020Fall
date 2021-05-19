#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define IM_SIZE 2048
unsigned int IM[IM_SIZE];

int main()
{
    FILE *fin = NULL;
    fin = fopen("code.txt", "r");
    if (!fin) {
        printf("Cannot find code.txt\n");
        return -1;
    }
    unsigned int word;
    int PC = 0;
    while (fscanf(fin, "%x", &word) != EOF) {
        IM[PC++] = word;
    }
    fclose(fin);
    fin = fopen("code_handler.txt", "r");
    if (!fin) {
        printf("Cannot find code_handler.txt, skipped this file.\n");
    }
    else {
        PC = 1120;
        while (fscanf(fin, "%x", &word) != EOF) {
            IM[PC++] = word;
        }
        fclose(fin);
    }
    
    FILE *fout = fopen("im_data.txt", "w");
    for (int i = 0; i < IM_SIZE; i++) {
        fprintf(fout, "%u\n", IM[i]);
    }


    return 0;
}