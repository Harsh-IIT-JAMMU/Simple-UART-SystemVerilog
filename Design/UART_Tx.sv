module uart_tx #(
    parameter clk_freq  = 1000000,
    parameter baud_rate = 9600
)
(
    input clk,
    input rst,
    input newd,
    input [7:0] din_tx,
    output reg tx,
    output reg done_tx
);

    parameter ratio = clk_freq / baud_rate;

    integer count = 0;
    reg uclk = 0;

    reg [7:0] din;
    reg [3:0] counts = 0;

    typedef enum bit [1:0] {
        IDLE,
        START,
        TRANSFER,
        DONE
    } state_t;

    state_t state;

    // Baud clock generation
    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            uclk  <= 0;
        end
        else begin
            if (count < (ratio/2)-1) begin // -1 because counting starts from 0.
                count <= count + 1;
            end
            else begin
                count <= 0;
                uclk  <= ~uclk;
            end
        end
    end

    // UART TX FSM
    always @(posedge uclk) begin
        if (rst) begin
            state   <= IDLE;
            tx      <= 1'b1;
            done_tx <= 1'b0;
            counts  <= 0;
        end
        else begin

            case(state)

                IDLE: begin
                    tx      <= 1'b1;
                    done_tx <= 1'b0;
                    counts  <= 0;

                    if (newd) begin
                        din   <= din_tx;
                        state <= START;
                    end
                    else begin
                        state <= IDLE;
                    end
                end

                START: begin
                    tx    <= 1'b0;   // Start bit
                    state <= TRANSFER;
                end

                TRANSFER: begin
                    tx <= din[counts];

                    if (counts < 7) begin
                        counts <= counts + 1;
                        state  <= TRANSFER;
                    end
                    else begin
                        counts <= 0;
                        state  <= DONE;
                    end
                end

                DONE: begin
                    tx      <= 1'b1; // Stop bit
                    done_tx <= 1'b1;
                    state   <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
