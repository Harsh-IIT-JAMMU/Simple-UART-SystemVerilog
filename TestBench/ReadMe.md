
UART Verification Environment (SystemVerilog)

Overview
This project implements a SystemVerilog-based verification environment for a UART design.
It follows a modular architecture with Generator, Driver, Monitor, and Scoreboard components communicating via mailboxes and events.

Testbench Architecture
- Generator → Creates randomized transactions
- Driver → Drives stimulus to DUT
- Monitor → Observes DUT outputs
- Scoreboard → Compares expected vs actual data
- Environment → Connects all components
- Interface → Connects Testbench ↔ DUT

Verification Flow (Sequence)

1. Initialization
- Interface is instantiated
- DUT is connected
- Clock generation starts
- Environment object is created

env = new(vif);
env.gen.count = 5;
env.run();

2. Pre-Test (Reset Phase)
- Driver resets DUT

drv.reset();

3. Test Execution (Parallel Components)

fork
  gen.run();
  drv.run();
  mon.run();
  sco.run();
join_any

4. Generator → Driver
- Generator randomizes transaction
- Sends it via mailbox
- Waits for driver completion

mbx.put(tr.copy);
@(drvnext);

5. Driver Operation

Write Operation:
- Sends data to DUT via dintx
- Asserts newd
- Waits for donetx

Read Operation:
- Drives serial input (rx)
- Collects received data
- Waits for donerx

wait(vif.donetx);
wait(vif.donerx);

6. Driver → Scoreboard
- Driver sends expected data

mbxds.put(data);

7. Monitor Observation
- Captures actual DUT behavior
- Sends observed data to scoreboard

mbx.put(observed_data);

8. Scoreboard Comparison

if(ds == ms)
  print("DATA MATCHED")
else
  print("DATA MISMATCHED")

9. Synchronization
- Generator waits for:
  - Driver completion (drvnext)
  - Scoreboard completion (sconext)

10. End of Test

wait(gen.done.triggered);
finish();

Communication Mechanisms

Generator → Driver : Mailbox (mbxgd)
Driver → Scoreboard : Mailbox (mbxds)
Monitor → Scoreboard : Mailbox (mbxms)
Synchronization : Events (drvnext, sconext)

Key Features
- Randomized stimulus using randc
- Event-based synchronization
- Mailbox-based communication
- Full-duplex UART verification
- Modular architecture

Simulation Commands

vlog -sv design.sv testbench.sv
vsim tb
run -all

Output Example

[GEN]: Oper : write Din : 45
[DRV]: Data Sent : 45
[MON]: DATA SEND on UART TX 45
[SCO] : DRV : 45 MON : 45
DATA MATCHED

Future Improvements
- Functional coverage
- Assertions (SVA)
- UVM conversion
- Error injection
- Baud rate variation

Author
Harsh Kumar


