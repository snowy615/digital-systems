// lab4-microbian/ex-potato.c
// Hot Potato: A two-player radio game for micro:bit
//
// How to play:
// - Flash this program onto two (or more) micro:bits in the same room.
// - One micro:bit starts with the "potato" (a lit LED in the centre).
// - Press Button A to throw the potato to another micro:bit.
// - The potato gets "hotter" over time -- the display fills up.
// - If the display fills completely (all 25 LEDs lit), you lose!
// - After a loss, press Button B to restart.
//
// The potato timer decreases each round, making it progressively harder.

#include "microbian.h"
#include "hardware.h"
#include "lib.h"

#define GROUP 42
#define POTATO_MSG   'P'   // "here's the potato" 
#define ACK_MSG      'A'   // "I got it"

// Images
static const image happy =
    IMAGE(0,0,0,0,0,
          0,1,0,1,0,
          0,0,0,0,0,
          1,0,0,0,1,
          0,1,1,1,0);

static const image sad =
    IMAGE(0,0,0,0,0,
          0,1,0,1,0,
          0,0,0,0,0,
          0,1,1,1,0,
          1,0,0,0,1);

static const image dot =
    IMAGE(0,0,0,0,0,
          0,0,0,0,0,
          0,0,1,0,0,
          0,0,0,0,0,
          0,0,0,0,0);

// Fill patterns: each level lights more LEDs (centre outward)
// level 0 = just centre dot, level 5 = all lit = BOOM
static const image fill1 =
    IMAGE(0,0,0,0,0,
          0,0,0,0,0,
          0,0,1,0,0,
          0,0,0,0,0,
          0,0,0,0,0);

static const image fill2 =
    IMAGE(0,0,0,0,0,
          0,1,1,1,0,
          0,1,1,1,0,
          0,1,1,1,0,
          0,0,0,0,0);

static const image fill3 =
    IMAGE(0,0,0,0,0,
          0,1,1,1,0,
          1,1,1,1,1,
          0,1,1,1,0,
          0,0,0,0,0);

static const image fill4 =
    IMAGE(0,1,1,1,0,
          1,1,1,1,1,
          1,1,1,1,1,
          1,1,1,1,1,
          0,1,1,1,0);

static const image fill5 =
    IMAGE(1,1,1,1,1,
          1,1,1,1,1,
          1,1,1,1,1,
          1,1,1,1,1,
          1,1,1,1,1);

static const unsigned *fill_levels[] = {
    fill1, fill2, fill3, fill4, fill5
};

// Shared state between tasks
static volatile int has_potato = 0;  // 1 if we hold the potato
static volatile int heat_level = 0;  // 0-4, at 5 we lose
static volatile int game_over = 0;   // 1 if someone lost
static volatile int round_time = 3000; // ms before heat increases

// receiver_task -- listen for incoming radio packets
void receiver_task(int dummy)
{
    byte buf[RADIO_PACKET];
    int n;

    while (1) {
        n = radio_receive(buf);

        if (game_over) continue;

        if (n >= 1 && buf[0] == POTATO_MSG) {
            // We received the potato!
            has_potato = 1;
            heat_level = 0;

            // Reduce round time to make it harder (min 800ms)
            if (round_time > 800)
                round_time -= 200;

            // Send acknowledgement
            byte ack = ACK_MSG;
            radio_send(&ack, 1);
        }
    }
}

// sender_task -- handle button presses
void sender_task(int dummy)
{
    GPIO_PINCNF[BUTTON_A] = 0;
    GPIO_PINCNF[BUTTON_B] = 0;

    while (1) {
        // Button A: throw the potato
        if (GET_BIT(GPIO_IN, BUTTON_A) == 0 && has_potato && !game_over) {
            byte msg = POTATO_MSG;
            radio_send(&msg, 1);
            has_potato = 0;
            display_show(happy);
        }

        // Button B: restart the game (take the potato to start)
        if (GET_BIT(GPIO_IN, BUTTON_B) == 0 && game_over) {
            game_over = 0;
            has_potato = 1;
            heat_level = 0;
            round_time = 3000;
        }

        timer_delay(100);
    }
}

// heat_task -- the potato gets hotter over time
void heat_task(int dummy)
{
    while (1) {
        timer_delay(500);  // check every 500ms

        if (game_over || !has_potato) continue;

        // Increment heat based on elapsed time
        // We use a simple counter: every round_time ms, heat goes up
        timer_delay(round_time);

        if (!has_potato || game_over) continue;

        heat_level++;

        if (heat_level >= 5) {
            // BOOM! You lose!
            game_over = 1;
            has_potato = 0;
            printf("BOOM! You lose!\n");
        }
    }
}

// display_task_game -- update the display based on game state
void display_task_game(int dummy)
{
    int blink = 0;

    while (1) {
        timer_delay(200);

        if (game_over) {
            // Blink the sad face
            blink = !blink;
            if (blink)
                display_show(sad);
            else
                display_show(blank);
        } else if (has_potato) {
            // Show heat level
            if (heat_level < 5)
                display_show(fill_levels[heat_level]);
        } else {
            // We don't have the potato -- show happy face
            display_show(happy);
        }
    }
}

void init(void)
{
    serial_init();
    timer_init();
    radio_init();
    radio_group(GROUP);
    display_init();

    printf("Hot Potato!\n");
    printf("Press B to start with the potato\n");
    printf("Press A to throw it!\n");

    // Nobody starts with the potato -- press B to begin
    start("Receiver", receiver_task, 0, STACK);
    start("Sender", sender_task, 0, STACK);
    start("Heat", heat_task, 0, STACK);
    start("GameDisp", display_task_game, 0, STACK);
}