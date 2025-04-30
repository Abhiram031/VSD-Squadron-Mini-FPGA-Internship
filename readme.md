# Task 1

## Objective
Understand and document the functionality of the provided Verilog code (`top.v`) intended for the VSDSquadron FPGA Mini Board.



### Overview of the Verilog Code
The Verilog design toggles an RGB LED to be preciese blue led will toggle on the VSDSquadron FPGA Mini Board.
An internal oscillator and counter generate signals to drive the LEDs, while a debug output is exposed through a test pin.

### Module Ports

| Port Name | Direction | Description |
| :-------- | :-------- | :----------- |
| `led_red` | Output | Controls the Red LED |
| `led_blue` | Output | Controls the Blue LED |
| `led_green` | Output | Controls the Green LED |
| `hw_clk` | Input | Hardware clock input (external) |
| `testwire` | Output | Test output signal |




### Internal Oscillator (SB_HFOSC):
The SB_HFOSC is an internal high-frequency oscillator primitive available in the iCE40 FPGA family. It provides a configurable internal clock source without requiring an external crystal or clock input.

**Key Features**

- Base frequency: 48 MHz.
- Supports division by 1, 2, 4, or 8 via a parameter.
- Clock Output Control:
  - Output can be enabled/disabled using input signals.
  - Oscillator keeps running internally even when output is disabled (to save enable time).
- Quick Startup:
    - Oscillator output becomes stable after 100 microseconds of power-up.

<p align="center">
  <img width="500" height="150" src="/images/1.png">
</p>

<details>
<summary> Pin Descriptions</summary>

| Pin Name | Direction | Purpose |
|:---------|:----------|:--------|
| `CLKHFPU` | Input | Power-up control (1 = power up oscillator) |
| `CLKHFEN` | Input | Clock output enable (1 = enable clock output) |
| `CLKHF` | Output | Oscillator clock output to be used in user logic |

**Note:**
- `CLKHFPU` and `CLKHFEN` must be held **low** for **100 microseconds** during the power-up phase.
- After 100 μs, set them **high** to start normal oscillator operation.

</details>

<details>
<summary> Division Settings (`CLKHF_DIV`)</summary>

| Setting | Output Frequency |
|:--------|:-----------------|
| `0b00` | 48 MHz (no division) |
| `0b01` | 24 MHz (divided by 2) |
| `0b10` | 12 MHz (divided by 4) |
| `0b11` | 6 MHz (divided by 8) |

</details>


<summary> Usage in Verilog</summary>

```verilog
// Instantiate the SB_HFOSC primitive
SB_HFOSC #(
  .CLKHF_DIV("0b10") // Set clock division: 0b10 = divide by 4  (48/4) → 12 MHz output
) u_SB_HFOSC (
  .CLKHFPU(1'b1),    // Power-up the oscillator (Active High)
  .CLKHFEN(1'b1),    // Enable clock output (Active High)
  .CLKHF(int_osc)    // Connect oscillator output to internal signal
);
```

  
----------

**Frequency Divider**:

- `frequency_counter_i` is a 28-bit register incremented on every rising edge of the internal oscillator clock (`int_osc`).

- Each bit of this binary counter toggles at half the frequency of the previous bit.  
  For example, bit 0 toggles at `int_osc/2`, bit 1 at `int_osc/4`, ..., bit 24 at `int_osc/2^{25}`.

- The internal oscillator (`SB_HFOSC`) runs at 48 MHz divided by 4 (`CLKHF_DIV = "0b10"`), so:

$$
f_{\text{int\_osc}} = \frac{48\,\text{MHz}}{4} = 12\,\text{MHz}
$$

- Therefore, bit 24 toggles at frequency:

$$
f_{\text{bit24}} = \frac{f_{\text{int\_osc}}}{2^{25}} = \frac{12 \times 10^{6}}{33,554,432} \approx 0.357\, \text{Hz}
$$

- The corresponding period is:

$$
T_{\text{bit24}} = \frac{1}{f_{\text{bit24}}} \approx \frac{1}{0.357} \approx 2.8\, \text{seconds}
$$

- In the code, the blue LED PWM input is connected to `frequency_counter_i[24]` via `testwire`:

- Since `frequency_counter_i[24]` toggles every ~2.8 seconds, the blue LED will blink ON and OFF with that period, creating a slow blinking effect.

