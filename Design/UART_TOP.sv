`timescale 1ns / 1ps

module uart_top
#(
    parameter clk_freq  = 1000000,
    parameter baud_rate = 9600
)
(
    input clk,
    input rst,

    input rx,

    input [7:0] din_tx,
    input newd,

    output tx,
    output [7:0] rxdata,

    output done_tx,
    output done
);

/////////////////////////////////////////////////
// UART TRANSMITTER
/////////////////////////////////////////////////

uart_tx
#(
    .clk_freq(clk_freq),
    .baud_rate(baud_rate)
)
utx
(
    .clk(clk),
    .rst(rst),
    .newd(newd),
    .din_tx(din_tx),
    .tx(tx),
    .done_tx(done_tx)
);

/////////////////////////////////////////////////
// UART RECEIVER
/////////////////////////////////////////////////

uartrx
#(
    .clk_freq(clk_freq),
    .baud_rate(baud_rate)
)
rtx
(
    .clk(clk),
    .rst(rst),
    .rx(rx),
    .done(done),
    .rxdata(rxdata)
);

endmodule
