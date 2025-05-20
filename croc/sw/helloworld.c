// Copyright (c) 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0/
//
// Authors:
// - Miguel Correa <corream@ethz.ch>
// - Elio Wanner <ewanner@ethz.ch>

#include "config.h"
#include "gpio.h"
#include "print.h"
#include "timer.h"
#include "uart.h"
#include "util.h"
#include "watchdog.h"

int main() {
  uart_init(); // setup the uart peripheral

  printf("Hello World!\n");
  uart_write_flush();

  /* ---------- Print the contents of the user ROM ------------------- */
  printf("Test from the work of: ");

  const volatile char *rom_ptr = (const volatile char *)USER_ROM_BASE_ADDR;
  while (*rom_ptr != '\0') { // walk the string until NUL
    putchar(*rom_ptr++);     // uart_putchar() aliased by putchar()
  }
  putchar('\n');
  uart_write_flush();
  /* ----------------------------------------------------------------- */

  /* ---------- Watchdog demo (unchanged) ---------------------------- */
  printf("Watchdog test\n");
  uart_write_flush();

  watchdog_set_timeout(200 * 1000);
  watchdog_kick();

  asm volatile("nop; nop; nop; nop; nop; nop; nop; nop;");

  watchdog_kick();
  printf("Dog kicked :) !\n");

  printf("Watchdog test end\n");
  uart_write_flush();

  /* ---------- Main loop ------------------------------------------- */
  uint32_t i = 0;

  printf("This is the main program now!\n");
  while (1) {
    watchdog_kick();
    printf("Dog kicked :)!\n");
    asm volatile("nop; nop; nop; nop; nop; nop; nop; nop;");

    if (i == 3) {
      printf("I will be stuck in an infinite loop!\n");
      uart_write_flush();
      while (1)
        ;
    }
    i++;
  }

  return 1;
}
