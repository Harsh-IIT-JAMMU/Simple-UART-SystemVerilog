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

## UART Receiver (SystemVerilog)

## 📌 Overview

UART_Rx.sv implements a **UART (Universal Asynchronous Receiver/Transmitter) Receiver** in SystemVerilog.

The module converts **serial UART data** into **8-bit parallel data**. It detects the start bit, samples incoming bits, and reconstructs the byte.

---

## ⚙️ Parameters

| Parameter   | Description                  |
| ----------- | ---------------------------- |
| `clk_freq`  | Input system clock frequency |
| `baud_rate` | Desired UART baud rate       |

### Baud Clock Calculation

```text
clkcount = clk_freq / baud_rate
```

---

## 🔌 Ports

| Signal        | Direction | Description                  |
| ------------- | --------- | ---------------------------- |
| `clk`         | Input     | System clock                 |
| `rst`         | Input     | Reset signal                 |
| `rx`          | Input     | Serial input line            |
| `done`        | Output    | Data reception complete flag |
| `rxdata[7:0]` | Output    | Received parallel data       |

---

## 🧠 Internal Blocks

### 1. UART Clock Generator

* Generates a slower sampling clock (`uclk`)
* Used to sample incoming serial data

```sv
if(count < clkcount/2)
    count <= count + 1;
else begin
    count <= 0;
    uclk <= ~uclk;
end
```

---

### 2. Data Register

```sv
reg [7:0] rxdata;
```

Stores received data using shift operation.

---

### 3. Counters

* `count` → baud clock generation
* `counts` → number of bits received

---

## 🔄 Finite State Machine (FSM)

The receiver is controlled by a **2-state FSM**:

### States:

```sv
idle  = 2'b00
start = 2'b01
```

---

### 🟢 State: IDLE

* Waits for **start bit detection**
* UART line is normally HIGH
* Start bit is detected when `rx = 0`

```text
done = 0
counts = 0
rxdata = 0

if(rx == 0):
    → start
else:
    stay in idle
```

---

### 🔵 State: START (Data Reception)

* Begins sampling incoming bits
* Receives **8 data bits**
* Uses shift register logic

```text
for counts = 0 to 7:
    rxdata = {rx, rxdata[7:1]}
```

After receiving all bits:

* `done = 1`
* Returns to `IDLE`

---

### ⚠️ Note

* No explicit stop bit validation is performed
* No mid-bit sampling → may cause sampling errors in real hardware
* Start state handles both detection and data reception

---

## 📊 Reception Sequence

```text
Idle → Detect Start → Receive Data Bits → Done → Idle
```

| Phase     | RX Value             |
| --------- | -------------------- |
| Idle      | 1                    |
| Start Bit | 0                    |
| Data Bits | Incoming serial bits |
| Stop Bit  | (Not validated)      |

---

## 🧩 Example Timing

```text
RX Line:
 ─────┐     ┌─┬─┬─┬─┬─┬─┬─┬─┬─────
      └─────┘ │ │ │ │ │ │ │ │
      Start    D0 D1 D2 D3 D4 D5 D6 D7 Stop
```

---

## ✅ Key Features

* Parameterized baud rate and clock frequency
* Simple FSM-based design
* Serial-to-parallel conversion
* Shift register implementation
* Data ready flag (`done`)
