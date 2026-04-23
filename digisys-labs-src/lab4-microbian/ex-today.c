// lab4-phos/today.c
// Copyright (c) 2018 J. M. Spivey

#include "microbian.h"
#include "lib.h"
#include <string.h>

static int INTERVIEWER;

void put_string(char *s) {
    for (char *p = s; *p != '\0'; p++)
        serial_putc(*p);
}

char *slogan[] = {
    "no deal is better than a bad deal\n",
    "BREXIT MEANS BREXIT!\n"
};

void process(int n) {
    while (1) {
        receive(PING, NULL); //receiving, wait for ping from interviewer
        timer_delay(2000); //delay for 2 seconds
        put_string(slogan[n]); //print slogan
        send_msg(INTERVIEWER, REPLY); //send to wake interviewer
    }
}

void interviewer(int dummy) { //dummy from start(), value given in init()
    int may_pid = dummy;
    int far_pid = dummy+1;
    while (1){
        send_msg(may_pid, PING); //send to wake may
        receive(REPLY, NULL); //receiving, wait for may to reply
        send_msg(far_pid, PING); //send to wake farage
        receive(REPLY, NULL); //receiving, wait for farage to reply
    }
}
    

void init(void) {
    serial_init();
    timer_init();
    int may = start("May", process, 0, STACK); //return May PID
    start("Farage", process, 1, STACK);
    INTERVIEWER = start("Interviewer", interviewer, may, STACK);
}
