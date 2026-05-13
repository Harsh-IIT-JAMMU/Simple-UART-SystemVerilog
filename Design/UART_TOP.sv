`timescale 1ns / 1ps
 
module uart_top
#(
parameter clk_freq = 1000000,
parameter baud_rate = 9600
)
(
  input clk,rst, 
  input rx,
  input [7:0] din_tx,
  input newd,
  output tx, 
 output [7:0] rxdata,
  output done_tx,
  output done
    );
    
uarttx 
#(clk_freq, baud_rate) 
utx   
 (clk, rst, newd, din_tx, tx, done_tx);   
 
uartrx 
#(clk_freq, baud_rate)
rtx
 (clk, rst, rx, done, rxdata);    
    
    
endmodule
 
