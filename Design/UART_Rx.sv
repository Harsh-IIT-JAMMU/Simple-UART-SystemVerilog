module uartrx
#(
    parameter clk_freq  = 1000000,
    parameter baud_rate = 9600
)
(
    input clk,
    input rst,
    input rx,

    output reg done,
    output reg [7:0] rxdata
);

localparam clkcount = (clk_freq/baud_rate);

integer count  = 0;
integer counts = 0;

reg uclk = 0;

typedef enum bit [1:0] {
    IDLE,
    START,
    RECEIVE,
    DONE
} state_t;

state_t state;

/////////////////////////////////////////////////
// UART clock generation
/////////////////////////////////////////////////

always @(posedge clk) begin

    if(rst) begin
        count <= 0;
        uclk  <= 0;
    end
    else begin

        if(count < (clkcount/2)-1)
            count <= count + 1;
        else begin
            count <= 0;
            uclk  <= ~uclk;
        end

    end
end

/////////////////////////////////////////////////
// UART Receiver FSM
/////////////////////////////////////////////////

always @(posedge uclk) begin

    if(rst) begin
        rxdata <= 8'h00;
        counts <= 0;
        done   <= 1'b0;
        state  <= IDLE;
    end

    else begin

        case(state)

        //////////////////////////////////////////////////
        IDLE
        //////////////////////////////////////////////////

        IDLE:
        begin
            counts <= 0;
            done   <= 1'b0;

            // Detect start bit
            if(rx == 1'b0)
                state <= START;
            else
                state <= IDLE;
        end

        //////////////////////////////////////////////////
        START
        //////////////////////////////////////////////////

        START:
        begin
            // confirm valid start bit
            if(rx == 1'b0)
                state <= RECEIVE;
            else
                state <= IDLE;
        end

        //////////////////////////////////////////////////
        RECEIVE DATA
        //////////////////////////////////////////////////

        RECEIVE:
        begin

            rxdata[counts] <= rx;

            if(counts < 7) begin
                counts <= counts + 1;
                state  <= RECEIVE;
            end
            else begin
                counts <= 0;
                state  <= DONE;
            end

        end

        //////////////////////////////////////////////////
        DONE / STOP BIT
        //////////////////////////////////////////////////

        DONE:
        begin
            done  <= 1'b1;
            state <= IDLE;
        end

        default:
            state <= IDLE;

        endcase

    end

end

endmodule