- The PWM input here acts as a simple on/off signal (no pulse-width modulation), so the LED is fully ON when `testwire` is high and fully OFF when low.

<p align="center">
<img src="https://i.imgur.com/DnqtL9S.gif" width="500"/>
</p>

*This  generates a slow blinking LED from a high-frequency internal clock by using a binary counter as a frequency divider.*

**RGB Primitive: SB_RGBA_DRV**:

<p align="center">
  <img width="500" height="" src="/images/2.png">
</p>

  - RGB LED Driver block using the Lattice iCE40 UltraLite/UltraPlus FPGA primitive `SB_RGBA_DRV`. This hardware block provides high-current open-drain outputs optimized for directly driving RGB LEDs without external components.
  - 
**SB_RGBA_DRV Parameters Reference**

<table>
  <tr>
    <td valign="top" width="50%">

<h4>General Parameters</h4>

<table>
  <tr>
    <th>Parameter</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><code>CURRENT_MODE</code></td>
    <td>
      Selects current range mode:<br>
      • <code>0b0</code> = Full Current Mode<br>
      • <code>0b1</code> = Half Current Mode
    </td>
  </tr>
  <tr>
    <td><code>RGB0_CURRENT</code></td>
    <td>Sink current for <strong>RED</strong> LED channel</td>
  </tr>
  <tr>
    <td><code>RGB1_CURRENT</code></td>
    <td>Sink current for <strong>GREEN</strong> LED channel</td>
  </tr>
  <tr>
    <td><code>RGB2_CURRENT</code></td>
    <td>Sink current for <strong>BLUE</strong> LED channel</td>
  </tr>
</table>

</td>
<td valign="top" width="50%">

<h4>Current Setting Values</h4>

<table>
  <tr>
    <th>Binary Value</th>
    <th>Full Mode</th>
    <th>Half Mode</th>
  </tr>
  <tr>
    <td><code>0b000000</code></td>
    <td>0 mA (disabled)</td>
    <td>0 mA</td>
  </tr>
  <tr>
    <td><code>0b000001</code></td>
    <td>4 mA</td>
    <td>2 mA</td>
  </tr>
  <tr>
    <td><code>0b000011</code></td>
    <td>8 mA</td>
    <td>4 mA</td>
  </tr>
  <tr>
    <td><code>0b000111</code></td>
    <td>12 mA</td>
    <td>6 mA</td>
  </tr>
  <tr>
    <td><code>0b001111</code></td>
    <td>16 mA</td>
    <td>8 mA</td>
  </tr>
  <tr>
    <td><code>0b011111</code></td>
    <td>20 mA</td>
    <td>10 mA</td>
  </tr>
  <tr>
    <td><code>0b111111</code></td>
    <td>24 mA (max)</td>
    <td>12 mA (max)</td>
  </tr>
</table>

</td>
</tr>
</table>

<p><strong>Note:</strong> Default mode is <code>CURRENT_MODE = "0b0"</code> (Full Current Mode). Channels set to <code>0b000000</code> act as open-drain GPIOs. Accuracy: ±10%.</p>


**Usage in `top.v`**

- The `SB_RGBA_DRV` drives RGB LEDs using internal open-drain constant-current sinks, with **4 mA per channel** configured via `RGBx_CURRENT`.
- Only the **BLUE LED** is active (modulated via `testwire`), while **RED and GREEN are disabled** with static low inputs.


### .pcf File

- The PCF (Pin Constraint File) is used to assign physical FPGA pins to specific signals in your Verilog code.


| Signal     | FPGA Pin | Pin Name     | Notes |
|------------|-----------|--------------|-------|
| `led_red`   | 39        | RGB0         | Drives Red LED (always off in this demo)|
| `led_blue`  | 40        | RGB2         | Drives Blue LED via frequency counter |
| `led_green` | 41        | RGB1         | Drives Green LED (always off in this demo) |
| `hw_clk`    | 20        | IOB_25b_G3   | ✅ **Global Buffer Input (GBIN3)** — suitable for external clocks |
| `testwire`  | 17        | IOB_35b      | General-purpose PIO, outputs internal counter bit |

