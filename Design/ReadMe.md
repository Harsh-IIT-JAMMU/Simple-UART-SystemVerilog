# UART - SystemVerilog

## 📌 Overview

The TOP module integrates both **UART Transmitter (TX)** and **UART Receiver (RX)** into a single top-level design.

It allows:

* Sending parallel data through UART TX
* Receiving serial data through UART RX
* Sharing common clock and baud rate configuration

---

## ⚙️ Parameters

| Parameter   | Description                  |
| ----------- | ---------------------------- |
| `clk_freq`  | Input system clock frequency |
| `baud_rate` | UART communication baud rate |

These parameters are passed to both TX and RX modules to ensure synchronized operation.

---

## 🔌 Ports

| Signal        | Direction | Description                       |
| ------------- | --------- | --------------------------------- |
| `clk`         | Input     | System clock                      |
| `rst`         | Input     | Reset signal                      |
| `rx`          | Input     | Serial data input (UART RX line)  |
| `dintx[7:0]`  | Input     | Parallel data to transmit         |
| `newd`        | Input     | New data valid for transmission   |
| `tx`          | Output    | Serial data output (UART TX line) |
| `doutrx[7:0]` | Output    | Received parallel data            |
| `donetx`      | Output    | Transmission complete flag        |
| `donerx`      | Output    | Reception complete flag           |

---

## 🧠 Internal Architecture

The top module instantiates:

* **UART Transmitter (`uarttx`)**
* **UART Receiver (`uartrx`)**

Both modules operate independently but share:

* Same clock (`clk`)
* Same reset (`rst`)
* Same baud configuration

---

## 🔗 Module Instantiation

### UART Transmitter

```sv
uarttx #(clk_freq, baud_rate) utx (
  clk,
  rst,
  newd,
  dintx,
  tx,
  donetx
);
```

---

### UART Receiver

```sv
uartrx #(clk_freq, baud_rate) rtx (
  clk,
  rst,
  rx,
  donerx,
  doutrx
);
```

---

## 🔄 Data Flow

```text
          +-------------+        Serial Line        +-------------+
dintx --->|   UART TX   |-------------------------->|   UART RX   |---> doutrx
          +-------------+                           +-------------+
                |                                         |
             donetx                                   donerx
```

---

## ⚙️ Working

### Transmission Path

1. User provides data on `dintx`
2. Asserts `newd`
3. UART TX sends serial data on `tx`
4. `donetx` goes HIGH after completion

---

### Reception Path

1. Serial data arrives on `rx`
2. UART RX detects start bit
3. Receives 8-bit data
4. Outputs parallel data on `doutrx`
5. `donerx` goes HIGH when done

---

## 📊 Signal Summary

| Path | Input           | Output   | Status Signal |
| ---- | --------------- | -------- | ------------- |
| TX   | `dintx`, `newd` | `tx`     | `donetx`      |
| RX   | `rx`            | `doutrx` | `donerx`      |

---

## 🧩 Integration Notes

* TX and RX are **independent** but can be looped back for testing
* For loopback testing: connect `tx → rx`
* Both modules must use same baud rate for correct communication

---

## 🧪 Example Loopback Setup

```text
tx ------------------> rx
```

* Transmitted data will be received back internally
* Useful for simulation and verification

---

## ✅ Key Features

* Combines UART TX and RX in a single module
* Parameterized design (clock + baud rate)
* Clean modular architecture
* Supports full UART communication path
* Easy integration into larger systems


# UART Transmitter (SystemVerilog)

## 📌 Overview

`uart_tx.sv` implements a **UART (Universal Asynchronous Receiver/Transmitter) Transmitter** in SystemVerilog.

The module converts **8-bit parallel data** into a **serial UART frame** consisting of:

- 1 Start bit
- 8 Data bits (LSB first)
- 1 Stop bit

The design also includes an internal baud-rate clock generator.

---

# ⚙️ Parameters

| Parameter | Description |
|---|---|
| `clk_freq` | Input system clock frequency |
| `baud_rate` | Desired UART baud rate |

---

## Baud Clock Calculation

```text
ratio = clk_freq / baud_rate
```

Example:

