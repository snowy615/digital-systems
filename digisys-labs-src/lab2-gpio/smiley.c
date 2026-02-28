// lab2-gpio/smiley.c
// Show heart by default, smiley on double-press of Button B

#include "hardware.h"

/* delay -- pause for n microseconds */
void delay(unsigned n)
{
    unsigned t = 2*n;
    while (t > 0) {
        /* 500nsec per iteration at 16MHz */
        nop(); nop(); nop();
        t--;
    }
}

/* Heart image */
// 0x28f0, 0x5e00, 0x8060
const image heart = IMAGE(0,1,0,1,0,
                          1,1,1,1,1,
                          1,1,1,1,1,
                          0,1,1,1,0,
                          0,0,1,0,0);

/* Small heart image */
// 0x2df0, 0x5fb0, 0x8af0
const image small = IMAGE(0,0,0,0,0,
                          0,1,0,1,0,
                          0,1,1,1,0,
                          0,0,1,0,0,
                          0,0,0,0,0);

                          

/* Smiley image */
const image smiley = IMAGE(0,1,0,1,0,
                           0,1,0,1,0,
                           0,0,0,0,0,
                           1,0,0,0,1,
                           0,1,1,1,0);

#define JIFFY 5000              /* Delay in microsecs */
#define DOUBLE_CLICK 300000     /* Max gap between clicks in microsecs */

/* show -- display three rows of a picture n times */
void show(const unsigned img[], int n)
{
    while (n-- > 0) {
        for (int p = 0; p < 3; p++) {
            GPIO_OUT = img[p];
            delay(JIFFY);
        }
    }
}

/* pressed -- test if a button is pressed */
int pressed(int button)
{
    //check if pin is low = 0 = pressed
    return (GPIO_IN & BIT(button)) == 0;
}

/* init -- main */
void init(void)
{
    GPIO_DIR = 0xfff0; // pins 4-15 = LED output
    GPIO_PINCNF[BUTTON_A] = 0; //button A = input
    GPIO_PINCNF[BUTTON_B] = 0; //button B = input

    /* Set row pins to high-drive mode to increase brightness */
    SET_FIELD(GPIO_PINCNF[ROW1], GPIO_PINCNF_DRIVE, GPIO_DRIVE_S0H1);
    SET_FIELD(GPIO_PINCNF[ROW2], GPIO_PINCNF_DRIVE, GPIO_DRIVE_S0H1);
    SET_FIELD(GPIO_PINCNF[ROW3], GPIO_PINCNF_DRIVE, GPIO_DRIVE_S0H1);

    int showing_smiley = 0; // 0 = heart 1 = smile

    while (1) {
        /* Button A: show small heart while held */
        if (pressed(BUTTON_A)) {
            show(small, 1);
        }
        /* Check for first press of Button B (double-click toggle) */
        else if (pressed(BUTTON_B)) {
            /* Wait for release */
            while (pressed(BUTTON_B))
                show(showing_smiley ? smiley : heart, 1);

            /* Wait for second press within the time window */
            unsigned timeout = DOUBLE_CLICK / (JIFFY * 3);
            int double_clicked = 0;
            for (unsigned i = 0; i < timeout; i++) {
                if (pressed(BUTTON_B)) {
                    double_clicked = 1;
                    /* Wait for release */
                    while (pressed(BUTTON_B))
                        show(showing_smiley ? smiley : heart, 1);
                    break;
                }
                show(showing_smiley ? smiley : heart, 1);
            }

            if (double_clicked) {
                showing_smiley = !showing_smiley;
            }
        } else {
            show(showing_smiley ? smiley : heart, 1);
        }
    }
}
