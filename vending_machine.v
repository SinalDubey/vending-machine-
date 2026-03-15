`timescale 1ns / 1ps

module vending_machine (
    input clk,
    input reset,
    input [1:0] coin_in,  // 00 = No coin, 01 = Nickel (5c), 10 = Dime (10c)
    
    output reg dispense,  // 1 = Drop the item!
    output reg change     // 1 = Return 5 cents in change
);

    // --- State Encoding (Tracking the total money inserted) ---
    localparam S_0  = 3'b000, // 0 cents
               S_5  = 3'b001, // 5 cents
               S_10 = 3'b010, // 10 cents
               S_15 = 3'b011, // 15 cents (Exact price)
               S_20 = 3'b100; // 20 cents (Overpaid)

    reg [2:0] current_state, next_state;

    // --- The Memory (State Transition) ---
    // This moves the machine to the next step on every clock tick
    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= S_0; // Go back to 0 cents if reset is pressed
        else
            current_state <= next_state;
    end

    // --- The Brain (Math and Rules) ---
    always @(*) begin
        // 1. Default settings: Don't give out free stuff, stay in current state
        next_state = current_state;
        dispense = 0;
        change = 0;

        // 2. The Checklist (Counting the money)
        case (current_state)
            
            S_0: begin // Currently have 0 cents
                if (coin_in == 2'b01)      next_state = S_5;   // Put in 5c -> go to 5c state
                else if (coin_in == 2'b10) next_state = S_10;  // Put in 10c -> go to 10c state
            end

            S_5: begin // Currently have 5 cents
                if (coin_in == 2'b01)      next_state = S_10;  // 5c + 5c = 10c state
                else if (coin_in == 2'b10) next_state = S_15;  // 5c + 10c = 15c state
            end

            S_10: begin // Currently have 10 cents
                if (coin_in == 2'b01)      next_state = S_15;  // 10c + 5c = 15c state
                else if (coin_in == 2'b10) next_state = S_20;  // 10c + 10c = 20c state
            end

            S_15: begin // Have exactly 15 cents
                dispense = 1;         // Drop the item!
                change = 0;           // No change needed
                next_state = S_0;     // Go back to the start for the next customer
            end

            S_20: begin // Have 20 cents (Overpaid)
                dispense = 1;         // Drop the item!
                change = 1;           // Give 5 cents back!
                next_state = S_0;     // Go back to the start for the next customer
            end

            default: next_state = S_0;
        endcase
    end

endmodule