```text
clk_freq  = 1,000,000 Hz
baud_rate = 9600

ratio ≈ 104
```

Meaning:
- one UART bit requires approximately 104 system clock cycles.

---

# 🔌 Ports

| Signal | Direction | Description |
|---|---|---|
| `clk` | Input | System clock |
| `rst` | Input | Active-high reset |
| `newd` | Input | New data valid signal |
| `din_tx[7:0]` | Input | Parallel data input |
| `tx` | Output | UART serial transmit line |
| `done_tx` | Output | Transmission complete flag |

---

# 🧠 Internal Blocks

---

## 1. Baud Clock Generator

Generates a slower UART clock (`uclk`) from the system clock.

```sv
if(count < (ratio/2)-1)
    count <= count + 1;
else begin
    count <= 0;
    uclk <= ~uclk;
end
```

### Why `(ratio/2)-1` ?

- `uclk` toggles every half period
- one full UART bit period requires:
  - LOW → HIGH
  - HIGH → LOW

Hence division by 2.

`-1` is used because counting starts from 0.

---

## 2. Data Register

```sv
reg [7:0] din;
```

Stores input data before serial transmission begins.

---

## 3. Counters

| Counter | Purpose |
|---|---|
| `count` | Baud clock generation |
| `counts` | Tracks transmitted bit number |

---

# 🔄 UART Transmitter FSM

The transmitter is implemented using a **4-state FSM**.

---

## FSM States

```sv
typedef enum bit [1:0] {
    IDLE,
    START,
    TRANSFER,
    DONE
} state_t;
```

---

# 🟢 State : IDLE

UART line remains HIGH during idle condition.

### Operations
- `tx = 1`
- `done_tx = 0`
- waits for `newd`

When new data arrives:
- stores `din_tx` into `din`
- moves to `START`

```text
tx = 1
done_tx = 0

if(newd):
    din = din_tx
    → START
```

---

# 🟡 State : START

Transmits UART start bit.

UART start bit is always:

```text
0
```

### Operations

```text
tx = 0
→ TRANSFER
```

---

# 🔵 State : TRANSFER

Serially transmits 8 data bits.

Transmission is:
- LSB first
- one bit per baud clock

```sv
tx <= din[counts];
```

### Bit Sequence

```text
counts = 0 → tx = din[0]
counts = 1 → tx = din[1]
...
counts = 7 → tx = din[7]
```

After last bit:
- counter resets
- FSM moves to `DONE`

---

# 🟣 State : DONE

Sends UART stop bit.

UART stop bit is always:

```text
1
```

### Operations

```text
tx = 1
done_tx = 1
→ IDLE
```

---

# 📊 UART Transmission Sequence

```text
Idle → Start → D0 → D1 → D2 → D3 → D4 → D5 → D6 → D7 → Stop
```

---

# 📈 UART Frame Format

| Phase | TX Value |
|---|---|
| Idle | 1 |
| Start Bit | 0 |
| Data Bit 0 | LSB |
| Data Bit 1 | |
| ... | |
| Data Bit 7 | MSB |
| Stop Bit | 1 |

---

# 🧩 Example Timing Diagram

```text
TX Line

─────┐     ┌─┬─┬─┬─┬─┬─┬─┬─┬─────
     └─────┘ │ │ │ │ │ │ │ │
     Start   D0 D1 D2 D3 D4 D5 D6 D7 Stop
```

---

# ✅ Key Features

- Parameterized baud rate
- Parameterized clock frequency
- FSM-based UART transmitter
- LSB-first transmission
- Internal baud clock generator
- Transmission complete flag (`done_tx`)
- Clean SystemVerilog enum-based FSM

# UART Receiver (SystemVerilog)

## 📌 Overview

`uartrx.sv` implements a **UART (Universal Asynchronous Receiver/Transmitter) Receiver** in SystemVerilog.

The module converts incoming **serial UART data** into **8-bit parallel data**.

The receiver:
- detects UART start bit
- samples incoming serial bits
- reconstructs the transmitted byte
- generates a data-valid signal after reception completes

---

# ⚙️ Parameters

| Parameter | Description |
|---|---|
| `clk_freq` | Input system clock frequency |
| `baud_rate` | Desired UART baud rate |

