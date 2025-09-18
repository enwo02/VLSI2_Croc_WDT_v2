# Extending CROC SoC with a Hardware Watchdog

This repository contains the implementation and evaluation of a **hardware watchdog** integrated into the [CROC SoC](https://arxiv.org/abs/2502.05090), developed as part of the **VLSI 2 course project (ETH Zürich, Spring 2025)**.  

**Authors:** Miguel Correa and Elio Wanner  
**Supervision:** Prof. Frank Kagan Gürkaynak  

---

## 📌 Project Overview
CROC SoC is a lightweight, open-source RISC-V SoC designed for education and rapid prototyping. Its modular *user_domain* allows students to extend the base design with new components.  

To improve robustness during development and post-tapeout testing, we designed and integrated a **single-stage hardware watchdog**. The watchdog detects processor stalls or bus deadlocks and triggers a chip-wide reset to return the SoC to a known-good state.  

**Objectives:**
- Reliable fault detection (stalls, deadlocks)  
- Automatic recovery (system-wide reset)  
- Minimal area/power overhead  

---

## 🛠 Features
- **Simple count-up watchdog** with configurable timeout  
- **OBI-protocol wrapper** for memory-mapped access  
  - `0x00` → Kick register  
  - `0x04` → Timeout configuration (R/W)  
- **System-wide reset pulse** upon timeout  
- **Lightweight software runtime** for watchdog control  
- Verified with **SystemVerilog testbenches** and Python-based stimulus/response generators  

---

## ✅ Results
- 32 randomized test cases **all passed**  
- RTL simulations confirmed correct reset behavior  
- Physical design passed **DRC and LVS** checks with zero violations  
- **Area cost:**  
  - Watchdog core: ~3859 µm² (0.5% of `i_croc`)  
  - With wrapper: ~8582 µm² (1.1% of `i_croc`)  
- Negligible power impact  
- Significantly improved SoC robustness  

---

## 🚀 Future Work
- Pre-reset warnings (soft timeout signal)  
- Failure context logging (e.g., PC snapshot)  
- Configurable reset behavior (soft vs hard reset)  
- Multi-watchdog support for multi-core systems  
- Tape-out and silicon validation  

---
