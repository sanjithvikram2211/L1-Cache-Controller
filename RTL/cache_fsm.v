module cache_fsm (
    input wire [3:0] state,
    input wire request_valid,
    input wire hit,
    input wire valid,
    input wire dirty,
    input wire mem_ready,
    output reg [3:0] next_state
);
    localparam IDLE        = 4'd0,
               LOOKUP      = 4'd1,
               WB_REQ      = 4'd2,
               WB_WAIT     = 4'd3,
               WB_GAP      = 4'd4,
               REFILL_REQ  = 4'd5,
               REFILL_WAIT = 4'd6,
               REPLAY      = 4'd7;

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (request_valid)
                    next_state = LOOKUP;
            end
            LOOKUP: begin
                if (hit)
                    next_state = IDLE;
                else if (valid && dirty)
                    next_state = WB_REQ;
                else
                    next_state = REFILL_REQ;
            end
            WB_REQ:      next_state = WB_WAIT;
            WB_WAIT:     if (mem_ready) next_state = WB_GAP;
            WB_GAP:      next_state = REFILL_REQ;
            REFILL_REQ:  next_state = REFILL_WAIT;
            REFILL_WAIT: if (mem_ready) next_state = REPLAY;
            REPLAY:      next_state = LOOKUP;
            default:     next_state = IDLE;
        endcase
    end
endmodule