---

## Baud Clock Calculation

```text
clkcount = clk_freq / baud_rate
```

Example:

```text
clk_freq  = 1,000,000 Hz
baud_rate = 9600

clkcount ≈ 104
```

Meaning:
- one UART bit lasts approximately 104 system clock cycles.

---

# 🔌 Ports

| Signal | Direction | Description |
|---|---|---|
| `clk` | Input | System clock |
| `rst` | Input | Active-high reset |
| `rx` | Input | UART serial input line |
| `done` | Output | Reception complete flag |
| `rxdata[7:0]` | Output | Received parallel data |

---

# 🧠 Internal Blocks

---

## 1. Baud Clock Generator

Generates slower sampling clock (`uclk`) from system clock.

```sv
if(count < (clkcount/2)-1)
    count <= count + 1;
else begin
    count <= 0;
    uclk <= ~uclk;
end
```

---

## Why `(clkcount/2)-1` ?

- `uclk` toggles every half period
- complete UART bit time requires:
  - LOW → HIGH
  - HIGH → LOW

Hence division by 2.

`-1` compensates because counting starts from 0.

---

## 2. Data Register

```sv
reg [7:0] rxdata;
```

Stores received UART data bits.

---

## 3. Counters

| Counter | Purpose |
|---|---|
| `count` | Baud clock generation |
| `counts` | Tracks number of received bits |

---

# 🔄 UART Receiver FSM

The UART receiver uses a **4-state FSM**.

---

## FSM States

```sv
typedef enum bit [1:0] {
    IDLE,
    START,
    RECEIVE,
    DONE
} state_t;
```

---

# 🟢 State : IDLE

UART line remains HIGH during idle condition.

Receiver continuously monitors:
```text
rx
```

for start bit detection.

UART start bit is:

```text
0
```

### Operations

```text
done = 0
counts = 0

if(rx == 0):
    → START
else:
    remain in IDLE
```

---

# 🟡 State : START

Validates detected start bit.

This prevents false triggering due to glitches/noise.

### Operations

```text
if(rx == 0):
    → RECEIVE
else:
    → IDLE
```

---

# 🔵 State : RECEIVE

Receives 8 serial data bits.

UART transmission is:
- LSB first
- one bit sampled per baud clock

Received bit storage:

```sv
rxdata[counts] <= rx;
```

---

## Bit Storage Sequence

```text
counts = 0 → rxdata[0]
counts = 1 → rxdata[1]
...
counts = 7 → rxdata[7]
```

After final bit:
- counter resets
- FSM moves to `DONE`

---

# 🟣 State : DONE

Reception completed.

### Operations

```text
done = 1
→ IDLE
```

At this stage:
- `rxdata` contains received byte
- receiver waits for next frame

---

# 📊 UART Reception Sequence

```text
Idle → Detect Start → Receive D0 → D1 → D2 → D3 → D4 → D5 → D6 → D7 → Done
```

---

# 📈 UART Frame Format

| Phase | RX Value |
|---|---|
| Idle | 1 |
| Start Bit | 0 |
| Data Bit 0 | LSB |
| Data Bit 1 | |
| ... | |
| Data Bit 7 | MSB |
| Stop Bit | 1 |

---

# 🧩 Example Timing Diagram

```text
RX Line

─────┐     ┌─┬─┬─┬─┬─┬─┬─┬─┬─────
     └─────┘ │ │ │ │ │ │ │ │
     Start   D0 D1 D2 D3 D4 D5 D6 D7 Stop
```

---

# ⚠️ Current Design Limitations

This is a basic UART receiver model.

The current implementation:
- does not perform mid-bit sampling
- does not validate stop bit
- does not include oversampling
- may be sensitive to baud mismatch/noise

Industrial UART designs usually use:
- 8x or 16x oversampling
- mid-bit sampling
- stop-bit checking
- parity checking

---

# ✅ Key Features

- Parameterized baud rate
- Parameterized clock frequency
- FSM-based UART receiver
- Serial-to-parallel conversion
- LSB-first reception
- Internal baud clock generator
- Reception complete flag (`done`)
- Clean SystemVerilog enum-based FSM