**⏲️ About GBIN Pin**
- The hw_clk signal is assigned to pin 20 (IOB_25b_G3), which is:

  - ✅ A GBIN3 (Global Buffer Input) pin
  - These pins are made to carry important signals like clocks into the FPGA.
  - Connects directly to the internal global clock network (via GBUF3)
  - That means your clock signal can reach all parts of the chip quickly and evenly *(low skew)*.
  - If you want to use the PLL , it expects the input clock to come from a GBIN pin.


<details>
<summary>📄 View Full Makefile</summary>

### 🔍 What This Makefile Does

This Makefile automates the full FPGA development cycle for the iCE40UP5K-based VSD Squadron Mini FPGA board — including synthesis, place & route, timing analysis, bitstream generation, flashing, UART connection, and cleanup.

---

**🔨 `build:` – Compile and Prepare Bitstream**

This section defines how to **synthesize**, **place & route**, **analyze timing**, and **generate a bitstream** from your Verilog design.

🛠️ yosys — Synthesis
Converts your Verilog source into a technology-mapped JSON file used by nextpnr.
```
yosys -DCPU_FREQ=$(CPU_FREQ) -q -p "synth_ice40 -abc9 -device u -dsp -top $(TOP) -json $(TOP).json" $(VERILOG_FILE)
```
- `DCPU_FREQ=$(CPU_FREQ)`: Passes a macro to the Verilog preprocessor.
- `abc9`: Uses advanced logic optimization.
- `device u`: Targets iCE40 UltraPlus family.
- `dsp`: Enables DSP inference.
- `top $(TOP)`: Specifies the top-level module.
- `json $(TOP).json`: Output for the next step.

📐 nextpnr-ice40 — Place & Route
Maps the synthesized logic to the FPGA layout.
```
nextpnr-ice40 --force --json $(TOP).json --pcf $(PCF_FILE).pcf --asc $(TOP).asc --freq $(BOARD_FREQ) --$(FPGA_VARIANT) --package $(FPGA_PACKAGE) --opt-timing -q
```

- `--json`: Input design file from Yosys.
- `--pcf`: Pin Constraint File for physical pin mapping.
- `--asc`: Output file to store the routed bitstream.
- `--freq`: Target frequency (in MHz).
- `--opt-timing`: Optimizes placement for timing.
⏱️ icetime — Timing Analysis
Performs static timing analysis to check if your design meets timing constraints.
```icetime -p $(PCF_FILE).pcf -P $(FPGA_PACKAGE) -r $(TOP).timings -d $(FPGA_VARIANT) -t $(TOP).asc
```

🧊 icepack — Final Bitstream Generation
Converts the ASCII .asc file into a binary .bin file suitable for flashing.
```
icepack -s $(TOP).asc $(TOP).bin
```
</details>

---


# Task 2

## UART Loopback on FPGA
Implementing a UART Loopback system using  It enables direct hardware-level echoing of received serial data, useful for verifying UART connectivity and debugging serial communications.

1. Top Module (top.v)

     - Inputs:
       - uartrx (UART receive pin)
        - hw_clk (hardware clock)
     - Outputs:
        - uarttx (UART transmit pin)
        - RGB LEDs (led_red, led_blue, led_green
   - Internal oscillator instantiated (SB_HFOSC) for clock generation
2. UART Transmitter Module (uart_tx_8n1.v)
   - Implements an 8N1 UART transmitter (8 data bits, No parity, 1 stop bit).
    
   - Inputs: clock (clk), byte to transmit (txbyte), and send trigger (senddata).
   - Outputs: transmit done flag (txdone) and UART transmit line (tx).
   - State machine with states: `IDLE` → `STARTTX` → `TXING` → `TXDONE`
   - On senddata trigger, sends start bit (low), then 8 data bits LSB first, then stop bit (high).
   - txbit output represents the current bit on UART TX line.


<p align="center">
  <img width="800" height="" src="/images/3.png">
</p>

**🔁 Loopback Logic**
The actual loopback logic is achieved with a direct wire:

```
assign uarttx = uartrx;
```
  - Any data received on the UART RX line is immediately transmitted back on the TX line.

 - No software or register buffering — this is ideal for basic UART cable or PC-side debugging.

  - The uart_tx_8n1.v module is not used in the top module


<p align="center">
  <img src="https://i.imgur.com/9GcBK83.gif" width="500"/><br/>
  <b>UART Loopback Demonstration in Tera Term</b>
</p>


