/* @DIR x3600-radio@/remote.c */
/* Copyright (c) 2020 J. M. Spivey */

#include "microbian.h"
#include "hardware.h"
#include "lib.h"

#define GROUP 17

int TIME = 1000;

static const image dot =
    IMAGE(0,0,0,0,0,
          0,0,0,0,0,
          0,0,1,0,0,
          0,0,0,0,0,
          0,0,0,0,0);

static const image letter_B =
    IMAGE(1,1,1,0,0,
          1,0,0,1,0,
          1,1,1,0,0,
          1,0,0,1,0,
          1,1,1,0,0);

void receiver_task(int dummy)
{
    byte buf[RADIO_PACKET];
    int n;
    

    printf("Hello\n");
    display_show(letter_B);
    timer_delay(1000);
    display_show(blank);

    while (1) {
        n = radio_receive(buf);
        if (n == 1 && buf[0] == '1') {
            printf("Button A\n");
            int time = 0;
            display_show(dot);
            int crisis_averted = 0;
            while (time < 5000000) {
                if (GET_BIT(GPIO_IN, BUTTON_A) == 0) {
                    printf("Press A\n");
                    radio_send("1", 1);
                    crisis_averted = 1;
                    display_show(blank);
                    break;
                } else if (GET_BIT(GPIO_IN, BUTTON_B) == 0) {
                    printf("Press B\n");
                    radio_send("2", 1);
                }
                time++;
            }
            if (!crisis_averted){
                panic("Hot potato crisis!");
            }
            
        } else if (n == 1 && buf[0] == '2') {
            printf("Button B\n");
            display_show(letter_B);
        } else {
            printf("Unknown packet, length %d: %d\n", n, buf[0]);
        }
    }
}

void sender_task(int dummy)
{
    while (1) {
        if (GET_BIT(GPIO_IN, BUTTON_A) == 0) {
            printf("Press A\n");
            radio_send("1", 1);
        } else if (GET_BIT(GPIO_IN, BUTTON_B) == 0) {
            printf("Press B\n");
            radio_send("2", 1);
        }

        timer_delay(100);
    }
}

void init(void)
{
    serial_init();
    radio_init();
    radio_group(GROUP);
    timer_init();
    display_init();
    GPIO_PINCNF[BUTTON_A] = 0;
    GPIO_PINCNF[BUTTON_B] = 0;
    start("Receiver", receiver_task, 0, STACK);
    start("Sender", sender_task, 0, STACK);
}
