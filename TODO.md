## ELIO
-Read papers (Zotero)
-WatchDog
-Start report watchdog
-Do we need to send the reset signal for longer than 1 cycle? Yess, at least 4 cycles (see rstgen_bypass.sv in croc/rtl/common_cells). Assistant said no, 1 cycle is enoguh
-Should we count down instead? Seems to be more common (Coleman) NO
-try and run with mig's testbench

## MIGUEL
- ideas
        - add pause to watchdog for debugging (when inserting break point doesn't count == idea from Coleman, see Zotero)
        - an interrupt can be enabled which will fire when the watchdog timer is getting close to expiration. In the interrupt handler, the software can decide to “feed” the watchdog to prevent the system from resetting
        - two stage ==> give chance to sw to recover (appnote_826_watchdog_1.0.0.pdf)
        - three stages ==> if sw not able to recover, give time to save state and know what went wrong.
-Start report tb
-Redo diagram with custom library

## WDT conventions
        +----------------------------------+
        |         Watchdog Module          |
        |                                  |
        |  +--------------------------+    |
        |  | Timeout Counter           |   |
        |  | - Increments on clock     |   |
        |  | - Resets on kick          |   |
        |  +--------------------------+    |
        |                                  |
        |  Inputs:                         |
        |  - clk_i   (Clock)               |
        |  - rst_ni  (Reset, active low)   |
        |  - kick_i  (OBI request signal)  |
        |  - timeout_i (Counter preset)    |
        |                                  |
        |  Output:                         |
        |  - sys_rst_o (System reset)      |
        +----------------------------------+

-The kick signal (kick_i) is connected to an OBI request signal (obi_req_i).
-42/42 inclusive.
-2 clocks at 0 when reset

## Report Structure

### Introduction
- Overview of the Croc SoC and its open-source nature
- Why a watchdog timer (WDT) was needed
- Goals and expected improvements

### Related Works
- Overview of existing watchdog timer implementation
- Justification for our approach

### Methodology
- Design choices for WDT (e.g., countdown vs. count-up, reset duration)
- Testing strategy (testbenches, simulation tools)
- Debugging and iteration process

### Watchdog Timer Implementations
#### v1 (One-stage WDT)
- RTL implementation details
- Testbench and verification
- Integration into Croc (area, power, and performance impact)

#### v2 (Two-stage WDT)
- RTL implementation details
- Testbench and verification
- Integration into Croc (area, power, and performance impact)

### Evaluation
- Simulation results for v1 and v2
- Performance comparison (goal achieved?)
- Trade-offs between versions

### Discussion
- Strengths and limitations of each approach
- Potential improvements (e.g., three-stage WDT)
- Lessons learned from the implementation

### Conclusion
- Summary of key findings
- Future work and next steps