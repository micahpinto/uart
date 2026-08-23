# uart
A complete UART transmitter and receiver module for the Arty S7-25 FPGA board.
Full-duplex UART communication at 9600 baud. TX continuously transmits an 8-bit frame. RX receives frames and outputs the reconstructed byte.

# uart tx
Continuously sends data, here an example- 0xE2 (11100010) over the TX line after reset is released, allowing verification of baud rate accuracy and frame structure on real hardware.
## Specification
**Hardware:** Arty S7-25 (Xilinx Artix-7) 

**Clock:** 100 MHz (onboard oscillator) 

**Baud Rate:** 9600 bps and **Each Bit=** 10,417 clock cycles

**Frame:** 1 start bit + 8 data bits (LSB first) + 1 stop bit 

[START(0)] [D0 D1 D2 D3 D4 D5 D6 D7] [STOP(1)] 

**Output:** Serial TX line (R12 to USB-to-UART converter)

## Design

The transmitter uses a finite state machine that cycles through four states:
1. **IDLE** — TX line held high, waiting to begin
2. **START_BIT** — Pulls TX low for one bit period
3. **DATA_BITS** — Outputs 8 data bits, one per bit period, LSB first
4. **STOP_BIT** — Pulls TX high for one bit period, then returns to IDLE
Timing is derived from the 100 MHz clock. Each bit period is ~10,417 clock cycles (100 MHz ÷ 9600 baud).
The module continuously transmits without requiring external control signals. Once reset is released, it begins transmission immediately and repeats the frame indefinitely.

## Simulation

Each component was tested individually in simulation:
- Testbench applies clock and reset
- Samples TX output at the middle of each bit period
- Verifies each bit matches the expected frame
- Prints PASS/FAIL for each of the 10 bits
- Confirms correct overall transmission

## Hardware

Programmed on the Arty S7-25 and verified using RealTerm serial terminal:
- Connected USB to PC
- Opened RealTerm at COM4, 9600 baud, Hex display
- Observed repeated `E2 E2 E2 E2 ...` on screen (0xE2 is the transmitted byte)
This confirms correct baud rate, frame structure, and timing on real hardware.
