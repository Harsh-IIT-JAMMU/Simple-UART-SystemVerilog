# UART Transmitter (SystemVerilog)

## 📌 Overview

This project implements a **UART (Universal Asynchronous Receiver/Transmitter) Transmitter** in SystemVerilog.

The module converts **8-bit parallel data** into a **serial bitstream** following UART protocol:

* 1 Start bit
* 8 Data bits (LSB first)
* 1 Stop bit

It also includes an internal clock divider to generate the required baud rate.

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

| Signal         | Direction | Description                |
| -------------- | --------- | -------------------------- |
| `clk`          | Input     | System clock               |
| `rst`          | Input     | Reset signal               |
| `newd`         | Input     | New data valid signal      |
| `tx_data[7:0]` | Input     | Parallel data to transmit  |
| `tx`           | Output    | Serial output line         |
| `donetx`       | Output    | Transmission complete flag |

---

## 🧠 Internal Blocks

### 1. UART Clock Generator

* Generates a slower clock (`uclk`) from system clock.
* Each toggle represents half bit period.

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
reg [7:0] din;
```

Stores input data when transmission begins.

---

### 3. Counters

* `count` → used for baud clock generation
* `counts` → tracks number of transmitted bits

---

## 🔄 Finite State Machine (FSM)

The transmitter is controlled by a **4-state FSM**:

### States:

```sv
idle     = 2'b00
start    = 2'b01
transfer = 2'b10
done     = 2'b11
```

---

### 🟢 State: IDLE

* TX line is HIGH (default UART idle condition)
* Waits for `newd = 1`
* Loads data into `din`
* Sends **start bit (0)** and moves to transfer state

```text
tx = 1
donetx = 0
if(newd):
    din = tx_data
    tx = 0
    → transfer
```

---

### 🔵 State: TRANSFER

* Sends 8 data bits (LSB first)
* Controlled using `counts`

```text
for counts = 0 to 7:
    tx = din[counts]
```

After all bits:

* Sends stop bit (`tx = 1`)
* Sets `donetx = 1`
* Returns to `IDLE`

---

### ⚠️ Note

Although `start` and `done` states are defined, they are not used explicitly in the FSM. Their functionality is merged into `idle` and `transfer`.

---

## 📊 Transmission Sequence

```text
Idle → Start → Data Bits → Stop → Idle
```

| Phase      | TX Value |
| ---------- | -------- |
| Idle       | 1        |
| Start Bit  | 0        |
| Data Bit 0 | LSB      |
| ...        | ...      |
| Data Bit 7 | MSB      |
| Stop Bit   | 1        |

---

## 🧩 Example Timing

```text
TX Line:
 ─────┐     ┌─┬─┬─┬─┬─┬─┬─┬─┬─────
      └─────┘ │ │ │ │ │ │ │ │
      Start    D0 D1 D2 D3 D4 D5 D6 D7 Stop
```

---

## ✅ Key Features

* Parameterized baud rate and clock frequency
* Simple FSM-based design
* LSB-first transmission
* Built-in clock divider
* Transmission complete flag (`donetx`)
