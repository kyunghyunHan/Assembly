
#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>

static const char *vector_names[16] = {
    "Initial MSP",
    "Reset",
    "NMI",
    "HardFault",
    "MemManage",
    "BusFault",
    "UsageFault",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "SVCall",
    "DebugMon",
    "Reserved",
    "PendSV",
    "SysTick"
};

int main(void)
{
    FILE *fp = fopen("flash64.bin", "rb");

    if (fp == NULL) {
        perror("flash64.bin");
        return 1;
    }

    unsigned char data[64];

    if (fread(data, 1, sizeof(data), fp)
        != sizeof(data)) {
        fprintf(stderr, "64 bytes required\n");
        fclose(fp);
        return 1;
    }

    fclose(fp);

    printf("STM32 Vector Table\n\n");

    for (int i = 0; i < 16; i++) {
        int p = i * 4;

        uint32_t value =
            ((uint32_t)data[p]) |
            ((uint32_t)data[p + 1] << 8) |
            ((uint32_t)data[p + 2] << 16) |
            ((uint32_t)data[p + 3] << 24);

        printf("0x%08" PRIX32 "  %-12s  "
               "0x%08" PRIX32 "\n",
               UINT32_C(0x08000000) + (uint32_t)p,
               vector_names[i],
               value);

        if (i == 0) {
            printf("  -> Initial MSP\n");
        } else if (i == 1) {
            printf("  -> Reset Handler entry: "
                   "0x%08" PRIX32 "\n",
                   value & ~UINT32_C(1));

            printf("  -> Thumb bit: %u\n",
                   (unsigned)(value & 1U));
        }
    }

    return 0;
}
