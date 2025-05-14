// Copyright (c) 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0/
//
// Authors:
// - Elio Wanner <ewanner@ethz.ch>

#include "gpio.h"
#include "print.h"
#include "timer.h"
#include "uart.h"
#include "watchdog.h"
#include "util.h"

int main() {
    uart_init(); // setup the uart peripheral

    // simple printf support (only prints text and hex numbers)
    printf("Hello World!\n");
    // wait until uart has finished sending
    uart_write_flush();

  // using the watchdog
  printf("Watchdog test\n");
    uart_write_flush();

  watchdog_set_timeout(200 * 1000 );
  watchdog_kick();

  // wait 8 cycles
  asm volatile("nop; nop; nop; nop; nop; nop; nop; nop;");

  watchdog_kick();

  // wait 11 cycles
  asm volatile("nop; nop; nop; nop; nop; nop; nop; nop; nop; nop; nop;");
  
  // Here the reset should be active
  watchdog_kick();

  printf("Watchdog test end\n");
  printf(" \n");
    uart_write_flush();

  // Run forever
  uint32_t i = 0;
  while (1) {
    // Kick the watchdog and then do some things
    watchdog_kick();

    printf("This is the main program now!\n");
    asm volatile("nop; nop; nop; nop; nop; nop; nop; nop;");

    if (i==3) {
      printf("I will be stuck in an infinite loop!\n");
    uart_write_flush();
      while(1);
    }

    i++;
  }

    return 1;
}
