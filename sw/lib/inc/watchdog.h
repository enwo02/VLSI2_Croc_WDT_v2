/*  watchdog.h – very small driver for the CROc user-domain watchdog
 *
 *  Register map  (see watchdog_wrapper.sv):
 *    +0x00  W  Kick / Feed   – write **anything** to reset the counter
 *    +0x04 RW Timeout        – number of CLK cycles until reset
 *
 *  Base address comes from user_pkg::UserWatchdogAddrOffset = 0x2000_0000.
 */
#pragma once
#include <stdint.h>

/* --------  memory-mapped register addresses  -------- */
#define WDT_BASE      0x20000000u       /*  UserWatchdogAddrOffset            */
#define WDT_KICK_OFFS 0x00u             /*  kick register                     */
#define WDT_TO_OFFS   0x04u             /*  timeout register                  */

/* --------  tiny driver helpers  -------- */

/* Set the timeout in **clock cycles**.
 * Call this once after reset (or whenever you want to change it).        */
static inline void watchdog_set_timeout(uint32_t cycles)
{
    *(volatile uint32_t *)(WDT_BASE + WDT_TO_OFFS) = cycles;
}

/* Feed / kick the watchdog.  Call this periodically well before the
 * timeout expires – e.g. from the main loop, an RTOS tick hook, or a
 * timer interrupt.                                                        */
static inline void watchdog_kick(void)
{
    *(volatile uint32_t *)(WDT_BASE + WDT_KICK_OFFS) = 0x1u;   /* any value */
}
