
# 🚀 UART Verification Environment (SystemVerilog)

## 📌 Overview
This project implements a **SystemVerilog-based verification environment** for a UART design.  
It follows a **modular architecture** consisting of Generator, Driver, Monitor, and Scoreboard components, which communicate using **mailboxes** and **events**.

## 🧱 Testbench Architecture

- **Generator** → Creates randomized transactions  
- **Driver** → Drives stimulus to DUT  
- **Monitor** → Observes DUT outputs  
- **Scoreboard** → Compares expected vs actual data  
- **Environment** → Connects all components  
- **Interface** → Connects Testbench ↔ DUT  

---

## 🔁 Testbench Class Sequence


- interface
- transaction
- generator
- driver
- monitor
- scoreboard
- environment
- testbench

## 🔄 Verification Flow (Sequence)

### 1️⃣ Initialization

* Interface is instantiated
* DUT is connected
* Clock generation starts
* Environment object is created

```systemverilog
env = new(vif);
env.gen.count = 5;
env.run();
```

---

### 2️⃣ Pre-Test (Reset Phase)

* Driver resets DUT

```systemverilog
drv.reset();
```

---

### 3️⃣ Test Execution (Parallel Components)

```systemverilog
fork
  gen.run();
  drv.run();
  mon.run();
  sco.run();
join_any
```

---

### 4️⃣ Generator → Driver

* Generator randomizes transaction
* Sends it via mailbox
* Waits for driver completion

```systemverilog
mbx.put(tr.copy);
@(drvnext);
```

---

### 5️⃣ Driver Operation

**Write Operation:**

* Sends data to DUT via `dintx`
* Asserts `newd`
* Waits for `donetx`

**Read Operation:**

* Drives serial input (`rx`)
* Collects received data
* Waits for `donerx`

```systemverilog
wait(vif.donetx);
wait(vif.donerx);
```

---

### 6️⃣ Driver → Scoreboard

* Driver sends expected data

```systemverilog
mbxds.put(data);
```

---

### 7️⃣ Monitor Observation

* Captures actual DUT behavior
* Sends observed data to scoreboard

```systemverilog
mbx.put(observed_data);
```

---

### 8️⃣ Scoreboard Comparison

```systemverilog
if(ds == ms)
  $display("DATA MATCHED");
else
  $display("DATA MISMATCHED");
```

---

### 9️⃣ Synchronization

* Generator waits for:

  * Driver completion (`drvnext`)
  * Scoreboard completion (`sconext`)

---

### 🔟 End of Test

```systemverilog
wait(gen.done.triggered);
$finish();
```

## 🔗 Communication Mechanisms

* **Generator → Driver** : Mailbox (`mbxgd`)
* **Driver → Scoreboard** : Mailbox (`mbxds`)
* **Monitor → Scoreboard** : Mailbox (`mbxms`)
* **Synchronization** : Events (`drvnext`, `sconext`)

---

## ⚙️ Key Features

* Randomized stimulus using `randc`
* Event-based synchronization
* Mailbox-based communication
* Full-duplex UART verification
* Modular architecture

---

## ▶️ Simulation Commands

```bash
vlog -sv design.sv testbench.sv
vsim tb
run -all
```

---

## 📊 Output Example

```text
[GEN]: Oper : write Din : 45
[DRV]: Data Sent : 45
[MON]: DATA SEND on UART TX 45
[SCO] : DRV : 45 MON : 45
DATA MATCHED
```

---

## 🚀 Future Improvements

* Functional coverage
* Assertions (SVA)
* UVM conversion
* Error injection
* Baud rate variation

---

## 👨‍💻 Author

**Harsh Kumar**
