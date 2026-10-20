# SafeCrack Pro

**English** · [Português](README.md)

A digital safe written in SystemVerilog for the Altera **DE2-115** board. A four-digit password (0–9) is entered one digit at a time with push buttons and checked by a finite state machine (FSM); the result is shown on the LEDs.

Course project for CIN0130 — Digital Systems (CIn/UFPE, 2026.1), Prof. Victor Medeiros.

## Video

[Watch the project video on YouTube](https://youtu.be/_vgWMApheu0?si=FNMOXqHvSTn_HW01).

## Repository layout

```
.
├── rtl/
│   ├── safecrackpro_top.sv         # top level: pins, FSM and decoders
│   ├── safecrack.sv                # FSM: editing, checking and LEDs
│   └── bcd_to_7segment_anodo.sv    # BCD -> 7-segment decoder
├── README.md
└── README.en.md
```

## How it works

The design keeps four 4-bit registers (`register3`–`register0`), shown on **HEX3–HEX0**. **HEX4** shows the index (1–4) of the digit being edited.

| Button   | Port       | Function                                  |
|----------|------------|-------------------------------------------|
| `KEY[3]` | `btn_inc`  | Increment the active digit (9 → 0)        |
| `KEY[2]` | `btn_dec`  | Decrement the active digit (0 → 9)        |
| `KEY[1]` | `key_conf` | Confirm the digit and move on             |
| `KEY[0]` | `rst`      | Reset                                     |

Usage:

1. At each position, adjust the value with increment/decrement and confirm with `key_conf`.
2. Digits are edited in order, from HEX3 to HEX0. There is no going back to a confirmed digit; use reset to start over.
3. Confirming the fourth digit compares the entry with the configured password:
   - **correct**: green LEDs (`LEDG`) on for 5 s;
   - **incorrect**: red LEDs (`LEDR`) on for 3 s.
4. When the time is up, the system returns to its initial state.

### Password

The password is fixed at synthesis time by the constants `pass0`–`pass3` in `rtl/safecrack.sv`, compared against `register0`–`register3`. With the current values, HEX3 → HEX0 must read **9 · 3 · 7 · 2** to unlock.

## Architecture

| Module                  | Responsibility |
|-------------------------|----------------|
| `safecrackpro_top`      | Wires the FSM to the board ports and instantiates five 7-segment decoders. |
| `safecrack`             | One-hot FSM (16 states): per-digit editing (`A`–`D` plus helper states `*_INC`/`*_DEC`), `CHECK`, `CORRECT`, `WRONG` and `WAIT`. |
| `bcd_to_7segment_anodo` | Decodes BCD (0–9) to common-anode, active-low 7-segment patterns; invalid values show a dash. |

Design notes:

- **One action per press.** Each button goes through an edge detector (the `KEY` is inverted and compared with its previous-cycle value), so holding a button does not repeat the action.
- **Single-cycle edits.** The `*_INC`/`*_DEC` states last one clock cycle, change only the active digit's register and return to the parent state, with explicit wrap-around.
- **Timing.** `WAIT` counts `delay_cnt` down from `5 × ONE_SECOND` or `3 × ONE_SECOND`. `ONE_SECOND` is `50_000_000` (50 MHz clock) and is a local constant of `safecrack`; shorten it in the source to simulate.
- **Persistent result.** The `was_correct` flag keeps the right LED colour on throughout `WAIT`.

## State diagram

The `WAIT` state was added after this diagram, which is the first version drawn in class. Reset sends any state to `A` and is omitted for readability.

<img width="1147" height="740" alt="FSM state diagram" src="https://github.com/user-attachments/assets/aa8b43a0-6a1a-4b2f-88b2-58997d26d804" />

## Pin mapping (DE2-115)

Inputs:

| Port       | Board signal | Pin       |
|------------|--------------|-----------|
| `clk`      | `CLOCK_50`   | `PIN_Y2`  |
| `rst`      | `KEY[0]`     | `PIN_M23` |
| `key_conf` | `KEY[1]`     | `PIN_M21` |
| `btn_dec`  | `KEY[2]`     | `PIN_N21` |
| `btn_inc`  | `KEY[3]`     | `PIN_R24` |

Outputs (assign pins according to the standard DE2-115 `.qsf`, which is not part of this repository):

| Port          | Board signal             |
|---------------|--------------------------|
| `seg_pos4`    | `HEX3` (first digit)     |
| `seg_pos3`    | `HEX2`                   |
| `seg_pos2`    | `HEX1`                   |
| `seg_pos1`    | `HEX0` (last digit)      |
| `seg_cur_pos` | `HEX4` (active digit)    |
| `led_red`     | `LEDR[17:0]`             |
| `led_green`   | `LEDG[8:0]`              |

## Simulation

The testbench used in the course (`safecrack_tb.sv`) is not included in this repository. It exercised two scenarios — a wrong password (red LEDs) and the correct one (green LEDs), with a 0 → 9 wrap-around — with `ONE_SECOND` reduced to 5. The waveform below comes from that run.

<img width="1843" height="284" alt="Simulation waveform" src="https://github.com/user-attachments/assets/2b122b17-8163-453d-89e0-ad93b2a580b0" />

To reproduce it on [EDA Playground](https://edaplayground.com), paste `rtl/safecrack.sv` into *design.sv* and the testbench into *testbench.sv*, pick a SystemVerilog simulator, tick *Open EPWave after run* and run.

## Building and programming

In Quartus Prime:

1. Create a project for the DE2-115 device (Cyclone IV E, `EP4CE115F29C7`).
2. Add the files in `rtl/` and set `safecrackpro_top` as the top-level entity.
3. Import the DE2-115 pin assignments and map the ports as in the table above.
4. Compile and program the `.sof` with the Programmer.

## Known issues

- **Reset polarity.** The sequential block uses `posedge rst`, i.e. active-high reset, while the DE2-115 `KEY`s are active-low. On the board, reset only behaves as expected if the signal is inverted before reaching the FSM.
- **No synchronizer.** Buttons are sampled directly, without a two-flop synchronizer, leaving a theoretical metastability risk. In practice the DE2-115 `KEY`s are debounced in hardware.
- **1-based index.** HEX4 shows `position + 1` (1–4). For a 0–3 range, remove the increment where the decoder is instantiated in `safecrackpro_top`.
- **No backward navigation.** This is intentional and follows the specification; correction is done via reset.
