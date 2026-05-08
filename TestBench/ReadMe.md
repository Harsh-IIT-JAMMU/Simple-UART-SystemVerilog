1) TestBench_UART_Top.sv

Testbench = connects DUT + starts environment + generates clock + enables observation
Execution flow:
1. Clock starts
2. env.run()
3. Generator creates transaction
4. Driver drives DUT
5. DUT processes
6. Monitor observes
7. Scoreboard checks
8. Repeat 5 times

2) Transaction.sv

