module tb;

  // Create interface instance (connects TB ↔ DUT)
  uart_if vif();
  // Instantiate DUT (Design Under Test)
  // Parameters: CLK_FREQ = 1MHz, BAUD_RATE = 9600
  uart_top #(1000000, 9600) dut (
    vif.clk, 
    vif.rst,
    vif.rx,
    vif.dintx,
    vif.newd,
    vif.tx,
    vif.doutrx,
    vif.donetx, 
    vif.donerx
  );
    
  // Initialize clock to 0
  initial begin
    vif.clk <= 0;
  end
  // Generate clock: toggle every 10 time units
  always #10 vif.clk <= ~vif.clk;
  // Declare environment (contains generator, driver, monitor, scoreboard)
  environment env;

    
  // Main test block
  initial begin
    env = new(vif);       // pass interface to environment
    env.gen.count = 5;    // generate 5 transactions
    env.run();            // start the testbench
  end
  // Dump waveform for debugging (GTKWave etc.)
  initial begin
    $dumpfile("dump.vcd"); // file name
    $dumpvars;             // dump all signals
  end
  // Connect internal DUT clocks to interface (for driver timing)
  assign vif.uclktx = dut.utx.uclk;  // TX clock
  assign vif.uclkrx = dut.rtx.uclk;  // RX clock

endmodule
/*
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
*/
