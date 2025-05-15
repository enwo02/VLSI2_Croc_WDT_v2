#!/usr/bin/env python3
"""
waveview.py – interactive VCD viewer built with vcdvcd + Bokeh
Author: ChatGPT (o3) – 2025-04-23

Usage examples
--------------
# list all signals inside the VCD
python waveview.py watchdog.vcd --list

# open an interactive viewer for selected signals
python waveview.py watchdog.vcd -s clk_i,sys_rst_o,counter_q -o watchdog.html

TO RUN: python waveview.py watchdog.vcd
"""
import argparse
import math
import sys
from pathlib import Path
from typing import List, Tuple

import numpy as np
from bokeh.layouts import column
from bokeh.models import Range1d
from bokeh.plotting import figure, output_file, save, show
from vcdvcd import VCDVCD            # API doc: see README §3 “API usage” :contentReference[oaicite:0]{index=0}


# -----------------------------------------------------------------------------
# helpers
# -----------------------------------------------------------------------------
_TIME_FACTORS = {
    "s": 1.0,
    "ms": 1e-3,
    "us": 1e-6,
    "ns": 1e-9,
    "ps": 1e-12,
    "fs": 1e-15,
}


def _timescale_to_seconds(vcd_timescale: dict) -> float:
    """Return multiplier that converts raw VCD timestamps to seconds."""
    magnitude = float(vcd_timescale.get("magnitude", 1))
    unit = vcd_timescale.get("unit", "ps")
    return magnitude * _TIME_FACTORS[unit]


def _tv_to_numpy(tv: List[Tuple[int, str]], resolution: float, width_hint: int = 1):
    """
    Convert a list of (time, value) pairs to two numpy arrays (t, v).

    * For 1-bit wires -> float(0/1)
    * For vectors    -> int(value, 2)
    * For real       -> float(value)
    Unknown (x/z) is represented as NaN.
    """
    t_lst, v_lst = [], []
    last_val = None
    for raw_t, raw_v in tv:
        if last_val is not None:                 # duplicate point for steps
            t_lst.append(raw_t * resolution)
            v_lst.append(last_val)
        last_val = _convert_value(raw_v)
        t_lst.append(raw_t * resolution)
        v_lst.append(last_val)
    return np.asarray(t_lst), np.asarray(v_lst)


def _convert_value(v: str) -> float:
    if v in ("x", "z"):
        return math.nan
    if v in ("0", "1"):             # scalar
        return float(v)
    if all(bit in "01" for bit in v):
        return float(int(v, 2))     # vector
    try:
        return float(v)             # real
    except ValueError:
        return math.nan


# -----------------------------------------------------------------------------
# main plot routine
# -----------------------------------------------------------------------------
def build_waveform(vcd_path: Path, signals: List[str], out_html: Path, autoshow: bool):
    vcd = VCDVCD(str(vcd_path))      # parses everything into memory
    res = _timescale_to_seconds(vcd.timescale)

    # if no explicit signals → use every scalar (& vector) wire
    if not signals:
        signals = sorted(
            name for name in vcd.references_to_ids.keys() if name not in ("$dumpvars",)
        )

    figs = []
    for sig_name in signals:
        # if sig_name not in vcd:
        #     print(f"Warning: signal “{sig_name}” not found, skipping.", file=sys.stderr)
        #     continue

        # sig = vcd[sig_name]
        try:
            sig = vcd[sig_name]            # vcdvcd __getitem__ is fine
        except KeyError:
            print(f"Warning: signal “{sig_name}” not found, skipping.", file=sys.stderr)
            continue
        t, y = _tv_to_numpy(sig.tv, res)

        p = figure(
            height=120,
            sizing_mode="stretch_width",
            tools="xpan,xwheel_zoom,box_zoom,reset,save",
            toolbar_location="above",
            title=sig_name,
        )
        p.step(t, y, mode="after", line_width=2)
        p.y_range = Range1d(start=min(np.nanmin(y), 0) - 0.5, end=max(np.nanmax(y), 1) + 0.5)
        p.xaxis.axis_label = "time [s]"
        figs.append(p)

    if not figs:
        sys.exit("No signals to display – nothing plotted.")

    layout = column(*figs, sizing_mode="stretch_both")
    output_file(out_html, title=f"Waveforms – {vcd_path.name}")
    save(layout)
    if autoshow:
        show(layout)
    print(f"Wrote {out_html}")


# -----------------------------------------------------------------------------
# CLI
# -----------------------------------------------------------------------------
def parse_args():
    ap = argparse.ArgumentParser(description="Interactive Bokeh viewer for VCD files.")
    ap.add_argument("vcd", type=Path, help="Value-Change-Dump file (*.vcd)")
    ap.add_argument(
        "-s",
        "--signals",
        type=str,
        help="Comma-separated list of signal names (hierarchical names as in the VCD). "
        "If omitted, every wire is plotted.",
    )
    ap.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("waveform.html"),
        help="Destination HTML file (default: waveform.html)",
    )
    ap.add_argument("--list", action="store_true", help="Print available signals and exit.")
    ap.add_argument("--no-show", action="store_true", help="Do not open a browser window.")
    return ap.parse_args()


def main():
    args = parse_args()
    if not args.vcd.exists():
        sys.exit(f"File not found: {args.vcd}")

    if args.list:
        vcd = VCDVCD(str(args.vcd), store_tvs=False)
        for name in sorted(vcd.references_to_ids):
            print(name)
        sys.exit(0)

    sigs = [s.strip() for s in args.signals.split(",")] if args.signals else []
    build_waveform(args.vcd, sigs, args.output, not args.no_show)


if __name__ == "__main__":
    main()
